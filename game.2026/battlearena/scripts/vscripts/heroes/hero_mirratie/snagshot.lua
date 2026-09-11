-- ============================================================
-- MIRRATIE — Snagshot (mirratie_snagshot, ability_lua)
-- Портировано из BS (там была нативная база meepo_earthbind).
-- ⚠️ 2026-08-13: нативная база не работала; CreateLinearProjectile
-- рендерил снаряд плохо, а частица meepo_earthbind_main (loop)
-- не уничтожалась (утечка). Полёт переделан на ручной
-- модификатор-тикер (паттерн smoke_out cloud): частица снаряда
-- двигается по CP0 к точке, сетка в точке приземления создаётся
-- и уничтожается по истечении рута. Все частицы DestroyParticle
-- (страховка от утечки в OnDestroy).
-- ⚠️ Частицы вижена НЕ дают (вижен — только через вижн-ноды,
-- мы их не создаём): сетка видима при имеющемся вижене.
-- ============================================================

require('lib/ability_kv')

mirratie_snagshot = class({})

function mirratie_snagshot:OnSpellStart()
	local ok, err = xpcall(function()
		self:DoCast()
	end, function(e)
		return tostring(e)
	end)
	if not ok then
		print("[MIRRATIE] snagshot error: " .. tostring(err))
	end
end

function mirratie_snagshot:DoCast()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	if not point then return end

	local origin = caster:GetAbsOrigin()
	local distance = (point - origin):Length2D()
	if distance < 1 then return end

	local speed = AbilityKV:Get(self, "speed")
	if not speed or speed <= 0 then speed = 857 end

	local flight_time = distance / speed
	local root_duration = AbilityKV:Get(self, "duration")
	if not root_duration or root_duration <= 0 then root_duration = 2.0 end

	print("[MIRRATIE] snagshot cast, lvl=" .. self:GetLevel() ..
		" dist=" .. math.floor(distance) ..
		" ft=" .. string.format("%.2f", flight_time))

	caster:AddNewModifier(caster, self, "modifier_mirratie_snagshot_flight", {
		duration = flight_time + root_duration + 0.5,
		origin_x = origin.x, origin_y = origin.y, origin_z = origin.z,
		target_x = point.x, target_y = point.y, target_z = point.z,
		flight_time = flight_time,
	})
end

modifier_mirratie_snagshot_flight = class({})

function modifier_mirratie_snagshot_flight:IsHidden() return true end
function modifier_mirratie_snagshot_flight:IsPurgable() return false end

function modifier_mirratie_snagshot_flight:OnCreated(kv)
	if not IsServer() then return end

	self.origin = Vector(kv.origin_x, kv.origin_y, kv.origin_z)
	self.target = Vector(kv.target_x, kv.target_y, kv.target_z)
	self.flight_time = kv.flight_time or 1.0
	self.elapsed = 0
	self.landed = false
	self.pfx = nil
	self.land_pfx = nil

	-- снаряд: частица-сетка в полёте (рендер по CP0, чисто визуальная)
	self.pfx = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_meepo/meepo_earthbind_projectile_fx.vpcf",
		PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(self.pfx, 0, self.origin)

	-- ⚠️ StartIntervalThink вместо GetIntervalThinkTime: в этой сборке
	-- GetIntervalThinkTime не запускает тики (проверено 2026-08-13)
	self:StartIntervalThink(0.05)
end

function modifier_mirratie_snagshot_flight:OnIntervalThink()
	if not IsServer() then return end

	self.elapsed = self.elapsed + 0.05

	if not self.landed then
		local t = self.elapsed / self.flight_time
		if t >= 1 then
			self.landed = true
			self:ApplySnag()
		else
			local pos = self.origin + (self.target - self.origin) * t
			ParticleManager:SetParticleControl(self.pfx, 0, pos)
		end
		return
	end

	-- после приземления: тики только для своевременного уничтожения сетки
	local root_duration = AbilityKV:Get(self:GetAbility(), "duration")
	if not root_duration or root_duration <= 0 then root_duration = 2.0 end

	if self.elapsed >= self.flight_time + root_duration then
		self:Destroy()
	end
end

function modifier_mirratie_snagshot_flight:ApplySnag()
	local caster = self:GetParent()
	local ability = self:GetAbility()

	if self.pfx then
		ParticleManager:DestroyParticle(self.pfx, true)
		ParticleManager:ReleaseParticleIndex(self.pfx)
		self.pfx = nil
	end

	if not IsValidEntity(caster) or not caster:IsAlive() then
		return
	end

	local radius = AbilityKV:Get(ability, "radius")
	if not radius or radius <= 0 then radius = 180 end
	local root_duration = AbilityKV:Get(ability, "duration")
	if not root_duration or root_duration <= 0 then root_duration = 2.0 end

	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), self.target, nil, radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	for _, enemy in ipairs(enemies) do
		if not enemy:IsMagicImmune() then
			enemy:AddNewModifier(caster, ability, "modifier_meepo_earthbind", { duration = root_duration })
		end
	end

	-- сетка на земле в точке приземления (видима, вижена не даёт);
	-- уничтожается в OnIntervalThink по истечении рута
	self.land_pfx = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_meepo/meepo_earthbind_main.vpcf",
		PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.land_pfx, 0, self.target)
	ParticleManager:SetParticleControl(self.land_pfx, 1, Vector(radius, radius, radius))
end

function modifier_mirratie_snagshot_flight:OnDestroy()
	if not IsServer() then return end
	if self.pfx then
		ParticleManager:DestroyParticle(self.pfx, true)
		ParticleManager:ReleaseParticleIndex(self.pfx)
		self.pfx = nil
	end
	if self.land_pfx then
		ParticleManager:DestroyParticle(self.land_pfx, true)
		ParticleManager:ReleaseParticleIndex(self.land_pfx)
		self.land_pfx = nil
	end
end
