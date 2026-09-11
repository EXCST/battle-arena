-- ============================================================
-- MIRRATIE — Smoke Out (mirratie_smoke_out, ability_lua)
-- Портировано из BS heroes/hero_mirratie/smoke_out.lua.
-- ⚠️ BS-версия была datadriven RunScript Target POINT — этот
-- паттерн в сборке не работает (см. stargazer gamma_ray).
-- Переведено на ability_lua. Облако — модификатор-тикер на
-- кастере с фиксированной точкой старта (паттерн ручного
-- скана stegius brightness; thinker-юниты не используются).
-- ⚠️ require('lib/timers') не используется: клиентская VM
-- падает на Timers:start() (грабли проекта).
-- ============================================================

require('lib/ability_kv')

mirratie_smoke_out = class({})

function mirratie_smoke_out:OnSpellStart()
	local ok, err = xpcall(function()
		self:DoCast()
	end, function(e)
		return tostring(e)
	end)
	if not ok then
		print("[MIRRATIE] smoke_out error: " .. tostring(err))
	end
end

function mirratie_smoke_out:DoCast()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	if not point then return end

	print("[MIRRATIE] smoke_out cast, lvl=" .. self:GetLevel())

	local origin = caster:GetAbsOrigin()
	local duration = AbilityKV:Get(self, "duration")
	if not duration or duration <= 0 then duration = 6 end

	ProjectileManager:ProjectileDodge(caster)
	ParticleManager:CreateParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, caster)

	-- облако остаётся в точке старта (как в BS: ApplyDataDrivenThinker на caster:GetAbsOrigin() до телепорта)
	caster:AddNewModifier(caster, self, "modifier_mirratie_smoke_out_cloud", { duration = duration })
	-- ⚠️ CreateVisibilityNode — метод СПОСОБНОСТИ (у юнита nil; проверено 2026-08-13)
	self:CreateVisibilityNode(origin, 10, duration)

	FindClearSpaceForUnit(caster, point, true)
	ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, caster)
end

modifier_mirratie_smoke_out_cloud = class({})

function modifier_mirratie_smoke_out_cloud:IsHidden() return true end
function modifier_mirratie_smoke_out_cloud:IsPurgable() return false end

function modifier_mirratie_smoke_out_cloud:OnCreated()
	if not IsServer() then return end

	local ok, err = xpcall(function()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		self.point = parent:GetAbsOrigin()
		self.radius = AbilityKV:Get(ability, "radius")
		if not self.radius or self.radius <= 0 then self.radius = 275 end

		parent:EmitSound("Hero_Riki.Smoke_Screen")

		-- ⚠️ StartIntervalThink вместо GetIntervalThinkTime: в этой сборке
		-- GetIntervalThinkTime не запускает тики (проверено 2026-08-13)
		self:StartIntervalThink(0.25)

		self.pfx = ParticleManager:CreateParticle(
			"particles/arena/units/heroes/hero_mirratie/smoke_out_bomb.vpcf",
			PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(self.pfx, 0, self.point)
		ParticleManager:SetParticleControl(self.pfx, 1, Vector(self.radius, self.radius, self.radius))
	end, function(e)
		return tostring(e)
	end)
	if not ok then
		print("[MIRRATIE] smoke_out cloud OnCreated error: " .. tostring(err))
	end
end

function modifier_mirratie_smoke_out_cloud:OnIntervalThink()
	if not IsServer() then return end
	if not self.point then return end

	local parent = self:GetParent()
	local ability = self:GetAbility()
	local debuff_duration = 0.5

	local enemies = FindUnitsInRadius(parent:GetTeamNumber(), self.point, nil, self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	for _, enemy in ipairs(enemies) do
		enemy:AddNewModifier(parent, ability, "modifier_mirratie_smoke_out_debuff", { duration = debuff_duration })
	end
end

function modifier_mirratie_smoke_out_cloud:OnDestroy()
	if not IsServer() then return end
	if self.pfx then
		ParticleManager:DestroyParticle(self.pfx, true)
		ParticleManager:ReleaseParticleIndex(self.pfx)
		self.pfx = nil
	end
end

modifier_mirratie_smoke_out_debuff = class({})

function modifier_mirratie_smoke_out_debuff:IsDebuff() return true end
function modifier_mirratie_smoke_out_debuff:IsPurgable() return true end

-- ⚠️ DeclareFunctions ОБЯЗАТЕЛЕН: в этой сборке движок не вызывает
-- проперти-методы без объявления (проверено 2026-08-13: модификатор
-- навешивался, но слоу/мисс не применялись — паттерн проекта
-- modifier_huntress_crippling_arrow_slow, 469 файлов с DeclareFunctions).
function modifier_mirratie_smoke_out_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MISS_PERCENTAGE,
	}
end

-- Кэш значений при создании/обновлении (пересоздаётся каждые 0.25с
-- облаком → значения всегда свежие; паттерн huntress_crippling_arrow_slow)
function modifier_mirratie_smoke_out_debuff:OnCreated(kv)
	self.slow_pct = 0
	self.miss_pct = 0
	self:RefreshValues()
end

function modifier_mirratie_smoke_out_debuff:OnRefresh(kv)
	self:RefreshValues()
end

function modifier_mirratie_smoke_out_debuff:RefreshValues()
	local ability = self:GetAbility()
	local slow = AbilityKV:Get(ability, "move_slow_pct")
	if not slow or slow >= 0 then slow = -10 end
	self.slow_pct = slow

	local miss = AbilityKV:Get(ability, "miss_chance_pct")
	if not miss or miss <= 0 then miss = 10 end
	self.miss_pct = miss
end

function modifier_mirratie_smoke_out_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow_pct
end

function modifier_mirratie_smoke_out_debuff:GetModifierMiss_Percentage()
	return self.miss_pct
end

function modifier_mirratie_smoke_out_debuff:CheckState()
	return {
		[MODIFIER_STATE_BLIND] = true,
	}
end
