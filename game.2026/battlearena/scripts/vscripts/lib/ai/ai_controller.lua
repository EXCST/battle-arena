-- ============================================================
-- BATTLE ARENA — AIController
-- Декларативный движок ИИ на правилах с явным приоритетом.
-- Каждые interval секунд выполняется первое подходящее правило.
--
-- Использование:
--   local brain = AIController(unit, { aggro_radius = 1200 })
--   brain:SetRules({
--       { action = AI_ACTIONS.CAST,   ability = "x", min_enemies = 2 },
--       { action = AI_ACTIONS.ATTACK, min_enemies = 1 },
--       { action = AI_ACTIONS.RETURN, max_distance = 1200 },
--   })
--   brain:Start(0.5)
--   unit.brain = brain
--
-- Условия правил:
--   health_pct           — HP% юнита должен быть НЕ выше значения
--   mana_pct             — маны % должен быть НЕ ниже значения
--   min_enemies          — минимум врагов в радиусе агро
--   cooldown             — не чаще чем раз в N секунд (на правило)
--   min_idle             — только после N тиков простоя без действий
--   allowed_while_returning — разрешено, пока босс возвращается на базу
--   check                — кастомная функция conditions: function(self, rule) -> bool
--   can_cast             — per-скилл гейт для CAST: function(self, rule, ability) -> bool
--                          (проверяется после готовности/КД способности)
--   range                — фолбэк дальности цели, если GetCastRange способности = 0
--                          (иначе self.aggro_radius)
--
-- Действия правил (AI_ACTIONS):
--   CAST    — каст способности по поведению (target / point / no-target)
--   ATTACK  — атаковать ближайшего врага
--   RETURN  — вернуться на базу, если далеко или рядом нет врагов
--   function(self, rule) — произвольное кастомное действие
-- ============================================================

require('lib/timers')

AIController = AIController or class({})

AI_ACTIONS = {
	CAST    = 1,
	ATTACK  = 2,
	RETURN  = 3,
}

local DEFAULT_AGGRO_RADIUS = 1100
local RETURN_ARRIVED_DISTANCE = 150
local RETURN_REISSUE_DISTANCE = 100


--- Проверка флага поведения способности.
--- По docs.moddota.com: GetBehaviorInt() возвращает флаги как int
--- (GetBehavior() в текущих версиях движка возвращает userdata-перечисление).
local function HasBehavior(ability, behavior)
	return bit.band(ability:GetBehaviorInt(), behavior) ~= 0
end


function AIController:constructor(entity, options)
	options = options or {}

	self.entity = entity
	self.home = options.home

	self.aggro_radius = options.aggro_radius or DEFAULT_AGGRO_RADIUS

	self.abilities = {}
	self.rules = {}
	self.enemies = {}

	self.current_location = self.entity:GetOrigin()

	self.returning = false
	self.idle_counter = 0
	self.active_rule_index = nil
	self.last_execute_time = {}
end


function AIController:SetRules(ruleset)
	self.rules = ruleset

	for index, rule in ipairs(self.rules) do
		rule._index = index

		if rule.action == AI_ACTIONS.CAST then
			self.abilities[rule.ability] = self.entity:FindAbilityByName(rule.ability)
		end
	end
end


--- Позволяет внешнему коду менять точку возврата (телепорт, перемещение базы).
function AIController:SetHome(position)
	self.home = position
end


function AIController:Start(interval)
	self.interval = interval or 0.5

	self.timer_name = Timers:CreateTimer(self.interval, function()
		-- защита тика: ошибка печатается и не убивает таймер молча
		local ok, res = pcall(function() return self:Tick() end)

		if not ok then
			print("[AIController] tick error on " .. tostring(self.entity and self.entity:GetUnitName() or "unknown") .. ": " .. tostring(res))
			return nil
		end

		return res
	end)
end


function AIController:Stop()
	if self.timer_name then
		Timers:RemoveTimer(self.timer_name)
		self.timer_name = nil
	end
end


