item_rebels_sword_2 = item_rebels_sword_2 or class({}) 
item_rebels_sword_2_dummy = item_rebels_sword_2

LinkLuaModifier( "modifier_rebels_sword_2_passive", 		'items/rebels_sword_2/modifiers/modifier_rebels_sword_2_passive',   	LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_rebels_sword_2_disarmor", 		'items/rebels_sword_2/modifiers/modifier_rebels_sword_2_disarmor', 		LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_rebels_sword_2_disarmor_cd", 	'items/rebels_sword_2/modifiers/modifier_rebels_sword_2_disarmor_cd', 	LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function item_rebels_sword_2:GetIntrinsicModifierName()
	return "modifier_rebels_sword_2_passive"
end
