-- lib/duel_bosses/boss_hud.lua
-- Серверный тик неттэйбла duel_boss_hud: имя/HP/кастбар (с окном контр-брейка)/
-- поствура/стаггер текущего дуэльного босса. Панель duel_boss_bar читает на клиенте.
-- solo_duel вызывает DuelBossHUD:Start(boss) после спавна и :Stop() на финале дуэли.
-- ⚠️ БЕЗ require('lib/timers') — Timers глобал на сервере.
require('lib/duel_bosses/modifiers/modifier_duel_boss_frame')

if not DuelBossHUD then
	DuelBossHUD = {}
end

local HUD_NAME_KEYS = {
	npc_ba_duel_boss_01 = "#duel_boss_beast",
	npc_ba_duel_boss_02 = "#duel_boss_skull",
	npc_ba_duel_boss_03 = "#duel_boss_deadeye",
}

local function safeRemain(mod)
	if not mod then return 0 end
	local ok, r = pcall(function() return mod:GetRemainingTime() end)
	if ok and r and r > 0 then return r end
	return 0
end

function DuelBossHUD:Start(boss)
	if not IsServer() then return end
	self:Stop()
	self._boss = boss
	self._stop = false

	Timers:CreateTimer(0.1, function()
		if self._stop then
			self._stop = false
			return nil
		end

		local b = self._boss
		if not b or not IsValidEntity(b) or not b:IsAlive() then
			self._boss = nil
			CustomNetTables:SetTableValue("duel_boss_hud", "state", { active = 0 })
			return nil
		end

		local castRemain, castTotal, castWindow = 0, 0, 0
		local prot = b:FindModifierByName("modifier_duel_boss_cast_protection")
		if prot then
			castRemain = safeRemain(prot)
			castTotal = prot._total or 0
			castWindow = prot._window or 0
		end

		local posture = 0
		local frame = b:FindModifierByName("modifier_duel_boss_frame")
		if frame then
			posture = frame:GetPostureValue()
		end

		local stagger = 0
		local st = b:FindModifierByName("modifier_duel_boss_stagger")
		if st then
			stagger = safeRemain(st)
			if st._end then
				stagger = math.min(stagger, math.max(0, st._end - GameRules:GetGameTime()))
			end
		end

		CustomNetTables:SetTableValue("duel_boss_hud", "state", {
			active = 1,
			name = HUD_NAME_KEYS[b:GetUnitName()] or "#duel_boss_generic",
			hp = math.floor(b:GetHealth()),
			hpmax = math.max(1, math.floor(b:GetMaxHealth())),
			cast_remain = castRemain,
			cast_total = castTotal,
			cast_window = castWindow,
			posture = posture,
			posture_max = DuelBossFrameUtil and DuelBossFrameUtil.THRESHOLD or 100,
			stagger = stagger,
		})

		return 0.1
	end)
end

function DuelBossHUD:Stop()
	if not IsServer() then return end
	self._stop = true
	self._boss = nil
	CustomNetTables:SetTableValue("duel_boss_hud", "state", { active = 0 })
end
