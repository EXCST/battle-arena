require('lib/ability_kv')

scaling_bear_armor = scaling_bear_armor or class({})

LinkLuaModifier("modifier_scaling_bear_armor", "abilities/modifier_scaling_bear_armor", LUA_MODIFIER_MOTION_NONE)


function scaling_bear_armor:GetIntrinsicModifierName()
	return "modifier_scaling_bear_armor"
end
