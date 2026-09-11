-- lib/duel_bosses/modifiers/modifier_duel_boss_frame.lua
-- Интринзик-«фрейм» дуэльного босса (вешается способностью duel_boss_frame, слот юнита).
-- Две подсистемы «живости» из референса (своя реализация, идея из досье docs/boss_ai_reference.md):
--
-- 1) ПОСТУРА (поствура-метр, паттерн «Sekiro» — переработан 2026-09-03 на схему
--    китайцев modifier_cs_posture_bar, т.к. MODIFIER_EVENT_ON_TAKE_DAMAGE у
--    дуэльного босса молчит (проверено логом: событие не вызывается)):
--      • тик FrameTime(), урон = РАЗНИЦА HP (поллинг, не событие) — 1% макс.HP = +1
--      • стан по боссу копит +2 каждые 0.03с (контроль приближает слом)
--      • lock на время каста (protection/busy) — постура не копится пока кастует
--      • множитель 1/число вражеских героев в 2500 (соло = 1.0)
--      • значение = StackCount модификатора (движковый синк на клиент)
--      • на 100 — «СЛОМ»: стан-нокаут (окно наказания)
--
-- 2) УГРОЗА (threat): счётчик урона по атакующим; GetBestThreatTarget — цель,
--    по которой бьют сильнее всего (босс «помнит» обидчика, а не только ближайшего).
--    ⚠️ Threat тоже сидел на ON_TAKE_DAMAGE — событие мёртвое, threat пуст,
--    GetSmartTarget фолбэчится на ближайшего (осознанно).
--
-- ⚠️ НЕ требует lib/timers (клиентская VM); только IsServer-guard'ы.

if not DuelBossFrameUtil then
	DuelBossFrameUtil = {
		THRESHOLD = 100,            -- порог слома
		PER_HP_PCT = 1.0,           -- 1% макс.HP урона = 1 очко постуры
		COUNTER_BONUS = 15,         -- + за успешный контр-брейк
		CRASH_BONUS = 12,           -- + за врезание в стену (свой таран)
		CAST_DECAY = 3,             -- − за каждый завершённый каст босса (метр «выдыхается»)
		STUN_INTERVAL = 0.03,       -- тик накопления постуры от стана (китайцы: 0.03с)
		STUN_POSTURE_ADD = 2,       -- +2 за интервал стана
		NEARBY_RADIUS = 2500,       -- радиус подсчёта игроков для множителя
		BREAK_STAGGER = 4.0,        -- длительность «слома»
		COUNTER_STAGGER = 0.5,      -- длительность стан-замирания на контр-брейке (как у китайцев: 0.5с)
	}
end

local function EnsureStaggerLink()
	LinkLuaModifier("modifier_duel_boss_stagger", "lib/duel_bosses/modifiers/modifier_duel_boss_stagger", LUA_MODIFIER_MOTION_NONE)
end

modifier_duel_boss_frame = modifier_duel_boss_frame or class({})

function modifier_duel_boss_frame:IsHidden()       return true  end
function modifier_duel_boss_frame:IsPurgable()     return false end
function modifier_duel_boss_frame:IsDebuff()        return false end
function modifier_duel_boss_frame:IsPermanent()    return true  end
function modifier_duel_boss_frame:RemoveOnDeath()  return true  end

function modifier_duel_boss_frame:OnCreated()
	if not IsServer() then return end
	self._posture = 0
	self._threat = {}
	self._lastHp = self:GetParent() and self:GetParent():GetHealth() or 0
	self._stunAccum = 0
	self._breaking = false
	self._mult = 1
	self._multAt = 0
	self:StartIntervalThink(FrameTime())
end

function modifier_duel_boss_frame:DeclareFunctions()
	return {}
end

function modifier_duel_boss_frame:GetPostureValue()
	return self._posture or 0
end

