require('lib/ability_kv')

-- способность: интринзик-пассивка (аура на врагов)
stegius_brightness_of_desolate = class({})

function stegius_brightness_of_desolate:GetIntrinsicModifierName()
	return "modifier_stegius_brightness_of_desolate"
end

-- ХОЛДЕР: ручной скан врагов в радиусе каждые 0.5с + навешивание ПРЯМОГО дебаффа.
-- ПОЧЕМУ НЕ IsAura: MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS от аура-ребёнка движком
-- не применялся (проверено в игре 2026-08-09), а AbilityKV:Get(self:GetAbility(), ...)
-- в проперти-методе возвращал 0 (GetAbility/GetAbilityKeyValues ненадёжны в этом
-- контексте). Броня через СТЕКИ (паттерн modifier_stegius_desolating_touch_debuff —
-- доказанно работает): дебафф возвращает -GetStackCount(), холдер ставит стаки.
modifier_stegius_brightness_of_desolate = modifier_stegius_brightness_of_desolate or class({})

function modifier_stegius_brightness_of_desolate:IsHidden() return true end
function modifier_stegius_brightness_of_desolate:IsPurgable() return false end

function modifier_stegius_brightness_of_desolate:OnCreated()
	self:OnRefresh()
	self:StartIntervalThink(0.5)
end

function modifier_stegius_brightness_of_desolate:OnRefresh()
	local ability = self:GetAbility()
	if not ability or not IsValidEntity(ability) then return end

	self.radius = AbilityKV:Get(ability, "radius")
	self.armor_decrease = AbilityKV:Get(ability, "armor_decrease")
	self.health_decrease_pct = AbilityKV:Get(ability, "health_decrease_pct")

	if not self.radius or self.radius <= 0 then self.radius = 700 end
	if not self.armor_decrease then self.armor_decrease = 0 end
	if not self.health_decrease_pct then self.health_decrease_pct = 0 end

	local t = GameRules:GetGameTime()
	if not modifier_stegius_brightness_of_desolate.lastPrint or t - modifier_stegius_brightness_of_desolate.lastPrint > 10 then
		modifier_stegius_brightness_of_desolate.lastPrint = t
		print("[STEGIUS] brightness holder created, ability=" .. tostring(ability) .. " armor=" .. tostring(self.armor_decrease) .. " pct=" .. tostring(self.health_decrease_pct) .. " radius=" .. tostring(self.radius))
	end
end

