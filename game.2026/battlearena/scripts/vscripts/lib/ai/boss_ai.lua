-- ============================================================
-- BATTLE ARENA — Boss AI engine
-- Written from scratch for modern Dota 2 (Source 2).
-- Drives boss behaviour: spellcasting, chasing, returning home.
--
-- Usage:
--   local brain = BossBrain(unit)
--   brain:AddCastRule("possessed_devil_stomp", { min_targets = 1 })
--   brain:AddCastRule("possessed_hellshield", { hp_below = 75, min_targets = 1 })
--   brain:AddAttackRule()
--   brain:AddReturnRule(1100)
--   brain:Run(0.5)
-- ============================================================

require('lib/timers')

BossBrain = BossBrain or class({})

-- rule kinds
BOSS_RULE_CAST   = 1
BOSS_RULE_ATTACK = 2
BOSS_RULE_RETURN = 3


--- Scan for nearby enemies once per tick (cached for all rules).
function BossBrain:_Scan()
	self.enemies = FindUnitsInRadius(
		DOTA_TEAM_NEUTRALS,
		self.unit:GetAbsOrigin(),
		nil,
		self.scan_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_CLOSEST,
		false
	)
end


--- Add a rule: cast a spell when conditions are met.
--- cond: min_targets (number), hp_below (percent), only_once (bool)
function BossBrain:AddCastRule(ability_name, cond)
	cond = cond or {}
	table.insert(self.rules, {
		kind = BOSS_RULE_CAST,
		ability_name = ability_name,
		ability = self.unit:FindAbilityByName(ability_name),
		min_targets = cond.min_targets or 1,
		hp_below = cond.hp_below or 100,
		only_once = cond.only_once or false,
		used = false,
	})
end


function BossBrain:AddAttackRule()
	table.insert(self.rules, { kind = BOSS_RULE_ATTACK })
end


function BossBrain:AddReturnRule(max_distance)
	table.insert(self.rules, { kind = BOSS_RULE_RETURN, max_distance = max_distance or 1200 })
end


--- Kick off the brain loop.
function BossBrain:Run(interval)
	interval = interval or 0.5

	self.tick_count = 0

	Timers:CreateTimer(interval, function()
		if not IsValidEntity(self.unit) or self.unit:IsNull() or not self.unit:IsAlive() then
			return nil
		end

		self.tick_count = self.tick_count + 1
		if self.tick_count % 10 == 0 then
			print("[BOSS_AI] tick " .. self.tick_count .. " on " .. self.unit:GetUnitName())
		end

		-- don't act while busy
		if self.unit:IsStunned() or self.unit:IsHexed() or self.unit:IsChanneling() then
			return interval
		end

		self:_Scan()

		for _, rule in ipairs(self.rules) do
			local busy = self:_Execute(rule)
			if busy then
				return interval
			end
		end

		return interval
	end)
end


function BossBrain:_Execute(rule)
	if rule.kind == BOSS_RULE_CAST then
		return self:_TryCast(rule)
	elseif rule.kind == BOSS_RULE_ATTACK then
		return self:_TryAttack()
	elseif rule.kind == BOSS_RULE_RETURN then
		return self:_TryReturn(rule)
	end
	return false
end


function BossBrain:_TryCast(rule)
	if rule.used and rule.only_once then return false end
	if not IsValidEntity(rule.ability) then return false end
	if rule.ability:GetCooldownTimeRemaining() > 0 then return false end
	if not rule.ability:IsFullyCastable() then return false end

	-- hp gate
	if self.unit:GetHealthPercent() > rule.hp_below then return false end

	-- find valid targets in range
	local cast_range = rule.ability:GetCastRange(self.unit:GetAbsOrigin(), self.unit)
	local target = nil

	print("[BOSS_AI] TryCast " .. rule.ability_name .. " cd=" .. rule.ability:GetCooldownTimeRemaining() .. " hp=" .. self.unit:GetHealthPercent() .. " range=" .. tostring(cast_range) .. " enemies=" .. tostring(#(self.enemies or {})))

	for _, enemy in ipairs(self.enemies) do
		if IsValidEntity(enemy) and not enemy:IsCourier() and not enemy:IsInvulnerable() then
			if (enemy:GetAbsOrigin() - self.unit:GetAbsOrigin()):Length2D() <= cast_range then
				target = enemy
				break
			end
		end
	end

	if not target then
		print("[BOSS_AI] NO TARGET in range for " .. rule.ability_name)
		return false
	end

	-- count how many enemies are actually in range (for min_targets)
	local in_range = 0
	for _, enemy in ipairs(self.enemies) do
		if IsValidEntity(enemy) and not enemy:IsCourier() and not enemy:IsInvulnerable() then
			if (enemy:GetAbsOrigin() - self.unit:GetAbsOrigin()):Length2D() <= cast_range then
				in_range = in_range + 1
			end
		end
	end

	if in_range < rule.min_targets then
		print("[BOSS_AI] NOT ENOUGH TARGETS (" .. in_range .. "/" .. rule.min_targets .. ") for " .. rule.ability_name)
		return false
	end

	print("[BOSS_AI] about to cast " .. rule.ability_name .. " target=" .. tostring(target:GetUnitName()))

	-- pick the cast order flavour by behaviour flags
	local behavior = rule.ability:GetBehavior()

	if bit.band(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) ~= 0 then
		ExecuteOrderFromTable({
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			TargetIndex = target:entindex(),
			AbilityIndex = rule.ability:entindex(),
		})
	elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_POINT) ~= 0 then
		ExecuteOrderFromTable({
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
			Position = target:GetAbsOrigin(),
			AbilityIndex = rule.ability:entindex(),
		})
	else
		ExecuteOrderFromTable({
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = rule.ability:entindex(),
		})
	end

	print("[BOSS_AI] CASTED " .. rule.ability_name)

	rule.used = true

	return true
end


function BossBrain:_TryAttack()
	for _, enemy in ipairs(self.enemies) do
		if IsValidEntity(enemy) and enemy:IsAlive() and not enemy:IsCourier() then
			self.unit:MoveToTargetToAttack(enemy)
			return true
		end
	end
	return false
end


function BossBrain:_TryReturn(rule)
	local distance = (self.unit:GetAbsOrigin() - self.home):Length2D()

	if distance > rule.max_distance then
		self.unit:MoveToPosition(self.home)
		return true
	end

	return false
end