function modifier_duel_boss_frame:AddPosturePoints(v)
	if not IsServer() then return end
	if self._breaking then return end
	self._posture = math.min(DuelBossFrameUtil.THRESHOLD, (self._posture or 0) + math.max(0, v))
	if self._posture >= DuelBossFrameUtil.THRESHOLD then
		self:Break()
	end
end

function modifier_duel_boss_frame:ResetPosture()
	if not IsServer() then return end
	self._posture = 0
end

function modifier_duel_boss_frame:CastCompleted()
	if not IsServer() then return end
	self._posture = math.max(0, (self._posture or 0) - DuelBossFrameUtil.CAST_DECAY)
end

-- ⚠️ «Заблокирован» ли набор постуры: пока босс кастует (защита/канал) или в
-- фазовом окне (неуязвим, застанен) — не копит. Фаза-окно у китайцев = каст с
-- SetPostureLocked(true) на всё окно; у нас фаза отдельная — добавляем явно.
function modifier_duel_boss_frame:IsPostureLocked()
	local p = self:GetParent()
	if not p then return true end
	return p:HasModifier("modifier_duel_boss_cast_protection")
		or p:HasModifier("modifier_duel_boss_busy")
		or p:HasModifier("modifier_duel_boss_phase_window")
end

-- множитель 1/N вражеских героев в радиусе (китайцы: 1/число игроков в 2500)
function modifier_duel_boss_frame:GetNearbyMultiplier()
	local now = GameRules:GetGameTime()
	-- кэш раз в секунду (поллинг каждый кадр — не гонять FindUnitsInRadius)
	if self._multAt and (now - self._multAt) < 1 then
		return self._mult or 1
	end
	self._multAt = now

	local p = self:GetParent()
	if not IsValidEntity(p) then
		self._mult = 1
		return 1
	end
	local heroes = FindUnitsInRadius(
		p:GetTeamNumber(),
		p:GetAbsOrigin(),
		nil,
		DuelBossFrameUtil.NEARBY_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)
	local n = 0
	for _, u in ipairs(heroes) do
		if IsValidEntity(u) and u:IsAlive() then
			n = n + 1
		end
	end
	self._mult = math.max(1, 1 / math.max(1, n))
	return self._mult
end

function modifier_duel_boss_frame:Break()
	local parent = self:GetParent()
	if not IsValidEntity(parent) or not parent:IsAlive() then return end

	self._posture = 0
	self._breaking = true
	EnsureStaggerLink()
	parent:AddNewModifier(parent, self:GetAbility(), "modifier_duel_boss_stagger", {
		duration = DuelBossFrameUtil.BREAK_STAGGER,
		big = 1,
	})

	-- босс не кидает скиллы сразу после «слома»
	parent.duel_next_action_at = GameRules:GetGameTime() + DuelBossFrameUtil.BREAK_STAGGER + 0.8

	Timers:CreateTimer(DuelBossFrameUtil.BREAK_STAGGER + 0.1, function()
		self._breaking = false
		return nil
	end)
end

-- ⚠️ МЁРТВОЕ событие в этой сборке (не вызывается у дуэльного босса, проверено
-- логом 2026-09-03). Оставлено как запасной путь набора постуры/угрозы, если
-- в будущем движок починит ON_TAKE_DAMAGE. Основной набор — HP-дельта в тике.
function modifier_duel_boss_frame:OnTakeDamage(params)
	if not IsServer() then return end

	local parent = self:GetParent()
	if params.unit ~= parent then return end

	local attacker = params.attacker
	if not attacker or not IsValidEntity(attacker) then return end

	local dmg = params.damage or 0
	if dmg <= 0 then return end

	local maxHp = math.max(1, parent:GetMaxHealth())
	self:AddPosturePoints(dmg / maxHp * 100 * DuelBossFrameUtil.PER_HP_PCT)

	local idx = attacker:entindex()
	self._threat[idx] = (self._threat[idx] or 0) + dmg
end

