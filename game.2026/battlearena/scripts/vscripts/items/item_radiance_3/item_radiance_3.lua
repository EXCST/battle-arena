item_radiance_3 = item_radiance_3 or class({})

LinkLuaModifier("modifier_item_radiance_3", "items/item_radiance_3/modifier_item_radiance_3", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_radiance_effect_lua", "items/item_radiance_3/modifier_item_radiance_effect_lua", LUA_MODIFIER_MOTION_NONE)

function item_radiance_3:Precache(context)
	PrecacheResource("particle", "particles/econ/events/ti9/radiance_owner_ti9.vpcf", context)
	PrecacheResource("particle", "particles/econ/events/ti9/radiance_ti9.vpcf", context)
end

function item_radiance_3:GetIntrinsicModifierName()
    return "modifier_item_radiance_3"
end
