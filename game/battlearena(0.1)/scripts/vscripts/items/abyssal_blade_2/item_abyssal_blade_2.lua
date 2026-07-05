item_abyssal_blade_2 = item_abyssal_blade_2 or class({})
LinkLuaModifier("modifier_item_abyssal_blade_2", "items/abyssal_blade_2/modifier_item_abyssal_blade_2", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_abyssal_blade_2_bash", "items/abyssal_blade_2/modifier_item_abyssal_blade_2_bash", LUA_MODIFIER_MOTION_NONE)

function item_abyssal_blade_2:GetIntrinsicModifierName()
    return "modifier_item_abyssal_blade_2"
end

function item_abyssal_blade_2:CastFilterResultTarget(hTarget)
    if self:GetCaster():GetTeamNumber() == hTarget:GetTeamNumber() then
        return UF_FAIL_ENEMY
    end
    return UF_SUCCESS
end

function item_abyssal_blade_2:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    if not target then return end

    if target:TriggerSpellAbsorb(self) then return end

    local stun_duration = self:GetSpecialValueFor("stun_duration")
    target:AddNewModifier(caster, self, "modifier_stunned", { duration = stun_duration })
end
