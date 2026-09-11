hola_grace = hola_grace or class({})
LinkLuaModifier("modifier_hola_grace", "heroes/hola/hola_grace", LUA_MODIFIER_MOTION_NONE)


function hola_grace:IsHiddenWhenStolen() return false end


function hola_grace:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", context)

	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_omniknight.vsndevts", context)
end


function hola_grace:OnSpellStart()
	local target = self:GetCursorTarget()

	self:Apply(target)

	EmitSoundOnClient("keeper_of_the_light_keep_chakramagic_0" .. RandomInt(1, 6), self:GetCaster():GetPlayerOwner())
end


function hola_grace:Apply(target)
	local caster = self:GetCaster()

	local heal_duration = self:GetSpecialValueFor("heal_duration")

	target:AddNewModifier(caster, self, "modifier_hola_grace", {
		duration = heal_duration,
	})
end



modifier_hola_grace = modifier_hola_grace or class({})


function modifier_hola_grace:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_hola_grace:IsHidden() return false end
function modifier_hola_grace:IsPurgable() return false end


function modifier_hola_grace:OnCreated()
	local ability = self:GetAbility()
	local parent = self:GetParent()

	local heal = ability:GetSpecialValueFor("heal")
	self.hp_regen = ability:GetSpecialValueFor("hp_regen")

	self.heal_amp = ability:GetSpecialValueFor("heal_amp")

	if not IsServer() then return end

	local caster = self:GetCaster()

	parent:Heal(heal, ability)
	parent:EmitSound("Hero_Omniknight.Purification")
	SendOverheadEventMessage(caster, OVERHEAD_ALERT_HEAL, parent, heal, nil)

	local part = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(part, 0, parent:GetOrigin())
	ParticleManager:SetParticleControl(part, 1, Vector(300, 1, 1))
	ParticleManager:ReleaseParticleIndex(part)
end


function modifier_hola_grace:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,

		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
	}
end


function modifier_hola_grace:GetModifierConstantHealthRegen()
	return self.hp_regen
end


function modifier_hola_grace:GetModifierHealAmplify_PercentageSource() 			return self.heal_amp or 0 end
function modifier_hola_grace:GetModifierHealAmplify_PercentageTarget() 			return self.heal_amp or 0 end
function modifier_hola_grace:GetModifierHPRegenAmplify_Percentage() 	 			return self.heal_amp or 0 end
function modifier_hola_grace:GetModifierLifestealRegenAmplify_Percentage() 		return self.heal_amp or 0 end
function modifier_hola_grace:GetModifierSpellLifestealRegenAmplify_Percentage() 	return self.heal_amp or 0 end