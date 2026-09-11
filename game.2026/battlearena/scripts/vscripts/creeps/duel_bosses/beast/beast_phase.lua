-- creeps/duel_bosses/beast/beast_phase.lua
-- «Ярость» — фазовый переход при HP ≤ 60% (один раз), окно 10с:
--   возврат к спавну → купол + затемнение экрана + Upheaval-зона (r=2000, стаки
--   −12% MS / −7% AS каждые 1.5с, снимается в конце фазы)
--   → ТРИ залпа каменных волн (паттерн elite_025 референса, досье §11):
--       t≈1.2 «плюс» (4 волны) → t≈3.6 «икс» (4 волны, +45°) → t≈6.0 «звёздочка» (8 волн)
--   → финальный топот t≈8.2 → бафф 2-й фазы + призыв гончих.
-- Волна: фронт r=250, 500 u/s, 3с (1500 юнитов), тиковый урон 8% макс.HP +
-- стан 0.1с каждые 0.2с (паттерн elite_025 «Обвал» — дрожание-лок без hit-map).

-- LinkLuaModifier здесь (не только в addon_game_mode): клиент узнаёт классы
-- модификаторов через ScriptFile способности — thinker-частицы лавины и зона
-- должны рендериться на клиенте.
LinkLuaModifier("modifier_duel_boss_avalanche", "lib/duel_bosses/modifiers/modifier_duel_boss_avalanche", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_duel_boss_upheaval_zone", "lib/duel_bosses/modifiers/modifier_duel_boss_upheaval", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_duel_boss_upheaval", "lib/duel_bosses/modifiers/modifier_duel_boss_upheaval", LUA_MODIFIER_MOTION_NONE)

require('lib/duel_bosses/boss_phase')
require('lib/duel_bosses/boss_summon')
require('lib/duel_bosses/boss_aim')
require('lib/duel_bosses/boss_warning')
require('lib/duel_bosses/boss_damage')
-- ⚠️ БЕЗ require('lib/timers') — клиентская VM падает (см. AGENTS.md); Timers — глобал

ba_duel_beast_phase = ba_duel_beast_phase or class({})

local WINDOW = 10
local RETURN_DUR = 0.8
local HOUND_COUNT = 3

local ZONE_RADIUS = 2500

-- залпы: время от старта окна; count=лучей; rot=смещение от базы (0/45/0)
local SALVOS = {
	{ t = 1.2, count = 4, rot = 0 },
	{ t = 3.6, count = 4, rot = 45 },
	{ t = 6.0, count = 8, rot = 0 },
}
local WAVE_LIFE = 3
local WAVE_DIST = 1450
local WAVE_WARN = 0.6
local WAVE_WIDTH = 500

local TRAMPLE_TIME = 8.2
local TRAMPLE_RADIUS = 550
local TRAMPLE_DAMAGE_PCT = 8
local TRAMPLE_STUN = 0.5

function ba_duel_beast_phase:FireSalvo(caster, baseDir, rot, count)
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	local origin = caster:GetAbsOrigin()

	caster:EmitSound("Hero_EarthShaker.Fissure.Cast")
	ScreenShake(origin, 8, 8, 1.2, 3000, 0, true)

	for i = 0, count - 1 do
		local dir = DuelBossAim:RotateVector2D(baseDir, rot + i * (360 / count))
		dir.z = 0

		-- теллур живёт ВСЁ время полёта волны (0.6с предупреждение + 3с волна) —
		-- видно, куда едет обвал; growTime = время вырастания линии
		DuelBossWarning:Line(caster, self, origin + dir * 160, origin + dir * WAVE_DIST, WAVE_WARN + WAVE_LIFE, {
			startWidth = WAVE_WIDTH,
			endWidth = WAVE_WIDTH,
			type = 1,
			growTime = WAVE_WARN,
		})

		Timers:CreateTimer(WAVE_WARN, function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return nil end

			local spawnPos = caster:GetAbsOrigin() + dir * 160
			spawnPos.z = GetGroundPosition(spawnPos, caster).z

			CreateModifierThinker(
				caster,
				self,
				"modifier_duel_boss_avalanche",
				{ duration = WAVE_LIFE, dir_x = dir.x, dir_y = dir.y },
				spawnPos,
				caster:GetTeamNumber(),
				false
			)

			return nil
		end)
	end
