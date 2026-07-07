item_death_shield = item_death_shield or class({})
LinkLuaModifier("modifier_item_death_shield", "items/death_shield/modifier_item_death_shield", LUA_MODIFIER_MOTION_NONE)

function item_death_shield:GetIntrinsicModifierName()
    return "modifier_item_death_shield"
end
