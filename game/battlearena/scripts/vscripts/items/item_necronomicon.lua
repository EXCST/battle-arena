-- Copyright (C) 2018  The Dota IMBA Development Team
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Editors:
--

--[[	Author: Firetoad
		Date: 06.01.2016	]]

function Necronomicon( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local sound_cast = keys.sound_cast
	local necro_level = keys.necro_level

	-- If this unit is not a real hero, do nothing
	if not caster:IsRealHero() then
		ability:RefundManaCost()
		ability:EndCooldown()
		return nil
	end

	-- Parameters
	local summon_duration = ability:GetLevelSpecialValueFor("summon_duration", ability_level)
	local caster_loc = caster:GetAbsOrigin()
	local caster_direction = caster:GetForwardVector()
	local melee_summon_name = "npc_imba_necronomicon_warrior_"..necro_level
	local ranged_summon_name = "npc_imba_necronomicon_archer_"..necro_level

	-- Play cast sound
	caster:EmitSound(sound_cast)

	-- Calculate summon positions
	local melee_loc = RotatePosition(caster_loc, QAngle(0, 30, 0), caster_loc + caster_direction * 180)
	local ranged_loc = RotatePosition(caster_loc, QAngle(0, -30, 0), caster_loc + caster_direction * 180)

	-- Destroy trees
	GridNav:DestroyTreesAroundPoint(caster_loc + caster_direction * 180, 180, false, caster)

	-- Destroy previous summons
	local currentAliveSummons = 1
	local maxSummons = tonumber(keys.max_summons)
	if(not caster["item_imba_necronomicon_"..necro_level]) then
		caster["item_imba_necronomicon_"..necro_level] = {}
	end
	local summonsTable = caster["item_imba_necronomicon_"..necro_level]
	for _, summon in pairs(summonsTable) do
		currentAliveSummons = currentAliveSummons + 1
	end
	while(currentAliveSummons > maxSummons) do
		if(summonsTable[1].melee and not summonsTable[1].melee:IsNull()) then
			UTIL_Remove(summonsTable[1].melee)
		end
		if(summonsTable[1].ranged and not summonsTable[1].ranged:IsNull()) then
			UTIL_Remove(summonsTable[1].ranged)
		end
		table.remove(summonsTable, 1)
		currentAliveSummons = currentAliveSummons - 1
	end
	-- Spawn the summons
	local melee_summon = CreateSummon(
		caster, 
		melee_summon_name, 
		melee_loc, 
		summon_duration, 
		nil, 
		nil, 
		nil, 
		nil
	)
	local ranged_summon = CreateSummon(
		caster, 
		ranged_summon_name, 
		ranged_loc, 
		summon_duration, 
		nil, 
		nil, 
		nil, 
		nil
	)
	table.insert(summonsTable, {melee = melee_summon, ranged = ranged_summon})
	-- Make the summons limited duration and controllable
	ability:ApplyDataDrivenModifier(caster, melee_summon, "modifier_item_imba_necronomicon_summon", {})
	ability:ApplyDataDrivenModifier(caster, ranged_summon, "modifier_item_imba_necronomicon_summon", {})
	-- Particles
	local meleeParticle = ParticleManager:CreateParticle("particles/items_fx/necronomicon_spawn_warrior.vpcf", PATTACH_ABSORIGIN, melee_summon)
	ParticleManager:ReleaseParticleIndex(meleeParticle)
	local rangedParticle = ParticleManager:CreateParticle("particles/items_fx/necronomicon_spawn.vpcf", PATTACH_ABSORIGIN, ranged_summon)
	ParticleManager:ReleaseParticleIndex(meleeParticle)
	-- Find summon abilities
	local melee_abilities = {
		"necronomicon_warrior_mana_burn",
		"necronomicon_warrior_last_will",
		"necronomicon_warrior_sight",
		"black_dragon_dragonhide_aura",
		"granite_golem_hp_aura",
		"spawnlord_aura"
	}
	local ranged_abilities = {
		"necronomicon_archer_mana_burn",
		"necronomicon_archer_aoe",
		"forest_troll_high_priest_mana_aura",
		"big_thunder_lizard_wardrums_aura",
		"imba_necronomicon_archer_multishot"
	}

	-- Upgrade melee minion abilities
	for _, melee_ability in pairs(melee_abilities) do
		if melee_summon:FindAbilityByName(melee_ability) then
			if melee_summon:FindAbilityByName(melee_ability):GetMaxLevel() > 1 then
				melee_summon:FindAbilityByName(melee_ability):SetLevel(necro_level)
			else
				melee_summon:FindAbilityByName(melee_ability):SetLevel(1)
			end
		end
	end

	-- Upgrade ranged minion abilities
	for _, ranged_ability in pairs(ranged_abilities) do
		if ranged_summon:FindAbilityByName(ranged_ability) then
			if ranged_summon:FindAbilityByName(ranged_ability):GetMaxLevel() > 1 then
				ranged_summon:FindAbilityByName(ranged_ability):SetLevel(necro_level)
			else
				ranged_summon:FindAbilityByName(ranged_ability):SetLevel(1)
			end
		end
	end
end
