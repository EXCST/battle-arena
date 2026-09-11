-- ============================================================
-- STARGAZER — Warp (stargazer_warp, ability_lua)
-- Портировано из BS heroes/hero_stargazer/warp.lua.
-- ⚠️ 2026-08-12: datadriven RunScript Target POINT не работает в этой
-- сборке (молчаливое "error in error handling", текст скрыт) — gamma_ray
-- кастуется только после перевода на ability_lua. Warp переведён тем же
-- способом.
-- Правки:
--   * GetLevelSpecialValueFor/GetAbilitySpecial → AbilityKV:Get
--   * dummy-юнит + pugna_ward_attack (нет в VPK) убраны — частица из
--     набора stargazer (gamma_ray_warp_blast) на кастере
--   * GetAgility(true) — в этой сборке атрибуты требуют аргумент
--   * талант: +500 дальность (stargazer_special_bonus_warp_range)
-- ============================================================

require('lib/ability_kv')

stargazer_warp = class({})

-- xpcall-обёртка (текст ошибки скрыт движковым хендлером, debug=nil)
function stargazer_warp:OnSpellStart()
	local ok, err = xpcall(function()
		self:DoCast()
	end, function(e)
		return tostring(e)
	end)
	if not ok then
		print("[STARGAZER] warp error: " .. tostring(err))
	end
end

function stargazer_warp:DoCast()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	if not point then return end

	local base_range = AbilityKV:Get(self, "base_range")
	if not base_range or base_range <= 0 then base_range = 500 end
	local agi_to_range = AbilityKV:Get(self, "agi_to_range_pct")
	if not agi_to_range or agi_to_range <= 0 then agi_to_range = 100 end
	local max_range = AbilityKV:Get(self, "max_range")
	if not max_range or max_range <= 0 then max_range = 3000 end

	-- ⚠️ GetAgility в этой сборке НЕ принимает аргумент (ожидает 0),
	-- в отличие от GetIntellect (ожидает 1) — проверено 2026-08-12.
	local blink_range = math.min(base_range + (caster:GetAgility() * (agi_to_range * 0.01)), max_range)

	if caster:HasTalent("stargazer_special_bonus_warp_range") then
		blink_range = math.min(blink_range + 500, 5000)
	end

	local origin = caster:GetAbsOrigin()
	local diff = point - origin
	if diff:Length2D() > blink_range then
		point = origin + diff:Normalized() * blink_range
	end

	caster:EmitSound("Hero_Pugna.NetherWard.Attack")

	local particle = ParticleManager:CreateParticle(
		"particles/arena/units/heroes/hero_stargazer/gamma_ray_warp_blast_immortal1.vpcf",
		PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(particle)

	FindClearSpaceForUnit(caster, point, true)
end
