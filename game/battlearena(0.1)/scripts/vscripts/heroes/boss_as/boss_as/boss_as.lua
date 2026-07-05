boss_as = class({})

LinkLuaModifier("modifier_boss_as", 'heroes/boss_as/boss_as/modifier_boss_as', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_as_effect", 'heroes/boss_as/boss_as/modifier_boss_as_effect', LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------
function boss_as:GetIntrinsicModifierName()
    return "modifier_boss_as"
end
--------------------------------------------------------------------------------