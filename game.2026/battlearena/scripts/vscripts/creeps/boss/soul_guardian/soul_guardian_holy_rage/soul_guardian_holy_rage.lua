soul_guardian_holy_rage = class({})
local modifierRageBoost = "modifier_soul_guardian_holy_rage"
LinkLuaModifier(modifierRageBoost, "creeps/boss/soul_guardian/soul_guardian_holy_rage/"..modifierRageBoost, LUA_MODIFIER_MOTION_NONE)

require('lib/ability_kv')
require('creeps/boss/soul_guardian/soul_guardian_helpers')

--------------------------------------------------------------------------------
function soul_guardian_holy_rage:OnSpellStart()
	local caster = self:GetCaster()

	local damage_for_purge_base = AbilityKV:Get(self, "damage_for_purge_base")
	local damage_for_purge_gain = AbilityKV:Get(self, "damage_for_purge_gain")
	local damage_for_purge_pct_from_max_hp = AbilityKV:Get(self, "damage_for_purge_pct_from_max_hp")
	local max_duration = AbilityKV:Get(self, "max_duration")

	-- страховки
	damage_for_purge_base = damage_for_purge_base > 0 and damage_for_purge_base or 1200
	damage_for_purge_gain = damage_for_purge_gain > 0 and damage_for_purge_gain or 200
	damage_for_purge_pct_from_max_hp = damage_for_purge_pct_from_max_hp > 0 and damage_for_purge_pct_from_max_hp or 6
	max_duration = max_duration > 0 and max_duration or 30

	local buff = caster:AddNewModifier(caster, self, modifierRageBoost, { duration = max_duration })
	if not buff then return end

	-- пул урона для снятия: % от макс. HP + flat + gain*f (растёт со временем игры)
	buff:SetStackCount(caster:GetMaxHealth() * damage_for_purge_pct_from_max_hp / 100
		+ damage_for_purge_base + damage_for_purge_gain * SoulGuardianHelpers:GetBossFactor())

	-- Zeal-фича из AAF: сброс всех КД способностей
	for i = 0, caster:GetAbilityCount() - 1 do
		local ability = caster:GetAbilityByIndex(i)
		if ability and not ability:IsNull() and ability:GetCooldownTimeRemaining() > 0 then
			ability:EndCooldown()
		end
	end
end

--------------------------------------------------------------------------------
