item_sacred_butterfly = item_sacred_butterfly or class({})

LinkLuaModifier("modifier_sacred_butterfly", "items/sacred_butterfly/modifiers/modifier_sacred_butterfly", LUA_MODIFIER_MOTION_NONE)

function item_sacred_butterfly:GetIntrinsicModifierName()
	return "modifier_sacred_butterfly"
end
