satan_bloody_trade = satan_bloody_trade or class({})
LinkLuaModifier("modifier_satan_bloody_trade_buff", "abilities/hero/satan/satan_bloody_trade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_satan_bloody_trade_passive", "abilities/hero/satan/satan_bloody_trade", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	ListenToGameEvent("entity_killed", function(event)
		if not event.entindex_killed or not event.entindex_attacker then return end

		local attacker = EntIndexToHScript(event.entindex_attacker)
		if not attacker or not attacker:IsRealHero() then return end

		local ability = attacker:FindAbilityByName("satan_bloody_trade")
		if not ability then return end

		local chance = ability:GetSpecialValueFor("on_kill_chance")
		if RollPercentage(chance) then
			local killedUnit = EntIndexToHScript(event.entindex_killed)
			ability:Apply(killedUnit:GetMaxHealth() * ability:GetSpecialValueFor("health_cost_pct") / 100)
		end
	end, nil)
end


function satan_bloody_trade:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_bringer_devour.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_infernal_blade_impact.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_bringer_doom_ring_b.vpcf", context)

	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_doombringer.vsndevts", context)
end


function satan_bloody_trade:GetIntrinsicModifierName()
	return "modifier_satan_bloody_trade_passive"
end


function satan_bloody_trade:OnSpellStart()
	local health_cost = self:GetHealthCost(self:GetLevel())

	self:Apply(health_cost)
end


function satan_bloody_trade:GetHealthCost(level)
	return self:GetCaster():GetMaxHealth() * (self:GetLevelSpecialValueFor("health_cost_pct", level) / 100.0)
end


function satan_bloody_trade:Apply(health_lost)
	local caster = self:GetCaster()

	local duration = self:GetSpecialValueFor("duration")
	local damage_pct = self:GetSpecialValueFor("damage_from_health_lost_pct") / 100.0

	local bonus_damage = health_lost * damage_pct

	local existing_modifier = caster:FindModifierByName("modifier_satan_bloody_trade_buff")

	if not existing_modifier then
		existing_modifier = caster:AddNewModifier(caster, self, "modifier_satan_bloody_trade_buff", {
			duration = duration
		})
	end

	if existing_modifier and not existing_modifier:IsNull() then
		existing_modifier:SetStackCount(existing_modifier:GetStackCount() + bonus_damage)

		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_devour.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(particle)

		caster:EmitSound("Hero_DoomBringer.DevourCast")
		caster:EmitSound("doom_bringer_doom_ability_devour_0" .. RandomInt(1, 4))
	end
end


modifier_satan_bloody_trade_buff = modifier_satan_bloody_trade_buff or class({})


function modifier_satan_bloody_trade_buff:IsPurgable() return false end


function modifier_satan_bloody_trade_buff:GetEffectName()
	return "particles/units/heroes/hero_doom_bringer/doom_bringer_doom_ring_b.vpcf"
end


function modifier_satan_bloody_trade_buff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end


function modifier_satan_bloody_trade_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, -- GetModifierPreAttack_BonusDamage
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK, -- GetModifierProcAttack_Feedback
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS, -- GetActivityTranslationModifiers
	}
end


function modifier_satan_bloody_trade_buff:GetModifierPreAttack_BonusDamage()
	return self:GetStackCount()
end


function modifier_satan_bloody_trade_buff:GetModifierProcAttack_Feedback(params)
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_infernal_blade_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.target)
	ParticleManager:SetParticleControl(particle, 0, params.target:GetOrigin())
	ParticleManager:ReleaseParticleIndex(particle)
end


function modifier_satan_bloody_trade_buff:GetActivityTranslationModifiers(params)
	return "infernal_blade"
end


modifier_satan_bloody_trade_passive = modifier_satan_bloody_trade_passive or class({})


function modifier_satan_bloody_trade_passive:IsHidden() return true end
function modifier_satan_bloody_trade_passive:IsPurgable() return false end


if not IsServer() then return end


function modifier_satan_bloody_trade_passive:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
end


function modifier_satan_bloody_trade_passive:OnRefresh()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
end
