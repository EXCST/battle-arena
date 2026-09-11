-- ============================================================
-- BATTLE ARENA — Travaler: фазовый контроллер
-- 3 сегмента HP: фаза 2 на <66%, фаза 3 на <33%.
-- При переходе: кламп HP на вершину сегмента, пурж дебаффов,
-- окно полной неуязвимости, FX. Фаза пишется в unit.travaler_phase
-- (читается правилами AI).
-- ============================================================

modifier_travaler_phases = modifier_travaler_phases or class({})

local mod = modifier_travaler_phases

local PHASE_2_AT = 0.66
local PHASE_3_AT = 0.33
local PHASE_INVULN_DURATION = 1.5


function mod:OnCreated()
	if not IsServer() then return end

	local unit = self:GetParent()

	self.phase = 1
	unit.travaler_phase = 1

	self:StartIntervalThink(0.5)
end


function mod:OnIntervalThink()
	local unit = self:GetParent()

	if not IsValidEntity(unit) or not unit:IsAlive() then return end
	if unit:HasModifier("modifier_travaler_phase_invuln") then return end

	self:CheckPhase()
end


function mod:IsHidden() 	return true end
function mod:IsPurgable() 	return false end


function mod:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKE_DAMAGE,
	}
end


function mod:OnTakeDamage(params)
	local unit = self:GetParent()

	if params.unit ~= unit then return end
	if not unit:IsAlive() then return end
	if unit:HasModifier("modifier_travaler_phase_invuln") then return end

	self:CheckPhase()
end


function mod:CheckPhase()
	local unit = self:GetParent()

	if not IsValidEntity(unit) or not unit:IsAlive() then return end

	local pct = unit:GetHealth() / unit:GetMaxHealth()

	if self.phase == 1 and pct < PHASE_2_AT then
		self:EnterPhase(2, PHASE_2_AT)
	elseif self.phase == 2 and pct < PHASE_3_AT then
		self:EnterPhase(3, PHASE_3_AT)
	end
end


function mod:EnterPhase(phase, segment_top)
	local unit = self:GetParent()

	self.phase = phase
	unit.travaler_phase = phase

	-- кламп на вершину сегмента (босс "восстанавливает" полосу)
	local max_hp = unit:GetMaxHealth()

	if unit:GetHealth() < max_hp * segment_top then
		unit:SetHealth(max_hp * segment_top)
	end

	-- пурж негативных эффектов с босса
	unit:Purge(false, true, false, true, false)

	-- окно неуязвимости
	unit:AddNewModifier(unit, nil, "modifier_travaler_phase_invuln", { duration = PHASE_INVULN_DURATION })

	-- FX: кольцо вокруг босса (loop-частица — гасим через 2с, иначе висит вечно)
	local p = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_doom_ring.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(p, 0, unit:GetAbsOrigin())
	ParticleManager:SetParticleControl(p, 1, Vector(500, 0, 0))

	Timers:CreateTimer(2.0, function()
		local ok, err = pcall(function()
			ParticleManager:DestroyParticle(p, true)
			ParticleManager:ReleaseParticleIndex(p)
		end)

		if not ok then print("[Travaler] phase fx error: " .. tostring(err)) end
	end)

	unit:EmitSound("Boss_Travaler.Phase.Shift")
end
