-- ============================================================
-- BATTLE ARENA — Travaler: Mana Burn (модификатор)
-- MODIFIER_EVENT_ON_ATTACK: при ударе босса жжёт ману цели,
-- наносит урон и показывает частицу + звук.
-- ============================================================

modifier_travaler_manaburn = modifier_travaler_manaburn or class({})

local mod = modifier_travaler_manaburn

require('lib/ability_kv')

local MANA_BURN_PARTICLE = "particles/econ/items/antimage/antimage_weapon_basher_ti5/am_basher_manaburn_impact_lightning.vpcf"
local MANA_BURN_FLASH = "particles/units/heroes/hero_oracle/oracle_false_promise_dmg.vpcf"


function mod:IsHidden() 		return true end
function mod:IsPurgable() 		return false end
function mod:IsDebuff() 		return false end


function mod:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end


function mod:OnAttackLanded(params)
	if not IsServer() then return end

	local parent = self:GetParent()

	if params.attacker ~= parent then return end

	local target = params.target

	if not IsValidEntity(target) or not target:IsAlive() then return end
	if target:GetMaxMana() <= 0 then return end

	local ability = self:GetAbility()

	local mana = AbilityKV:Get(ability, "mana_per_hit")
	local dmg = AbilityKV:Get(ability, "damage_per_burn")

	-- ReduceMana в этой сборке не работает — ставим ману напрямую
	local new_mana = math.max(0, target:GetMana() - mana)
	target:SetMana(new_mana)

	ApplyDamage({
		victim = target,
		attacker = parent,
		damage = dmg,
		damage_type = DAMAGE_TYPE_PHYSICAL,
		ability = ability,
	})

	-- дотовский визуал сжигания маны: молния + вспышка на цели
	local pos = target:GetAbsOrigin()

	local p = ParticleManager:CreateParticle(MANA_BURN_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(p, 0, pos)
	ParticleManager:ReleaseParticleIndex(p)

	local f = ParticleManager:CreateParticle(MANA_BURN_FLASH, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(f, 0, pos)
	ParticleManager:ReleaseParticleIndex(f)

	target:EmitSound("Boss_Travaler.Manaburn.Hit")
end
