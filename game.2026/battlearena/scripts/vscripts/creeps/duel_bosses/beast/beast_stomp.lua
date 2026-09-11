-- creeps/duel_bosses/beast/beast_stomp.lua
-- «Топот» — удар по земле: кольцо-теллур вокруг босса → урон %HP + стан + отброс.
-- Кастуется, когда враги близко (AI-правило с дистанцией).

require('lib/duel_bosses/boss_cast')
require('lib/duel_bosses/boss_warning')
require('lib/duel_bosses/boss_damage')
require('lib/duel_bosses/boss_motion')

local CAST_POINT = 0.6
local STOMP_RADIUS = 500
local WARNING_DURATION = 0.9
local DAMAGE_PCT = 12
local STUN_DURATION = 0.5
local KNOCKBACK_DISTANCE = 250
local KNOCKBACK_DURATION = 0.3

ba_duel_beast_stomp = ba_duel_beast_stomp or class({})

function ba_duel_beast_stomp:OnAbilityPhaseStart()
	DuelBossCast:OnPhaseStart(self, { castPoint = CAST_POINT })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return true end

	caster:EmitSound("Hero_PrimalBeast.Trample.Cast")
	DuelBossWarning:RedCircle(caster, self, caster:GetAbsOrigin(), STOMP_RADIUS, WARNING_DURATION)

	return true
end

function ba_duel_beast_stomp:OnAbilityPhaseInterrupted()
	DuelBossCast:OnPhaseInterrupted(self)
end

function ba_duel_beast_stomp:OnSpellStart()
	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	local center = caster:GetAbsOrigin()

	local victims = FindUnitsInRadius(
		caster:GetTeamNumber(),
		center,
		nil,
		STOMP_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		FIND_CLOSEST,
		false
	)

	for _, v in ipairs(victims) do
		if IsValidEntity(v) and v:IsAlive() and not v:IsCourier() then
			DuelBossDamage:Deal(self, caster, v, DAMAGE_PCT, 0)
			DuelBossDamage:Stun(v, caster, self, STUN_DURATION)
			DuelBossMotion:KnockBack(v, center, KNOCKBACK_DISTANCE, KNOCKBACK_DURATION, 60, 0, self)
		end
	end
end