function modifier_stegius_brightness_of_desolate:OnIntervalThink()
	if not IsServer() then return end
	local parent = self:GetParent()
	if not parent or parent:IsNull() or not parent:IsAlive() then return end
	local ability = self:GetAbility()
	if not ability or not IsValidEntity(ability) then return end

	local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil,
		self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	local t = GameRules:GetGameTime()
	if not modifier_stegius_brightness_of_desolate.lastScanPrint or t - modifier_stegius_brightness_of_desolate.lastScanPrint > 10 then
		modifier_stegius_brightness_of_desolate.lastScanPrint = t
		print("[STEGIUS] brightness scan: enemies_in_radius=" .. tostring(#enemies) .. " owner=" .. tostring(parent:GetUnitName()) .. " ill=" .. tostring(parent:IsIllusion()))
	end

	-- стаки брони: |armor_decrease| (2/4/6) — дебафф возвращает -GetStackCount().
	-- Талант "+2 брони" читается ЗДЕСЬ (свежий HasTalent каждый тик 0.5с),
	-- а не в OnRefresh — иначе эффект устаревал после взятия таланта без прокачки ауры
	local armor_stacks = math.abs(self.armor_decrease)
	if parent:HasTalent("stegius_special_bonus_brightness_armor") then
		armor_stacks = armor_stacks + 2
	end

	for _, enemy in pairs(enemies) do
		if IsValidEntity(enemy) and enemy:IsAlive() then
			local mod = enemy:FindModifierByName("modifier_stegius_brightness_of_desolate_effect")
			if not mod then
				mod = enemy:AddNewModifier(parent, ability, "modifier_stegius_brightness_of_desolate_effect", {duration = 1.2})
			end
			if mod then
				mod:SetDuration(1.2, true)
				enemy:SetModifierStackCount("modifier_stegius_brightness_of_desolate_effect", nil, armor_stacks)
			end
		end
	end
end

-- ПРЯМОЙ дебафф на враге (не аура-ребёнок): -броня (стеки), HP-пенальти, бонус за убийство.
modifier_stegius_brightness_of_desolate_effect = modifier_stegius_brightness_of_desolate_effect or class({})

function modifier_stegius_brightness_of_desolate_effect:IsDebuff() return true end
function modifier_stegius_brightness_of_desolate_effect:IsPurgable() return false end

function modifier_stegius_brightness_of_desolate_effect:OnCreated()
	-- pct кэшируется здесь: GetAbility() в OnCreated валиден (дебафф создаётся
	-- AddNewModifier с ability). Дебафф пересоздаётся каждые 1.2с — значение свежее.
	self.health_decrease_pct = 0
	local ability = self:GetAbility()
	if ability and IsValidEntity(ability) then
		local pct = AbilityKV:Get(ability, "health_decrease_pct")
		if pct then self.health_decrease_pct = pct end
	end
	self:StartIntervalThink(0.5)
end

function modifier_stegius_brightness_of_desolate_effect:OnIntervalThink()
	local parent = self:GetParent()
	if not parent or parent:IsNull() then return end
	local t = GameRules:GetGameTime()
	if not modifier_stegius_brightness_of_desolate_effect.lastPrint or t - modifier_stegius_brightness_of_desolate_effect.lastPrint > 10 then
		modifier_stegius_brightness_of_desolate_effect.lastPrint = t
		local cur = 0
		if parent.GetPhysicalArmorValue then cur = parent:GetPhysicalArmorValue(false) end
		print("[STEGIUS] aura effect armor=" .. tostring(self:GetStackCount()) .. " pct=" .. tostring(self.health_decrease_pct) .. " on " .. tostring(parent:GetUnitName()) .. " currentArmor=" .. tostring(cur))
	end
	if parent:IsHero() then
		local ok, err = pcall(function() parent:CalculateHealthReduction() end)
		if not ok then
			if not modifier_stegius_brightness_of_desolate_effect.lastErrPrint or t - modifier_stegius_brightness_of_desolate_effect.lastErrPrint > 5 then
				modifier_stegius_brightness_of_desolate_effect.lastErrPrint = t
				print("[STEGIUS] CHR error: " .. tostring(err) .. " | pct=" .. tostring(self.health_decrease_pct) .. " target=" .. tostring(parent:GetUnitName()))
			end
		end
	end
end

function modifier_stegius_brightness_of_desolate_effect:OnDestroy()
	local parent = self:GetParent()
	if parent and parent:IsHero() then
		parent:CalculateStatBonus(true)
	end
end

function modifier_stegius_brightness_of_desolate_effect:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_EVENT_ON_DEATH }
end

function modifier_stegius_brightness_of_desolate_effect:GetModifierPhysicalArmorBonus()
	return -self:GetStackCount()
end

function modifier_stegius_brightness_of_desolate_effect:OnDeath(params)
	if params.unit ~= self:GetParent() then return end
	IncreaseDamage({ caster = self:GetCaster(), unit = params.unit, ability = self:GetAbility() })
end

-- бонус к урону атаки: +1 за стак (стаки = величина бонуса)
modifier_stegius_brightness_of_desolate_damage = modifier_stegius_brightness_of_desolate_damage or class({})

function modifier_stegius_brightness_of_desolate_damage:IsPurgable() return false end

function modifier_stegius_brightness_of_desolate_damage:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_stegius_brightness_of_desolate_damage:GetModifierPreAttack_BonusDamage()
	return self:GetStackCount()
end

-- постоянная кража статов: AS/броня за стак
modifier_stegius_brightness_of_desolate_steal_buff = modifier_stegius_brightness_of_desolate_steal_buff or class({})

function modifier_stegius_brightness_of_desolate_steal_buff:IsPurgable() return false end

function modifier_stegius_brightness_of_desolate_steal_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_stegius_brightness_of_desolate_steal_buff:GetModifierAttackSpeedBonus_Constant()
	local ability = self:GetAbility()
	if not ability or not IsValidEntity(ability) then return 0 end
	return self:GetStackCount() * AbilityKV:Get(ability, "stolen_attack_speed")
end

function modifier_stegius_brightness_of_desolate_steal_buff:GetModifierPhysicalArmorBonus()
	local ability = self:GetAbility()
	if not ability or not IsValidEntity(ability) then return 0 end
	return self:GetStackCount() * AbilityKV:Get(ability, "stolen_armor")
end

function IncreaseDamage(keys)
	local caster = keys.caster
	local target = keys.unit
	local ability = keys.ability
	local damage
	if target:IsRealHero() then
		local steal = caster:FindModifierByNameAndCaster("modifier_stegius_brightness_of_desolate_steal_buff", caster)
		if steal then
			steal:SetStackCount(steal:GetStackCount() + 1)
		else
			caster:AddNewModifier(caster, ability, "modifier_stegius_brightness_of_desolate_steal_buff", {stacks = 1})
		end
		damage = AbilityKV:Get(ability, "bonus_damage_from_hero")
	else
		damage = AbilityKV:Get(ability, "bonus_damage_from_creep")
		if caster:HasTalent("stegius_special_bonus_brightness_creep_damage") then
			damage = damage * 2
		end
	end
	if damage <= 0 then damage = 1 end
	local bonus_duration = AbilityKV:Get(ability, "bonus_damage_duration")
	if bonus_duration <= 0 then bonus_duration = 20 end

	local modifier = caster:FindModifierByNameAndCaster("modifier_stegius_brightness_of_desolate_damage", caster)
	if modifier then
		modifier:SetStackCount(modifier:GetStackCount() + damage)
	else
		caster:AddNewModifier(caster, ability, "modifier_stegius_brightness_of_desolate_damage", {stacks = damage})
	end

	Timers:CreateTimer(bonus_duration, function()
		if IsValidEntity(caster) then
			local m = caster:FindModifierByNameAndCaster("modifier_stegius_brightness_of_desolate_damage", caster)
			if m then
				if m:GetStackCount() > damage then
					m:SetStackCount(m:GetStackCount() - damage)
				else
					caster:RemoveModifierByName("modifier_stegius_brightness_of_desolate_damage")
				end
			end
		end
	end)
end
