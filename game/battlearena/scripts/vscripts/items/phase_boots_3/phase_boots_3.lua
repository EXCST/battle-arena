item_phase_boots_3 = item_phase_boots_3 or class({})

LinkLuaModifier("modifier_phase_boots_3_passive", "items/phase_boots_3/modifiers/modifier_phase_boots_3_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phase_boots_3_active", "items/phase_boots_3/modifiers/modifier_phase_boots_3_passive", LUA_MODIFIER_MOTION_NONE)

function item_phase_boots_3:GetIntrinsicModifierName()
	return "modifier_phase_boots_3_passive"
end

function item_phase_boots_3:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	if not caster then return end

	local duration = self:GetSpecialValueFor("phase_duration")

	caster:AddNewModifier(caster, self, "modifier_phase_boots_3_active", { duration = duration })

	EmitSoundOn("DOTA_Item.PhaseBoots.Activate", caster)
end
