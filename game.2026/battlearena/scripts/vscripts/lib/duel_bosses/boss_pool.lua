-- lib/duel_bosses/boss_pool.lua
-- Взвешенный пул скиллов (адапт. RandomPool+0.618 референса) + ДИСТАНЦИОННЫЕ КОРИДОРЫ
-- и анти-повтор (паттерн Lina-Soul из референса: скилл знает, с какой дистанции он уместен).
--
--   pool:Add(name, weight)                       — без ограничений дистанции
--   pool:Add(name, weight, minDist, maxDist)     — коридор до цели
--   pool:PickCandidate(dist, lastName)           — взвешенный выбор из подходящих;
--     lastName (последний скилл) исключается, если есть ≥2 кандидатов.
--   pool:Pick()                                  — старый API без коридоров.
-- После пика вес × 0.618 (мин 1) — «золотое затухание» против спама.

BossPool = BossPool or class({})

local DECAY = 0.618

function BossPool:constructor()
	self.names = {}
	self.weights = {}
	self.mins = {}
	self.maxs = {}
end

function BossPool:Add(name, weight, minDist, maxDist)
	if self.weights[name] then
		self.weights[name] = weight or 1000
		return
	end
	self.names[#self.names + 1] = name
	self.weights[name] = weight or 1000
	self.mins[name] = minDist or 0
	self.maxs[name] = maxDist or 99999
end

function BossPool:_candidates(dist, lastName)
	local list = {}
	for _, name in ipairs(self.names) do
		if dist >= self.mins[name] and dist <= self.maxs[name] then
			list[#list + 1] = name
		end
	end

	if lastName and #list > 1 then
		local without = {}
		for _, name in ipairs(list) do
			if name ~= lastName then
				without[#without + 1] = name
			end
		end
		if #without > 0 then
			list = without
		end
	end

	return list
end

function BossPool:_roll(list)
	local total = 0
	for _, name in ipairs(list) do
		total = total + self.weights[name]
	end
	if total <= 0 then return nil end

	local roll = RandomFloat(0, total)
	local acc = 0
	for _, name in ipairs(list) do
		acc = acc + self.weights[name]
		if roll <= acc then
			self.weights[name] = math.max(1, self.weights[name] * DECAY)
			return name
		end
	end

	local last = list[#list]
	self.weights[last] = math.max(1, self.weights[last] * DECAY)
	return last
end

-- Вес конкретного скилла ×0.618 (мин 1). Вызывается из пере-роллов при провале
-- кандидата (семантика референса: вес уменьшается и на неудачных попытках).
function BossPool:Decay(name)
	if name and self.weights[name] then
		self.weights[name] = math.max(1, self.weights[name] * DECAY)
	end
end

function BossPool:PickCandidate(dist, lastName)
	if #self.names == 0 then return nil end
	local list = self:_candidates(dist or 0, lastName)
	if #list == 0 then return nil end
	return self:_roll(list)
end

function BossPool:Pick()
	return self:PickCandidate(0, nil)
end
