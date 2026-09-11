soul_guardian_pure_heal = class({})

require('lib/ability_kv')
require('creeps/boss/soul_guardian/soul_guardian_helpers')

local HEAL_PARTICLE = "particles/bosses/soul_guardian/soul_guardian_pure_heal/soul_guardian_pure_heal.vpcf"

--------------------------------------------------------------------------------
function soul_guardian_pure_heal:OnSpellStart()
	local caster = self:GetCaster()

	local base_heal = AbilityKV:Get(self, "base_heal")
	local base_heal_gain = AbilityKV:Get(self, "base_heal_gain")
	local heal_pct_from_max_hp = AbilityKV:Get(self, "heal_pct_from_max_hp")

	-- страховки
	base_heal = base_heal > 0 and base_heal or 2000
	base_heal_gain = base_heal_gain > 0 and base_heal_gain or 100
	heal_pct_from_max_hp = heal_pct_from_max_hp > 0 and heal_pct_from_max_hp or 8

	-- хил растёт с фактором времени (AAF-модель): flat + gain*f + % от макс. HP босса
	local heal = base_heal + base_heal_gain * SoulGuardianHelpers:GetBossFactor()
		+ caster:GetMaxHealth() * heal_pct_from_max_hp / 100

	local healParticle = ParticleManager:CreateParticle(HEAL_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(healParticle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(healParticle)

	caster:Heal(heal, self)
	caster:Purge(false, true, false, true, false)
end

--------------------------------------------------------------------------------
