modifier_soul_guardian_heavy_strike = modifier_soul_guardian_heavy_strike or class({})
local mod = modifier_soul_guardian_heavy_strike

require('lib/ability_kv')
require('creeps/boss/soul_guardian/soul_guardian_helpers')

local STRIKE_PARTICLE = "particles/bosses/soul_guardian/soul_guardian_heavy_strike/econ/items/ursa/ursa_ti10/soul_guardian_heavy_strike.vpcf"

function mod:IsHidden()         return true  end
function mod:DestroyOnExpire()  return false end
function mod:IsPurgable()       return false end
function mod:IsPurgeException() return false end
mod.OnRefresh = mod.OnCreated

function mod:OnCreated()
	local ability = self:GetAbility()
	if not ability then return end
    self.duration_slow = AbilityKV:Get(ability, "duration_slow")
    self.duration_stun = AbilityKV:Get(ability, "duration_stun")
    self.knockback_radius_search = AbilityKV:Get(ability, "knockback_radius_search")
    self.knockback_radius = AbilityKV:Get(ability, "knockback_radius")
    self.knockback_duration = AbilityKV:Get(ability, "knockback_duration")
    self.strike_damage_pct = AbilityKV:Get(ability, "strike_damage_pct")

	-- страховки
	if not self.duration_slow or self.duration_slow <= 0 then self.duration_slow = 6 end
	if not self.duration_stun or self.duration_stun <= 0 then self.duration_stun = 2.0 end
	if not self.knockback_radius_search or self.knockback_radius_search <= 0 then self.knockback_radius_search = 450 end
	if not self.knockback_radius or self.knockback_radius <= 0 then self.knockback_radius = 700 end
	if not self.knockback_duration or self.knockback_duration <= 0 then self.knockback_duration = 0.3 end
	if not self.strike_damage_pct or self.strike_damage_pct <= 0 then self.strike_damage_pct = 30 end
end

function mod:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ATTACK_LANDED, }
end

function mod:OnAttackLanded(params)
    if not IsServer() then return end
    local caster = self:GetParent()
    if params.attacker ~= caster or caster:PassivesDisabled() then return end
	local ability = self:GetAbility()
	if ability:GetCooldownTimeRemaining() > 0 then return end

	ability:StartCooldown(ability:GetCooldown(ability:GetLevel() - 1))

	-- урон удара: % от виртуального урона атаки (AAF-модель);
	-- PURE под Holy Rage, иначе PHYSICAL
	if not caster:HasModifier("modifier_soul_guardian_holy_rage") then
		local damage = SoulGuardianHelpers:GetAttackDamage() * self.strike_damage_pct / 100
		ApplyDamage({
			victim = params.target,
			attacker = caster,
			damage = damage,
			damage_type = DAMAGE_TYPE_PHYSICAL,
			ability = ability,
		})
	else
		SoulGuardianHelpers:DealDamagePctOfAD(ability, caster, params.target, self.strike_damage_pct)
	end

	local particle = ParticleManager:CreateParticle(STRIKE_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, params.target)
	ParticleManager:SetParticleControlEnt(particle, 0, params.target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", params.target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(particle, 1, Vector(320, 155, 130))
	ParticleManager:ReleaseParticleIndex(particle)

    params.target:AddNewModifier(caster, ability, "modifier_soul_guardian_heavy_strike_stun", { duration = self.duration_stun })

	local allies = FindUnitsInRadius(
		params.target:GetTeamNumber(),
		params.target:GetOrigin(),
		params.target,
		self.knockback_radius_search,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false
	)
	local point = params.target:GetAbsOrigin()

	for _, unit in pairs(allies) do
		if unit ~= params.target and IsValidEntity(unit) and unit:IsAlive() then
			unit:AddNewModifier(caster, ability, "modifier_soul_guardian_heavy_strike_knockback", {
				radius = self.knockback_radius,
				duration = self.knockback_duration,
				dur = self.knockback_duration,
				point = tostring(point.x) .. " " .. tostring(point.y) .. " " .. tostring(point.z),
			})
			unit:AddNewModifier(caster, ability, "modifier_soul_guardian_heavy_strike_slow", { duration = self.duration_slow })
		end
	end
end
