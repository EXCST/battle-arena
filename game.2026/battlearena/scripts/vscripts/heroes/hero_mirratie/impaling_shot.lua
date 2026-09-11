-- ============================================================
-- MIRRATIE — Impaling Shot (mirratie_impaling_shot, ability_lua)
-- Портировано из BS heroes/hero_mirratie/impaling_shot.lua.
-- Правки:
--   * GetSpecialValueFor → AbilityKV:Get (регрессия движка: 0)
--   * GetCastRange: клиентская ветка с хардкодом (на клиенте
--     нет GetAbilityKeyValues → AbilityKV:Get вернёт 0)
--   * ScriptFile в KV — без ".lua" (конвенция героев проекта)
-- ============================================================

require('lib/ability_kv')

mirratie_impaling_shot = class({})

function mirratie_impaling_shot:GetAbilityDamageType()
	if self:GetCaster():HasScepter() then
		return DAMAGE_TYPE_PURE
	end
	return self.BaseClass.GetAbilityDamageType(self)
end

function mirratie_impaling_shot:CastFilterResultTarget( hTarget )
	if IsServer() then
		if hTarget and hTarget:IsMagicImmune() and not self:GetCaster():HasScepter() then
			return UF_FAIL_MAGIC_IMMUNE_ENEMY
		end
		return UnitFilter(hTarget, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), self:GetCaster():GetTeamNumber())
	end
	return UF_SUCCESS
end

function mirratie_impaling_shot:GetCastRange(vLocation, hTarget)
	if self:GetCaster():HasScepter() then
		if IsServer() then
			return AbilityKV:Get(self, "cast_range_scepter")
		end
		-- ⚠️ Клиентский хардкод: AbilityKV на клиенте недоступен (паттерн saber)
		return 3000
	end
	return self.BaseClass.GetCastRange(self, vLocation, hTarget)
end

if IsServer() then
	function mirratie_impaling_shot:OnSpellStart()
		self.ChannelTarget = self:GetCursorTarget()
		self:GetCaster():EmitSound("Ability.AssassinateLoad")
	end

	function mirratie_impaling_shot:OnChannelFinish(bInterrupted)
		if not bInterrupted then
			self:GetCaster():EmitSound("Hero_Sniper.AssassinateProjectile")
			local hTarget = self.ChannelTarget
			if hTarget then
				ProjectileManager:CreateTrackingProjectile({
					EffectName = "particles/arena/units/heroes/hero_mirratie/impaling_shot.vpcf",
					Ability = self,
					iMoveSpeed = AbilityKV:Get(self, "projectile_speed"),
					Source = self:GetCaster(),
					Target = hTarget,
					--iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
				})
			end
		end
		self.ChannelTarget = nil
	end

	function mirratie_impaling_shot:OnProjectileHit(hTarget, vLocation)
		if hTarget and not hTarget:IsInvulnerable() and (not hTarget:IsMagicImmune() or self:GetCaster():HasScepter()) and not hTarget:TriggerSpellAbsorb(self) then
			hTarget:EmitSound("Hero_Sniper.AssassinateDamage")
			local stun_duration = AbilityKV:Get(self, "stun_duration")
			if not stun_duration or stun_duration <= 0 then stun_duration = 2.0 end
			local damage = self:GetAbilityDamage()

			if self:GetCaster():HasScepter() then
				stun_duration = AbilityKV:Get(self, "stun_duration_scepter")
				if not stun_duration or stun_duration <= 0 then stun_duration = 4.0 end
				damage = AbilityKV:Get(self, "damage_scepter")
				if not damage or damage <= 0 then damage = 1000 end
			end
			local damage_table = {
				victim = hTarget,
				attacker = self:GetCaster(),
				damage = damage,
				damage_type = self:GetAbilityDamageType(),
				ability = self
			}
			ApplyDamage(damage_table)
			hTarget:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = stun_duration})

			local impale_effect_pct = AbilityKV:Get(self, "impale_effect_pct")
			if not impale_effect_pct or impale_effect_pct <= 0 then impale_effect_pct = 100 end
			damage_table.damage = damage * impale_effect_pct * 0.01
			local loc1 = hTarget:GetAbsOrigin()
			local loc2 = loc1 + (loc1 - self:GetCaster():GetAbsOrigin()):Normalized() * AbilityKV:Get(self, "impale_range")

			local pfx = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_mirratie/impaling_shot_impale.vpcf", PATTACH_ABSORIGIN, hTarget)
			ParticleManager:SetParticleControl(pfx, 0, loc2)
			ParticleManager:SetParticleControl(pfx, 1, loc1)
			self:CreateVisibilityNode(loc1, 10, 1)
			for _, v in ipairs(FindUnitsInLine(self:GetCaster():GetTeamNumber(), loc1, loc2, nil, AbilityKV:Get(self, "impale_width"), self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags())) do
				if v ~= hTarget and (not v:IsMagicImmune() or self:GetCaster():HasScepter()) then
					damage_table.victim = v
					ApplyDamage(damage_table)
					v:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = stun_duration * impale_effect_pct * 0.01})
				end
			end
		end

		return true
	end
end
