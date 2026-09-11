-- lib/duel_bosses/modifiers/modifier_duel_boss_stagger.lua
-- «Стан-замирание» дуэльных боссов, ОБХОДЯЩИЙ debuff-иммунитет (IsDebuff = false —
-- движок не блокирует такие модификаторы состоянием DEBUFF_IMMUNE).
-- Паттерн референса: modifier_monster_cast_stun / thunderized-контр.
--
-- Параметры AddNewModifier:
--   duration  — базовая длительность
--   big = 1   — «слом» постуры: длинный стан, урон СОКРАЩАЕТ его (−1с за 5% макс.HP),
--               FX-разлом + тряска; короткий «контр-стан» — big=0, фиксированный.

modifier_duel_boss_stagger = modifier_duel_boss_stagger or class({})

local STAGGER_TICK = 0.05
local DMG_PCT_PER_SECOND_SAVED = 5 -- 5% макс.HP = −1 секунда стаггера (big)

function modifier_duel_boss_stagger:IsHidden()        return true  end
function modifier_duel_boss_stagger:IsPurgable()      return false end
function modifier_duel_boss_stagger:IsDebuff()         return false end
function modifier_duel_boss_stagger:RemoveOnDeath()   return true  end
function modifier_duel_boss_stagger:DestroyOnExpire() return true  end

function modifier_duel_boss_stagger:CheckState()
	return {
		[MODIFIER_STATE_STUNNED]            = true,
		[MODIFIER_STATE_ROOTED]             = true,
		[MODIFIER_STATE_DISARMED]           = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

function modifier_duel_boss_stagger:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKE_DAMAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function modifier_duel_boss_stagger:GetModifierIncomingDamage_Percentage()
	-- «сломанный» босс получает +20% урона в окно наказания
	return 120
end

function modifier_duel_boss_stagger:OnCreated(params)
	if not IsServer() then return end

	local parent = self:GetParent()
	self._big = (params and params.big == 1) or false
	self._end = GameRules:GetGameTime() + self:GetDuration()

	parent:InterruptMotionControllers(true)
	parent:Stop()

	local fx = ParticleManager:CreateParticle("particles/generic_stunned.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
	self:AddParticle(fx, false, false, -1, false, false)

	if self._big then
		local p = ParticleManager:CreateParticle("particles/units/heroes/hero_leshrac/leshrac_split_earth.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(p, 0, parent:GetAbsOrigin())
		ParticleManager:SetParticleControl(p, 1, Vector(400, 400, 400))
		ParticleManager:ReleaseParticleIndex(p)
		parent:EmitSound("DuelBoss.Broken")
		ScreenShake(parent:GetAbsOrigin(), 12, 12, 0.35, 1600, 0, true)
	else
		ScreenShake(parent:GetAbsOrigin(), 3, 3, 0.15, 900, 0, true)
	end

	self:StartIntervalThink(STAGGER_TICK)
end

function modifier_duel_boss_stagger:OnTakeDamage(params)
	if not IsServer() then return end
	if not self._big then return end

	local parent = self:GetParent()
	-- ⚠️ ON_TAKE_DAMAGE в этой сборке передаёт params.unit (не params.victim)
	if params.unit ~= parent then return end

	local dmg = params.damage or 0
	if dmg <= 0 then return end

	-- любой урон сокращает «слом» (консистентно с постура-метром)
	local maxHp = math.max(1, parent:GetMaxHealth())
	local pct = dmg / maxHp * 100
	local newEnd = self._end - (pct / DMG_PCT_PER_SECOND_SAVED)

	-- не короче 0.2с с текущего момента
	self._end = math.max(newEnd, GameRules:GetGameTime() + 0.2)
end

function modifier_duel_boss_stagger:OnIntervalThink()
	if not IsServer() then return end
	if GameRules:GetGameTime() >= self._end then
		self:Destroy()
	end
end

function modifier_duel_boss_stagger:OnDestroy()
	if not IsServer() then return end
	local parent = self:GetParent()
	if IsValidEntity(parent) and parent:IsAlive() and self._big then
		parent:EmitSound("Hero_Tidehunter.KravMaga")
	end
end
