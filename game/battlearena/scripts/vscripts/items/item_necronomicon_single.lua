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
	local summon_name = keys.necro_unit

	-- Play cast sound
	caster:EmitSound(sound_cast)

	-- Destroy previous summons
	local currentAliveSummons = 1
	local maxSummons = tonumber(keys.max_summons)
	if(not caster["item_imba_necronomicon_single_"..summon_name]) then
		caster["item_imba_necronomicon_single_"..summon_name] = {}
	end
	local summonsTable = caster["item_imba_necronomicon_single_"..summon_name]
	for _, summon in pairs(summonsTable) do
		currentAliveSummons = currentAliveSummons + 1
	end
	while(currentAliveSummons > maxSummons) do
		if(summonsTable[1].summon and not summonsTable[1].summon:IsNull()) then
			UTIL_Remove(summonsTable[1].summon)
		end
		table.remove(summonsTable, 1)
		currentAliveSummons = currentAliveSummons - 1
	end
	-- Spawn the summons
	local summon = CreateSummon(
		caster, 
		summon_name, 
		caster_loc, 
		summon_duration, 
		nil, 
		nil, 
		nil, 
		nil
	)
	table.insert(summonsTable, {summon = summon})
	ability:ApplyDataDrivenModifier(caster, summon, "modifier_item_imba_necronomicon_summon", {})
	-- Particle
	local particle = ParticleManager:CreateParticle(keys.particle, PATTACH_ABSORIGIN, summon)
	ParticleManager:ReleaseParticleIndex(particle)
end