end

function ba_duel_beast_phase:FinalTrample(caster)
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	local center = caster:GetAbsOrigin()
	DuelBossWarning:RedCircle(caster, self, center, TRAMPLE_RADIUS, 1.0)
	caster:EmitSound("Hero_PrimalBeast.Trample.Cast")

	Timers:CreateTimer(1.0, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end

		local victims = FindUnitsInRadius(
			caster:GetTeamNumber(),
			center,
			nil,
			TRAMPLE_RADIUS,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			0,
			FIND_CLOSEST,
			false
		)

		for _, v in ipairs(victims) do
			if IsValidEntity(v) and v:IsAlive() and not v:IsCourier() then
				DuelBossDamage:Deal(self, caster, v, TRAMPLE_DAMAGE_PCT, 0)
				DuelBossDamage:Stun(v, caster, self, TRAMPLE_STUN)
			end
		end

		return nil
	end)
end

function ba_duel_beast_phase:OnSpellStart()
	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	-- фаза один раз за бой (gate-правило DuelBossAI читает флаг)
	caster.duel_phase_done = true

	-- «слом» постура сбрасывается при фазе (чистый лист после ярости)
	require('lib/duel_bosses/modifiers/modifier_duel_boss_frame')
	DuelBossFrameUtil:ResetPosture(caster)

	caster:EmitSound("Hero_PrimalBeast.Trample.Cast")

	-- база углов залпов: направление на ближайшего героя + джиттер (фиксируется на касте)
	local baseDir = Vector(1, 0, 0)
	Timers:CreateTimer(RETURN_DUR, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		local target = DuelBossAim:GetNearestEnemy(caster, 3500)
		if target then
			local dir = target:GetAbsOrigin() - caster:GetAbsOrigin()
			dir.z = 0
			if dir:Length2D() > 1 then
				baseDir = DuelBossAim:RotateVector2D(dir:Normalized(), RandomFloat(-15, 15))
			end
		end

		-- Upheaval-зона на всё окно (снимает стаки сама при конце)
		caster:AddNewModifier(caster, self, "modifier_duel_boss_upheaval_zone", {
			duration = WINDOW,
			radius = ZONE_RADIUS,
		})

		return nil
	end)

	for _, salvo in ipairs(SALVOS) do
		Timers:CreateTimer(RETURN_DUR + salvo.t, function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
			local ok, err = pcall(function() self:FireSalvo(caster, baseDir, salvo.rot, salvo.count) end)
			if not ok then
				print("[BEAST-PHASE] salvo error: " .. tostring(err))
			end
			return nil
		end)
	end

	Timers:CreateTimer(RETURN_DUR + TRAMPLE_TIME, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		self:FinalTrample(caster)
		return nil
	end)

	-- купол ability_001_red УБРАН (2026-09-03): r=2500, камера внутри → экран
	-- целиком «затемняется» — именно его пользователь просил убрать 3 раза.

	DuelBossPhase:Run(caster, self, {
		window = WINDOW,
		returnDur = RETURN_DUR,
		buff = true,
		onWindowEnd = function(unit)
			if not IsValidEntity(unit) or not unit:IsAlive() then return end

			for i = 1, HOUND_COUNT do
				local pos = unit:GetAbsOrigin() + RandomVector(400)
				pos.z = unit:GetAbsOrigin().z
				DuelBossSummon:Create(unit, self, "npc_ba_duel_hound", pos, "beast_hound", HOUND_COUNT, {
					protect = 0.6,
					chase = true,
				})
			end
		end,
	})
end
