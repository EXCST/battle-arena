-- lib/solo/solo_duel.lua
-- Solo duel: instead of a team-vs-team duel, the radiant team (all players)
-- fights a duel boss on the duel arena. Reuses DuelLibrary primitives
-- (teleport, move limiter, respawn-to-tribune, EndDuel cleanup/rewards flow).

require('lib/teleport')
require('lib/duel/duel_lib')
require('lib/duel_bosses/boss_hud')
require('lib/duel_bosses/boss_summon')

SoloDuel = SoloDuel or class({})

SoloDuel.SOLO_TEAM = DOTA_TEAM_GOODGUYS

local DUEL_POINTS = { "RADIANT_DUEL_TELEPORT" }

-- Boss roster by duel number (sequential): boss 1 -> duel 1, boss 2 -> duel 2, ...
-- After the last entry the cycle repeats but stats keep scaling.
local BOSS_ROSTER = {
	"npc_ba_duel_boss_03",      -- TEST: Deadeye сразу (полный ростер ниже, вернуть после теста)
	-- "npc_ba_duel_boss_01",   -- Зверь
	-- "npc_ba_duel_boss_02",   -- Воин Пустоши (сильнее Зверя)
}

local SCALE_PER_DUEL = 1.3

function SoloDuel:Init()
	self.active_duel = false
	self.boss_alive = false
	self.duel_boss = nil
end

function SoloDuel:IsActive()
	return self.active_duel or false
end

-- Spawns the duel boss for the given duel number and applies scaling.
function SoloDuel:SpawnBoss(pos, duelCount)
	local bossName = BOSS_ROSTER[1]
	if duelCount > 0 then
		bossName = BOSS_ROSTER[((duelCount - 1) % #BOSS_ROSTER) + 1]
	end

	local boss = CreateUnitByName(bossName, pos, true, nil, nil, DOTA_TEAM_NEUTRALS)
	if not boss then
		print("[SOLODUEL] failed to spawn boss", bossName)
		return nil
	end

	boss.IsAngelArenaBoss = true
	boss.duel_boss = true
	boss.duel_scale = duelCount

	FindClearSpaceForUnit(boss, boss:GetOrigin(), true)
	boss:Stop()

	LinkLuaModifier("modifier_boss", 'lib/spawners/modifier_boss', LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_boss_power", 'lib/spawners/modifier_boss_power', LUA_MODIFIER_MOTION_NONE)
	boss:AddNewModifier(boss, nil, "modifier_boss", { duration = -1 })
	boss:AddNewModifier(boss, nil, "modifier_boss_power", { duration = -1 })

	for i = 0, 15 do
		local ab = boss:GetAbilityByIndex(i)
		if ab and ab:GetLevel() == 0 then ab:SetLevel(1) end
	end

	-- scaling: HP and attack damage grow 1.3x per duel
	local tier = math.max(0, (duelCount or 1) - 1)
	local mult = SCALE_PER_DUEL ^ tier
	if mult > 1.0001 then
		local baseHp = boss:GetMaxHealth()
		boss:SetBaseMaxHealth(baseHp * mult)
		boss:SetMaxHealth(baseHp * mult)
		boss:SetBaseDamageMin(boss:GetBaseDamageMin() * mult)
		boss:SetBaseDamageMax(boss:GetBaseDamageMax() * mult)
	end
	boss:SetHealth(boss:GetMaxHealth())

	print("[SOLODUEL] boss spawned:", bossName, "duelCount:", duelCount, "scale:", mult)
	return boss
end

-- Returns false when there are no alive heroes to fight.
function SoloDuel:StartSoloDuel()
	if self.active_duel then return false end

	local aliveHeroes = {}
	local heroes = TeamHelper:GetHeroes(SoloDuel.SOLO_TEAM)
	for _, hero in pairs(heroes) do
		if hero and not hero:IsNull() and IsValidEntity(hero) and hero:IsRealHero() and hero:IsAlive() then
			table.insert(aliveHeroes, hero)
		end
	end
	if #aliveHeroes == 0 then
		print("[SOLODUEL] no alive heroes, solo duel cancelled")
		return false
	end

	DuelLibrary.duelActive = true
	DuelLibrary.duelCount = (DuelLibrary.duelCount or 0) + 1
	DuelLibrary.teamHeroes = { [SoloDuel.SOLO_TEAM] = {} }
	DuelLibrary.alives = { [SoloDuel.SOLO_TEAM] = 0 }
	DuelLibrary.currentWarriors = {}
	-- ВАЖНО: endCallback обязателен — без него DuelLibrary:EndDuel (таймаут/вайп)
	-- не вызовет DuelController:EndDuel, и следующая дуэль не запланируется.
	DuelLibrary.endCallback = function(winnerTeam)
		DuelController:EndDuel(winnerTeam)
	end

	for _, hero in ipairs(aliveHeroes) do
		DuelLibrary.teamHeroes[SoloDuel.SOLO_TEAM][hero] = true
		DuelLibrary.currentWarriors[hero] = 1
	end

	DuelLibrary:MoveToDuel(aliveHeroes, DUEL_POINTS)
	DuelLibrary:_StartTimers()

	local center = GetPointPositionByName("DUEL_ARENA_CENTER")
	if not center then
		print("[SOLODUEL] DUEL_ARENA_CENTER not found, using fallback")
		center = Vector(0, 0, 0)
	end

	self.duel_boss = self:SpawnBoss(center, DuelLibrary.duelCount)
	self.boss_alive = self.duel_boss ~= nil
	self.active_duel = self.boss_alive

	if self.duel_boss then
		DuelBossHUD:Start(self.duel_boss)
	end

	print("[SOLODUEL] solo duel started, duel#", DuelLibrary.duelCount)
	return self.boss_alive
end

-- Called from on_entity_killed.lua when the duel boss dies.
function SoloDuel:OnBossKilled(boss, killer)
	DuelBossHUD:Stop()
	if not self.active_duel then return end
	self.active_duel = false
	self.boss_alive = false
	self.duel_boss = nil

	if boss then
		DuelBossSummon:KillAll(boss)
		boss.duel_boss = nil
		boss.IsAngelArenaBoss = false
	end

	if killer and not killer:IsNull() and IsValidEntity(killer) and killer:IsRealHero() then
		DuelLibrary:EndDuel(killer:GetTeamNumber())
	else
		DuelLibrary:EndDuel(DuelLibrary.DRAW_TEAM)
	end
end

-- Called from DuelController:EndDuel (timeout / all heroes dead / duel ended):
-- despawns the boss if it is still alive.
function SoloDuel:OnDuelEnded()
	DuelBossHUD:Stop()
	if not self.active_duel then return end
	self.active_duel = false

	if self.duel_boss and not self.duel_boss:IsNull() and IsValidEntity(self.duel_boss) then
		DuelBossSummon:KillAll(self.duel_boss)
		if not self.duel_boss:IsNull() then
			self.duel_boss:ForceKill(false)
		end
	end
	self.duel_boss = nil
	self.boss_alive = false
end