LinkLuaModifier("modifier_item_bfury", "items/bfury/modifier_item_bfury", LUA_MODIFIER_MOTION_NONE)

item_bfury = item_bfury or class({})

function item_bfury:GetIntrinsicModifierName()
    return "modifier_item_bfury"
end

function item_bfury:OnSpellStart()
    if not IsServer() then return end
    local caster = self:GetCaster()
    local pos = self:GetCursorPosition()
    GridNav:DestroyTreesAroundPoint(pos, self:GetSpecialValueFor("cleave_ending_width"), false)
    EmitSoundOn("Hero_BattleFury.Cleave", caster)
end