function AIController:Tick()
	if not IsValidEntity(self.entity) or not self.entity:IsAlive() then
		return nil
	end

	-- юнит занят: оглушён, кастует, каналирует
	if self.entity:IsStunned() or self.entity:IsHexed() then return self.interval end
	if self.entity:GetCurrentActiveAbility() then return self.interval end
	if self.entity:IsChanneling() then return self.interval end
	self.current_location = self.entity:GetOrigin()

	-- база: захватываем, когда позиция достоверна (в первые тики может быть (0,0,0))
	if self.home == nil or (self.home:Length2D() == 0 and self.current_location:Length2D() > 1) then
		local origin = self.entity:GetAbsOrigin()

		if origin:Length2D() > 1 then
			self.home = origin
		elseif self.current_location:Length2D() > 1 then
			self.home = self.current_location
		end
	end

	self:Scan()

	for index, rule in ipairs(self.rules) do
		if self:ApplyRule(rule) then
			self.active_rule_index = index
			self.idle_counter = 0
			self.last_execute_time[index] = GameRules:GetGameTime()
			return self.interval
		end
	end

	self.idle_counter = self.idle_counter + 1
	return self.interval
end


function AIController:ApplyRule(rule)
	local ok, executed = xpcall(function()
		return self:CheckRule(rule) and self:ExecuteRule(rule) or false
	end, function(err)
		return "in rule #" .. tostring(rule._index) .. ": " .. tostring(err)
	end)

	if not ok then
		print("[AIController] rule error on " .. self.entity:GetUnitName() .. ": " .. tostring(executed))
		return false
	end

	return executed
end


function AIController:CheckRule(rule)
	if rule.health_pct and self.entity:GetHealthPercent() > rule.health_pct then return false end
	if rule.mana_pct and self.entity:GetManaPercent() < rule.mana_pct then return false end
	if rule.min_enemies and #self.enemies < rule.min_enemies then return false end

	if rule.cooldown then
		local last = self.last_execute_time[rule._index]
		if last and GameRules:GetGameTime() - last < rule.cooldown then return false end
	end

	if rule.min_idle and self.idle_counter < rule.min_idle then return false end

	if self.returning and rule.action ~= AI_ACTIONS.RETURN and not rule.allowed_while_returning then return false end

	if rule.check and not rule.check(self, rule) then return false end

	return true
end


function AIController:ExecuteRule(rule)
	local action = rule.action

	if action == AI_ACTIONS.CAST then return self:TryCast(rule) end
	if action == AI_ACTIONS.ATTACK then return self:TryAttack(rule) end
	if action == AI_ACTIONS.RETURN then return self:TryReturn(rule) end

	if type(action) == "function" then return action(self, rule) end

	return false
end


---------------------------------------------------------------------------
-- CAST
---------------------------------------------------------------------------

function AIController:TryCast(rule)
	local ability = self.abilities[rule.ability]
	if not IsValidEntity(ability) then return false end
	if not ability:IsFullyCastable() then return false end
	if ability:GetCooldownTimeRemaining() > 0 then return false end

	-- per-скилл гейт (правило может проверять таргет-тип/дистанцию/окружение)
	if rule.can_cast and not rule.can_cast(self, rule, ability) then return false end

	local is_unit_target = HasBehavior(ability, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET)
	local is_point = HasBehavior(ability, DOTA_ABILITY_BEHAVIOR_POINT)

	-- без цели: просто кастуем (min_enemies уже проверен в CheckRule по всему агро)
	if not is_unit_target and not is_point then
		self:Cast(self.entity, ability, nil)
		return true
	end

	local cast_range = ability:GetCastRange(self.current_location, self.entity)
	if cast_range <= 0 then
		-- скилл без диапазона в KV (GetCastRange = 0): фолбэк на правило/агро
		cast_range = rule.range or self.aggro_radius
	end

	local targets = self:FilterEnemies(cast_range)

	for _, enemy in ipairs(targets) do
		if IsValidEntity(enemy) and enemy:IsAlive() and not enemy:IsCourier() and not enemy:IsInvulnerable() then
			self:Cast(self.entity, ability, enemy)
			return true
		end
	end

	return false
end