function modifier_duel_boss_frame:OnIntervalThink()
	if not IsServer() then return end

	local parent = self:GetParent()
	if not IsValidEntity(parent) or not parent:IsAlive() then return end

	local now = GameRules:GetGameTime()
	local currentHp = parent:GetHealth()
	local maxHp = math.max(1, parent:GetMaxHealth())

	-- УРОН → ПОСТУРА: HP-дельта (паттерн китайцев — поллинг, не событие).
	-- ⚠️ НЕ блокируем на время каста: босс кастует почти постоянно (КД 5-6с,
	-- каст 2-4с) — с lock'ом ~половина-больше урона выбрасывалась (проверено
	-- в игре 2026-09-03: убил босса → 15%). Lock остаётся только для стано-набора.
	local hpLost = math.max(0, (self._lastHp or currentHp) - currentHp)
	if hpLost > 0 then
		local gain = hpLost / maxHp * 100 * DuelBossFrameUtil.PER_HP_PCT * self:GetNearbyMultiplier()
		self:AddPosturePoints(gain)
	end

	-- СТАН → ПОСТУРА: пока босс в стане, +2 каждые 0.03с (китайцы: ~66.7/с)
	if not self._breaking and not self:IsPostureLocked()
		and (parent:HasModifier("modifier_stunned") or parent:HasModifier("modifier_duel_boss_stagger")) then
		self._stunAccum = (self._stunAccum or 0) + FrameTime()
		while self._stunAccum >= DuelBossFrameUtil.STUN_INTERVAL do
			self._stunAccum = self._stunAccum - DuelBossFrameUtil.STUN_INTERVAL
			self:AddPosturePoints(DuelBossFrameUtil.STUN_POSTURE_ADD)
		end
	else
		self._stunAccum = 0
	end

	self._lastHp = currentHp

	-- затухание угрозы
	for idx, v in pairs(self._threat) do
		v = v * 0.6
		if v < 1 then
			self._threat[idx] = nil
		else
			self._threat[idx] = v
		end
	end
end

-- Цель с наибольшим «счётом угрозы» среди живых врагов в радиусе.
function modifier_duel_boss_frame:GetBestThreatTarget(range)
	if not IsServer() then return nil end

	local parent = self:GetParent()
	local units = FindUnitsInRadius(
		parent:GetTeamNumber(),
		parent:GetAbsOrigin(),
		nil,
		range,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	local best, bestScore
	for _, u in ipairs(units) do
		if IsValidEntity(u) and u:IsAlive() and not u:IsInvulnerable() and not u:IsOutOfGame() then
			local score = self._threat[u:entindex()] or 0
			if score > 0 and (not bestScore or score > bestScore) then
				best, bestScore = u, score
			end
		end
	end

	return best
end

-- ─── статический API для скиллов/HUD ───

function DuelBossFrameUtil:GetFrame(unit)
	if not unit or not IsValidEntity(unit) then return nil end
	return unit:FindModifierByName("modifier_duel_boss_frame")
end

function DuelBossFrameUtil:AddPosture(unit, v)
	local f = self:GetFrame(unit)
	if f then f:AddPosturePoints(v) end
end

function DuelBossFrameUtil:ResetPosture(unit)
	local f = self:GetFrame(unit)
	if f then f:ResetPosture() end
end

function DuelBossFrameUtil:CastCompleted(unit)
	local f = self:GetFrame(unit)
	if f then f:CastCompleted() end
end

function DuelBossFrameUtil:CounterStagger(unit, ability)
	if not IsValidEntity(unit) or not unit:IsAlive() then return end
	EnsureStaggerLink()
	unit:AddNewModifier(unit, ability, "modifier_duel_boss_stagger", {
		duration = DuelBossFrameUtil.COUNTER_STAGGER,
		big = 0,
	})
end

function DuelBossFrameUtil:GetBestThreatTarget(unit, range)
	local f = self:GetFrame(unit)
	if f then return f:GetBestThreatTarget(range) end
	return nil
end
