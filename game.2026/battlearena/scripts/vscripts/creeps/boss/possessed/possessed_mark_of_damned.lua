possessed_mark_of_damned = possessed_mark_of_damned or class({})

local ability = possessed_mark_of_damned

require('lib/ability_kv')
require('creeps/boss/possessed/possessed_helpers')

LinkLuaModifier("modifier_possessed_mark", "creeps/boss/possessed/modifiers/modifier_possessed_mark", LUA_MODIFIER_MOTION_NONE)


function ability:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local cast_range = self:GetCastRange(caster:GetAbsOrigin(), caster)
	local target = PossessedHelpers:GetRandomEnemy(caster:GetTeamNumber(), caster:GetAbsOrigin(), cast_range)

	if not IsValidEntity(target) then return end

	local duration = AbilityKV:Get(self, "mark_duration")

	if not duration or duration <= 0 then
		duration = 3.0
	end

	target:AddNewModifier(caster, self, "modifier_possessed_mark", {
		duration = duration,
	})

	caster:EmitSound("Boss_Possessed.Curse.Cast")
end
