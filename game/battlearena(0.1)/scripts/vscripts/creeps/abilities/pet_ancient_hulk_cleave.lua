LinkLuaModifier("modifier_cleave_custom", "path/to/modifier_cleave_custom", LUA_MODIFIER_MOTION_NONE)

pet_ancient_hulk_cleave = class({})

function pet_ancient_hulk_cleave:GetIntrinsicModifierName()
	return "modifier_cleave_custom"
end
