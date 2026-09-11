-- lib/duel_bosses/modifiers/modifier_duel_boss_phase.lua
-- Фазовый переход дуэльных боссов:
--   modifier_duel_boss_phase_window — окно неуязвимости при смене фазы
--       (INVULNERABLE + STUNNED + ROOTED + DISARMED + COMMAND_RESTRICTED + NO_HEALTH_BAR)
--   modifier_duel_boss_phase_buff — бафф второй фазы:
--       +10% исходящего урона, −10% входящего, +20% MS, +20 AS

modifier_duel_boss_phase_window = modifier_duel_boss_phase_window or class({})

function modifier_duel_boss_phase_window:IsHidden()         return false end
function modifier_duel_boss_phase_window:IsPurgable()       return false end
function modifier_duel_boss_phase_window:IsDebuff()          return false end
function modifier_duel_boss_phase_window:DestroyOnExpire()  return true  end

function modifier_duel_boss_phase_window:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE]           = true,
		[MODIFIER_STATE_STUNNED]                = true,
		[MODIFIER_STATE_ROOTED]                 = true,
		[MODIFIER_STATE_DISARMED]               = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED]     = true,
		[MODIFIER_STATE_NO_HEALTH_BAR]          = true,
	}
end


modifier_duel_boss_phase_buff = modifier_duel_boss_phase_buff or class({})

function modifier_duel_boss_phase_buff:IsHidden()         return true  end
function modifier_duel_boss_phase_buff:IsPurgable()       return false end
function modifier_duel_boss_phase_buff:IsDebuff()          return false end
function modifier_duel_boss_phase_buff:DestroyOnExpire()  return false end

function modifier_duel_boss_phase_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_duel_boss_phase_buff:GetModifierDamageOutgoing_Percentage()
	return 10
end

function modifier_duel_boss_phase_buff:GetModifierIncomingDamage_Percentage()
	return 90
end

function modifier_duel_boss_phase_buff:GetModifierMoveSpeedBonus_Percentage()
	return 20
end

function modifier_duel_boss_phase_buff:GetModifierAttackSpeedBonus_Constant()
	return 20
end