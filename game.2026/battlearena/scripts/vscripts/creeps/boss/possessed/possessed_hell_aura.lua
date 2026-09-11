possessed_hell_aura = possessed_hell_aura or class({})

local ability = possessed_hell_aura

require('lib/ability_kv')

LinkLuaModifier("modifier_possessed_hell_aura", "creeps/boss/possessed/modifiers/modifier_possessed_hell_aura", LUA_MODIFIER_MOTION_NONE)


function ability:GetIntrinsicModifierName()
	return "modifier_possessed_hell_aura"
end
