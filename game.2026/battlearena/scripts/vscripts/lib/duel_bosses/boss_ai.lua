-- lib/duel_bosses/boss_ai.lua
-- AI дуэльных боссов поверх AIController (ритм и ротация — паттерны из досье
-- docs/boss_ai_reference.md §6, свои реализации):
--   1) фазовый переход при HP ≤ порога (один раз) — приоритет;
--   2) «дыхание»: не кастует раньше duel_next_action_at (ставит DuelBossCast),
--      не лезет, пока занят (busy/protection/stagger/stun);
--   3) случайный скилл из пула: threat-цель → дистанционный коридор + анти-повтор,
--      вес ×0.618 после пика (BossPool);
--   4) ATTACK; 5) RETURN (поводок).

require('lib/ai/ai_controller')
require('lib/duel_bosses/boss_pool')
require('lib/duel_bosses/boss_aim')

DuelBossAI = DuelBossAI or class({})

-- opts: abilities = { [name] = weight | {w=, min=, max=} }, phase_ability,
--       phase_pct (60), cast_range (3000 — поиск threat/дистанции для пула),
--       aggro_radius, leash, interval, home, pre_rules,
--       first_delay (nil→rand(2..6), число→фикс, false→сразу),
--       antirepeat (true — последний скилл исключается из выбора),
--       pool_attempts (5 — пере-роллы при провале кандидата)
function DuelBossAI:Create(unit, opts)
	opts = opts or {}

	local pool = BossPool()
	for name, v in pairs(opts.abilities or {}) do
		if type(v) == "table" then
			pool:Add(name, v.w or 1000, v.min or 0, v.max or 99999)
		else
			pool:Add(name, v)
		end
	end

	local brain = AIController(unit, {
		aggro_radius = opts.aggro_radius or 1200,
		home = opts.home,
	})

	brain.duel_pool = pool
	brain.duel_phase_ability = opts.phase_ability
	brain.duel_phase_pct = opts.phase_pct or 60
	brain.duel_cast_range = opts.cast_range or 3000
	brain.duel_last_cast = nil
	-- анти-повтор по умолчанию ВКЛ (возврат к референсу; тюнинг 03.09 «может дважды»
	-- теперь опцией): последний кастенный скилл исключается из следующего выбора.
	brain.duel_antirepeat = opts.antirepeat ~= false
	-- пере-роллы при провале кандидата (как у китайцев, до 5 попыток)
	brain.duel_pool_attempts = opts.pool_attempts or 5

	-- «раскачка»: первый каст не раньше чем через 2..6с после создания мозга
	-- (nil → случайная задержка; число → фикс; false → сразу)
	local first_delay = opts.first_delay
	if first_delay == nil then
		first_delay = RandomFloat(2, 6)
	end
	if first_delay then
		unit.duel_next_action_at = GameRules:GetGameTime() + first_delay
	end

	local rules = {}

	if opts.phase_ability then
		rules[#rules + 1] = {
			action = AI_ACTIONS.CAST,
			ability = opts.phase_ability,
			check = function(self, rule)
				return not self.entity.duel_phase_done
					and self.entity:GetHealthPercent() <= self.duel_phase_pct
			end,
		}
	end

	-- pre_rules: приоритетные правила перед случайным пулом
	for _, rule in ipairs(opts.pre_rules or {}) do
		rule._index = #rules + 1
		rules[#rules + 1] = rule
	end

	rules[#rules + 1] = {
		action = function(self, rule)
			local e = self.entity
			local now = GameRules:GetGameTime()

			-- занят: каст/канал/стан/замирание
			if e:HasModifier("modifier_duel_boss_busy")
				or e:HasModifier("modifier_duel_boss_cast_protection")
				or e:HasModifier("modifier_duel_boss_stagger")
				or e:HasModifier("modifier_stunned") then
				return false
			end

			-- «дыхание»: пауза после последнего каста
			if (e.duel_next_action_at or 0) > now then return false end

			-- threat-таргет, иначе ближайший
			local target = DuelBossAim:GetSmartTarget(e, self.duel_cast_range)
			if not target then return false end

			local dist = (target:GetAbsOrigin() - e:GetAbsOrigin()):Length2D()

			-- коридоры фильтруем по БЛИЖАЙШЕМУ врагу, а не только по threat-цели:
			-- иначе милишник, вцепившийся сбоку (smart target при этом в 800+),
			-- никогда не активирует ближние скиллы (Deadeye hookshot молчал в упор)
			local nearest = dist
			for _, en in ipairs(self.enemies or {}) do
				if IsValidEntity(en) and en:IsAlive() and not en:IsCourier() then
					local d = (en:GetAbsOrigin() - e:GetAbsOrigin()):Length2D()
					if d < nearest then nearest = d end
				end
			end
			dist = nearest

			-- пере-роллы: до pool_attempts попыток; провалившийся кандидат
			-- получает вес ×0.618 (BossPool:Decay) — как «перевыборы» у китайцев
			local name = nil
			for _ = 1, self.duel_pool_attempts do
				name = self.duel_pool:PickCandidate(dist, self.duel_antirepeat and self.duel_last_cast or nil)
				if not name then break end

				local ability = e:FindAbilityByName(name)
				if IsValidEntity(ability) and ability:IsFullyCastable() and ability:GetCooldownTimeRemaining() <= 0 then
					break
				end

				-- [TEMP-DEBUG] почему кандидат отброшен
				if e.duel_debug then
					local ab = IsValidEntity(ability) and ability or nil
					print("[POOL-DBG] skip " .. tostring(name) .. " dist=" .. string.format("%.0f", dist)
						.. " exists=" .. tostring(IsValidEntity(ability))
						.. (ab and (" lvl=" .. ab:GetLevel() .. " full=" .. tostring(ab:IsFullyCastable())
							.. " cd=" .. string.format("%.1f", ab:GetCooldownTimeRemaining())
							.. " beh=" .. tostring(ab:GetBehaviorInt())
							.. " cdT=" .. string.format("%.1f", ab:GetCooldown(0))) or ""))
				end

				self.duel_pool:Decay(name)
				name = nil
			end
			if not name then
				if e.duel_debug then print("[POOL-DBG] NO candidate, dist=" .. string.format("%.0f", dist)) end
				return false
			end

			local ability = e:FindAbilityByName(name)
			if not IsValidEntity(ability) then return false end

			-- каст по поведению способности (прямые методы):
			-- UNIT_TARGET → ближайшая цель, POINT → её позиция, иначе NoTarget
			local flags = ability:GetBehaviorInt()
			if bit.band(flags, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) ~= 0 then
				e:CastAbilityOnTarget(target, ability, -1)
			elseif bit.band(flags, DOTA_ABILITY_BEHAVIOR_POINT) ~= 0 then
				e:CastAbilityOnPosition(target:GetAbsOrigin(), ability, -1)
			else
				e:CastAbilityNoTarget(ability, -1)
			end

			self.duel_last_cast = name
			if e.duel_debug then print("[POOL-DBG] CAST " .. name .. " dist=" .. string.format("%.0f", dist)) end
			return true
		end,
	}

	rules[#rules + 1] = { action = AI_ACTIONS.ATTACK, min_enemies = 1 }

	rules[#rules + 1] = { action = AI_ACTIONS.RETURN, max_distance = opts.leash or 1200 }

	brain:SetRules(rules)
	brain:Start(opts.interval or 0.5)

	unit.brain = brain

	return brain
end
