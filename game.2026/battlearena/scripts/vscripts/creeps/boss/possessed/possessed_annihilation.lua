possessed_annihilation = possessed_annihilation or class({})

local ability = possessed_annihilation

require('lib/ability_kv')

LinkLuaModifier("modifier_possessed_annihilation", "creeps/boss/possessed/modifiers/modifier_possessed_annihilation", LUA_MODIFIER_MOTION_NONE)


function ability:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_possessed_annihilation", { duration = -1 })

	caster:EmitSound("Boss_Possessed.Hellshield.Cast")
end
