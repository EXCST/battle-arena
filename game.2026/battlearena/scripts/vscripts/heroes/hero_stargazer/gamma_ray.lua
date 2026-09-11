-- ============================================================
-- STARGAZER — Gamma Ray (stargazer_gamma_ray, ability_lua)
-- Портировано из BS heroes/hero_stargazer/gamma_ray.lua.
-- ⚠️ 2026-08-12: BS-версия была datadriven RunScript Target POINT —
-- этот паттерн в проекте НИГДЕ не используется (rg по abilities:
-- все RunScript — NO_TARGET), каст молча не доходил. Переведено на
-- ability_lua (паттерн inverse_field/cosmic_countdown).
-- Правки:
--   * GetLevelSpecialValueFor/GetAbilitySpecial → AbilityKV:Get
--   * dummy-юнит (npc_dummy_unit отсутствует в VPK) убран —
--     частица в точке через PATTACH_WORLDORIGIN
--   * талант: +30% инт→урон (stargazer_special_bonus_gamma_int)
-- ============================================================

require('lib/ability_kv')

stargazer_gamma_ray = class({})

-- ⚠️ xpcall-обёртка (2026-08-12): движковый хендлер скрывает текст ошибки
-- («error in error handling», debug=nil в этой сборке) — собственный
-- xpcall + print показывает реальную причину (паттерн pet_wolf_vampire).
function stargazer_gamma_ray:OnSpellStart()
	local ok, err = xpcall(function()
		self:DoCast()
	end, function(e)
		return tostring(e)
	end)
	if not ok then
		print("[STARGAZER] gamma_ray error: " .. tostring(err))
	end
end

function stargazer_gamma_ray:DoCast()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	if not point then return end

	print("[STARGAZER] gamma_ray cast, lvl=" .. self:GetLevel())

	local base_damage = AbilityKV:Get(self, "base_damage")
	if not base_damage or base_damage <= 0 then base_damage = 100 end
	local int_to_dmg = AbilityKV:Get(self, "int_to_dmg_pct")
	if not int_to_dmg or int_to_dmg <= 0 then int_to_dmg = 50 end
	local base_radius = AbilityKV:Get(self, "base_radius")
	if not base_radius or base_radius <= 0 then base_radius = 150 end
	local int_to_radius = AbilityKV:Get(self, "int_to_radius_pct")
	if not int_to_radius or int_to_radius <= 0 then int_to_radius = 0 end
	local max_damage = AbilityKV:Get(self, "max_damage")
	if not max_damage or max_damage <= 0 then max_damage = 30000 end
	local max_radius = AbilityKV:Get(self, "max_radius")
	if not max_radius or max_radius <= 0 then max_radius = 800 end

	if caster:HasTalent("stargazer_special_bonus_gamma_int") then
		int_to_dmg = int_to_dmg + 30
	end

	local radius = math.min(base_radius + (caster:GetIntellect(true) * (int_to_radius * 0.01)), max_radius)
	local damage = math.min(base_damage + (caster:GetIntellect(true) * (int_to_dmg * 0.01)), max_damage)

	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	for _, enemy in ipairs(enemies) do
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			damage = damage,
			damage_type = self:GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
			ability = self
		})
	end

	caster:EmitSound("Arena.Hero_Stargazer.GammaRay.Cast")

	local particle = ParticleManager:CreateParticle(
		"particles/arena/units/heroes/hero_stargazer/gamma_ray_immortal1.vpcf",
		PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, point)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(particle)
end
