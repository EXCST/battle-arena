satan_curse = satan_curse or class({})
LinkLuaModifier("modifier_satan_curse_debuff", "abilities/hero/satan/satan_curse", LUA_MODIFIER_MOTION_NONE)


function satan_curse:IsHiddenWhenStolen() return false end


function satan_curse:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_shadow_demon/shadow_demon_demonic_purge_debuff.vpcf", context)
	PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_doom_bringer.vsndevts", context)
end


function satan_curse:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:TriggerSpellAbsorb(self) then return end
	if target:TriggerSpellReflect(self) then return end

	local duration = self:GetSpecialValueFor("duration")
	target:AddNewModifier(caster, self, "modifier_satan_curse_debuff", {duration = duration})

	caster:EmitSound("doom_bringer_doom_ability_doom_0" .. RandomInt(1, 7))
end



modifier_satan_curse_debuff = modifier_satan_curse_debuff or class({})


function modifier_satan_curse_debuff:IsPurgable() return false end
function modifier_satan_curse_debuff:IsDebuff() return true end


function modifier_satan_curse_debuff:GetEffectName()
	return "particles/units/heroes/hero_shadow_demon/shadow_demon_demonic_purge_debuff.vpcf"
end


function modifier_satan_curse_debuff:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
		[MODIFIER_STATE_MUTED] = true,
		[MODIFIER_STATE_BLIND] = true,
	}
end


function modifier_satan_curse_debuff:OnCreated()
	self.slow = self:GetAbility():GetSpecialValueFor("slow")
end


function modifier_satan_curse_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end


function modifier_satan_curse_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end
