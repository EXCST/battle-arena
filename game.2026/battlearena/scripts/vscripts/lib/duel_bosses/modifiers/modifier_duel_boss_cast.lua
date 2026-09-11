-- lib/duel_bosses/modifiers/modifier_duel_boss_cast.lua
-- Каст-контроллер дуэльных боссов (своя адаптация каст-фреймворка референса,
-- см. docs/boss_ai_reference.md §4):
--
--   modifier_duel_boss_cast_protection — время прекаста:
--     • дебафф-иммунитет + ROOTED + DISARMED (не сходит с места, нельзя оглушить «просто так»)
--     • входящий урон −80% всю стойку, КРОМЕ последних `window` секунд —
--       «окно контр-брейка»: удар героем в окне = стан-замирание 1.2с + постура +15
--       + снятие защиты (дальше движок сам прервёт каст → OnPhaseInterrupted → КД).
--     • поля _total/_window читает HUD-тик (кастбар с красной зоной).
--
--   modifier_duel_boss_busy — «босс занят» на время канала: команды заблокированы,
--     AI пропускает тики (HasModifier).

modifier_duel_boss_cast_protection = modifier_duel_boss_cast_protection or class({})

function modifier_duel_boss_cast_protection:IsHidden()        return true  end
function modifier_duel_boss_cast_protection:IsPurgable()      return false end
function modifier_duel_boss_cast_protection:IsDebuff()         return false end
function modifier_duel_boss_cast_protection:DestroyOnExpire() return true  end

function modifier_duel_boss_cast_protection:CheckState()
	return {
		[MODIFIER_STATE_DEBUFF_IMMUNE] = true,
		[MODIFIER_STATE_ROOTED]        = true,
		[MODIFIER_STATE_DISARMED]      = true,
	}
end

function modifier_duel_boss_cast_protection:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKE_DAMAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function modifier_duel_boss_cast_protection:OnCreated(params)
	if not IsServer() then return end

	self._total  = (params and params.duration) or 0
	self._window = (params and params.window) or 0
	self._breakAt = GameRules:GetGameTime() + math.max(0, self._total - self._window)
	self._broken = false
end

function modifier_duel_boss_cast_protection:GetModifierIncomingDamage_Percentage()
	if IsServer() and self._window > 0 and not self._broken
		and GameRules:GetGameTime() >= self._breakAt then
		-- в окне: только −45% (наказуемо)
		return 55
	end
	-- вне окна: −80%
	return 20
end

function modifier_duel_boss_cast_protection:OnTakeDamage(params)
	if not IsServer() then return end
	if self._broken or self._window <= 0 then return end

	local parent = self:GetParent()
	-- ⚠️ ON_TAKE_DAMAGE в этой сборке передаёт params.unit (не params.victim)
	if params.unit ~= parent then return end

	local dmg = params.damage or 0
	if dmg <= 0 then return end

	if GameRules:GetGameTime() < self._breakAt then return end

	-- удар в окно от ЛЮБОГО источника = контр-брейк (как у китайцев: менеджер ловит любой урон)
	self._broken = true
	parent.duel_counter_break_at = GameRules:GetGameTime()

	require('lib/duel_bosses/modifiers/modifier_duel_boss_frame')
	DuelBossFrameUtil:CounterStagger(parent, self:GetAbility())
	DuelBossFrameUtil:AddPosture(parent, DuelBossFrameUtil.COUNTER_BONUS)

	parent:EmitSound("Hero_Spirit_Breaker.GreaterBash")

	self:Destroy()
end


modifier_duel_boss_busy = modifier_duel_boss_busy or class({})

function modifier_duel_boss_busy:IsHidden()         return true  end
function modifier_duel_boss_busy:IsPurgable()       return false end
function modifier_duel_boss_busy:IsDebuff()          return false end
function modifier_duel_boss_busy:DestroyOnExpire()  return true  end

function modifier_duel_boss_busy:CheckState()
	return {
		[MODIFIER_STATE_COMMAND_RESTRICTED]        = true,
		[MODIFIER_STATE_DISARMED]                  = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION]         = true,
		[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
	}
end
