OnEntityKilledListener = OnEntityKilledListener or class({})

RESPAWN_MODIFER = 0.065
GOLD_FOR_COUR = 350
_G.Kills = {}

function RemoveAegisModifier(killedUnit)
	while (killedUnit:HasModifier("modifier_item_aegis")) do
		killedUnit:RemoveModifierByName("modifier_item_aegis")
	end
end

function OnEntityKilledListener:OnHeroDeath(dead_hero, killer)
	if not dead_hero or dead_hero:IsNull() or not IsValidEntity(dead_hero) then return end
	if not killer or killer:IsNull() or not IsValidEntity(killer) then return end
	
	local item
	for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
		item = dead_hero:GetItemInSlot(i)
		if item and item:GetPurchaser() == dead_hero then
			if item and (item:GetName() == "item_power_amulet" or item:GetName() == "item_mystic_amulet" or item:GetName() == "item_strange_amulet" ) then
				item:SetCurrentCharges(math.floor(item:GetCurrentCharges() / 2 + 0.5))
				return
			end
		end
	end
	item = nil

	ComebackSystem:OnKill( killer:GetPlayerOwnerID(), killer:GetTeamNumber(), dead_hero:GetPlayerOwnerID(), dead_hero:GetTeamNumber() )
end

function OnEntityKilledListener:OnEntityKilled(event)
	local killedUnit = EntIndexToHScript(event.entindex_killed)

	if not killedUnit or not IsValidEntity(killedUnit) then
		return
	end

	-- AUGMENTS: champions count as real heroes (ConsideredHero "1"), handle them first
	if killedUnit.champion_kind then
		-- always remove the minimap dummy on death (any killer)
		if IsValidEntity(killedUnit.minimap_entity) then
			killedUnit.minimap_entity:RemoveSelf()
			killedUnit.minimap_entity = nil
		end

		local hero = EntIndexToHScript(event.entindex_attacker)
		if hero and IsValidEntity(hero) and hero:IsRealHero() then
			local killedTeam = killedUnit:GetTeam()
			local heroTeam = hero:GetTeam()
			if heroTeam and killedTeam and heroTeam ~= killedTeam and Augments then
				Augments:QueueForTeam(heroTeam, killedUnit.champion_kind)
				GameRules:SendCustomMessage("#champion_killed_" .. killedUnit.champion_kind, 0, 0)
			end
		end
		return
	end

	local hero = EntIndexToHScript(event.entindex_attacker)

	if not hero or not IsValidEntity(hero) then
		return
	end

	local killedTeam = killedUnit:GetTeam()
	local heroTeam = hero:GetTeam()

	-- SOLO DUEL BOSS: direct epic augment for the killer team, no orb progress
	-- (the duel reward itself is handled by DuelController:EndDuel).
	if killedUnit.duel_boss then
		if SoloDuel and SoloDuel.OnBossKilled then
			SoloDuel:OnBossKilled(killedUnit, hero)
		end
		if hero and not hero:IsNull() and IsValidEntity(hero) and hero:IsRealHero() and heroTeam and Augments and Augments.QueueForTeam then
			Augments:QueueForTeam(heroTeam, AUGMENT_TIER.EPIC)
			GameRules:SendCustomMessage("#solo_boss_killed", 0, 0)
		end
		return
	end

	_G.Kills[heroTeam] = _G.Kills[heroTeam] or 0
	_G.Kills[DOTA_TEAM_BADGUYS] = _G.Kills[DOTA_TEAM_BADGUYS] or 0
	_G.Kills[DOTA_TEAM_GOODGUYS] = _G.Kills[DOTA_TEAM_GOODGUYS] or 0

	local GameMode = GameRules:GetGameModeEntity()

	if not killedUnit or not IsValidEntity(killedUnit) then
		print("Not Valid Entity")
		return
	end
	
	if killedUnit:IsAlive() or not killedUnit:IsRealHero() then
		print("Entity is Alive or is NOT real hero")
	end
	
	if IsValidEntity(killedUnit) and not killedUnit:IsAlive() and killedUnit:IsRealHero() then
		local timeLeft = killedUnit:GetLevel() * 3.8 + 5
		timeLeft = timeLeft * RESPAWN_MODIFER
		if timeLeft < 5.0 then
			timeLeft = 5.0
		end

		if killedUnit:IsReincarnating() == false then
			killedUnit:SetTimeUntilRespawn(timeLeft)
		end
	end

	if killedUnit:IsRealHero() and not killedUnit:IsReincarnating() and heroTeam and heroTeam ~= killedTeam and _G.Kills[heroTeam] then
		_G.Kills[heroTeam] = _G.Kills[heroTeam] + 1
	end
	
	if killedUnit:HasAbility("skeleton_king_reincarnation") or killedUnit:HasAbility("angel_arena_reincarnation") then
		local rein_ability = killedUnit:FindAbilityByName("skeleton_king_reincarnation") or killedUnit:FindAbilityByName("angel_arena_reincarnation")
		if (rein_ability:GetCooldownTimeRemaining() ~= rein_ability:GetEffectiveCooldown(rein_ability:GetLevel() - 1)) then
			RemoveAegisModifier(killedUnit)
		end
	else
		RemoveAegisModifier(killedUnit)
	end

	if killedUnit:IsRealHero() and not killedUnit:IsReincarnating() then
		OnEntityKilledListener:OnHeroDeath(killedUnit, hero)

		-- AUGMENTS: hero kill credits a rare orb to the killer team
		if heroTeam and killedTeam and heroTeam ~= killedTeam and Augments and Augments.AddOrbProgress then
			Augments:AddOrbProgress(heroTeam, AUGMENT_TIER.RARE, 1)
		end
	end

	if not killedUnit:IsRealHero() and not killedUnit:IsCourier() then
		if CreepSpawner and CreepSpawner._OnDied then
			CreepSpawner:_OnDied(killedUnit)
		end
		if BossSpawner and BossSpawner.IsBoss and BossSpawner:IsBoss(killedUnit) then
			BossSpawner:_OnDeath(killedUnit)
		end
		if ScalingCamp and ScalingCamp:IsScalingBear(killedUnit) then
			local xp = killedUnit.scaling_xp or 0
			if xp > 0 and hero and hero:IsRealHero() then
				hero:AddExperience(xp, 0, false, true)
			end
		end
		if NeutralProgress then
			NeutralProgress:OnCreepKill(killedUnit, hero)
		end

		-- AUGMENTS: farm units credit orb progress
		if hero and hero:IsRealHero() and heroTeam and killedTeam and heroTeam ~= killedTeam and Augments then
			if killedUnit:IsCreep() and not killedUnit:IsIllusion() and killedUnit:GetPlayerOwnerID() < 0 then
				local is_scaling_boss = ScalingCamp and ScalingCamp.IsScalingBear
					and ScalingCamp:IsScalingBear(killedUnit)
					and killedUnit:GetUnitName() == "npc_aa_scaling_boss"

				if is_scaling_boss then
					-- scaling boss grants a FULL augment directly, no orb progress:
					-- rare on cycles 50-150, epic on 200+
					local boss_cycle = killedUnit.bear_spawn_cycle or 0
					local boss_orb = AUGMENT_TIER.RARE
					if boss_cycle >= 200 then
						boss_orb = AUGMENT_TIER.EPIC
					end
					Augments:QueueForTeam(heroTeam, boss_orb)
				else
					local orb_type = AUGMENT_TIER.COMMON
					if BossSpawner and BossSpawner.IsBoss and BossSpawner:IsBoss(killedUnit) then
						orb_type = AUGMENT_TIER.EPIC
					end
					Augments:AddOrbProgress(heroTeam, orb_type, killedUnit.orb_value or 1)
				end
			end
		end
	end

	GameMode:SetCustomDireScore( _G.Kills[DOTA_TEAM_BADGUYS] )
	GameMode:SetCustomRadiantScore( _G.Kills[DOTA_TEAM_GOODGUYS] )

	if hero and hero:GetPlayerOwnerID() ~= nil and killedUnit:IsCourier() then
	    print("On courier killed")
		PlayerResource:ModifyGold(hero:GetPlayerOwnerID(), GOLD_FOR_COUR, false, 0)
	end
	print("dodik",PlayerResource:GetTeamKills(DOTA_TEAM_GOODGUYS))

	if PlayerResource:GetTeamKills(DOTA_TEAM_GOODGUYS) >=100 then
    	GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
   	end


	if PlayerResource:GetTeamKills(DOTA_TEAM_BADGUYS) >=100 then
		GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
	end
end