function AIController:Cast(unit, ability, target)
	-- прямые методы каста (паттерн проекта: soul_guardian, golem) — надёжнее ExecuteOrderFromTable
	if HasBehavior(ability, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
		unit:CastAbilityOnTarget(target, ability, -1)
	elseif HasBehavior(ability, DOTA_ABILITY_BEHAVIOR_POINT) then
		unit:CastAbilityOnPosition(target:GetOrigin(), ability, -1)
	else
		unit:CastAbilityNoTarget(ability, -1)
	end
end


---------------------------------------------------------------------------
-- ATTACK
---------------------------------------------------------------------------

function AIController:TryAttack(rule)
	local enemy = self:GetFirstEnemy()

	if IsValidEntity(enemy) then
		enemy:RemoveModifierByName("modifier_smoke_of_deceit")
		self.entity:MoveToTargetToAttack(enemy)
		return true
	end

	-- варды — в самую последнюю очередь, только автоатака (без способностей)
	local ward = self:GetFirstWard()

	if IsValidEntity(ward) then
		self.entity:MoveToTargetToAttack(ward)
		return true
	end

	return false
end


function AIController:GetFirstWard()
	for _, entity in ipairs(self.wards or {}) do
		if IsValidEntity(entity) and entity:IsAlive() and not entity:IsCourier()
			and not entity:IsAttackImmune() and not entity:IsInvulnerable() and not entity:IsOutOfGame() then
			return entity
		end
	end
end


---------------------------------------------------------------------------
-- RETURN
---------------------------------------------------------------------------

function AIController:TryReturn(rule)
	if not self.home then return false end

	local distance_to_home = (self.current_location - self.home):Length2D()
	local enemy_count = #self.enemies

	if distance_to_home >= rule.max_distance or (self.returning and distance_to_home > RETURN_REISSUE_DISTANCE) then
		self.entity:MoveToPosition(self.home)
		self.returning = true
		return true
	end

	if enemy_count <= (rule.current_enemies or 0) and distance_to_home > RETURN_ARRIVED_DISTANCE then
		self.entity:MoveToPosition(self.home)
		self.returning = true
		return true
	end

	if distance_to_home < RETURN_ARRIVED_DISTANCE then
		self.returning = false
	end

	return false
end


---------------------------------------------------------------------------
-- Сканирование окружения
---------------------------------------------------------------------------

function AIController:Scan()
	local enemies = FindUnitsInRadius(
		self.entity:GetTeam(),
		self.current_location,
		nil,
		self.aggro_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_OTHER,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_CLOSEST,
		false
	)

	-- варды (IsOther) уходят в отдельный список self.wards: они НЕ считаются
	-- врагами для кастов/min_enemies, атакуются только в последнюю очередь.
	-- Призывы (IsSummoned) остаются в общем списке, но в конце.
	local wards = {}
	local deferred = {}
	local write_index = 1

	for read_index = 1, #enemies do
		local unit = enemies[read_index]

		if unit.IsOther and unit:IsOther() then
			wards[#wards + 1] = unit
		elseif unit.IsSummoned and unit:IsSummoned() then
			deferred[#deferred + 1] = unit
		else
			enemies[write_index] = unit
			write_index = write_index + 1
		end
	end

	for _, unit in ipairs(deferred) do
		enemies[write_index] = unit
		write_index = write_index + 1
	end

	self.enemies = enemies
	self.wards = wards
end


function AIController:FilterEnemies(max_radius)
	local enemies = {}

	for _, enemy in ipairs(self.enemies or {}) do
		if not enemy:IsCourier() and (enemy:GetOrigin() - self.entity:GetOrigin()):Length2D() <= max_radius then
			table.insert(enemies, enemy)
		end
	end

	return enemies
end


function AIController:GetFirstEnemy()
	for _, entity in ipairs(self.enemies or {}) do
		if IsValidEntity(entity) and entity:IsAlive() and not entity:IsCourier()
			and not entity:IsAttackImmune() and not entity:IsInvulnerable() and not entity:IsOutOfGame() then
			return entity
		end
	end
end
