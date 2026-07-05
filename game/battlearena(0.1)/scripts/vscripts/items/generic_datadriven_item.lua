generic_datadriven_item = generic_datadriven_item or class({})

function generic_datadriven_item:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end

LinkLuaModifier("modifier_generic_datadriven_item", "items/generic_datadriven_modifier", LUA_MODIFIER_MOTION_NONE)
