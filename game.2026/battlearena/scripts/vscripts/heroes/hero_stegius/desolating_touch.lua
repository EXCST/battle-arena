require('lib/ability_kv')

-- способность: интринзик-пассивка (ON_ATTACK на любых целях, включая иллюзии)
stegius_desolating_touch = class({})

function stegius_desolating_touch:GetIntrinsicModifierName()
	return "modifier_stegius_desolating_touch"
end

-- пассивка-прок при ударе
modifier_stegius_desolating_touch = modifier_stegius_desolating_touch or class({})

function modifier_stegius_desolating_touch:IsHidden() return true end
function modifier_stegius_desolating_touch:IsPurgable() return false end

function modifier_stegius_desolating_touch:OnCreated()
	-- стат-таланты (урон/HP/КД/AS): единый модификатор, читающий HasTalent на лету.
	-- Движковый авто-аттач modifier_<талант> для кастомных имён не работает —
	-- навешиваем вручную один раз (гард от дублей: пассивка создаётся и на иллюзиях).
	local parent = self:GetParent()
	if parent and not parent:IsNull() and not parent:HasModifier("modifier_stegius_talent_stats") then
		parent:AddNewModifier(parent, self:GetAbility(), "modifier_stegius_talent_stats", {})
	end
	print("[STEGIUS] desolating passive created, ability=" .. tostring(self:GetAbility()))
end

function modifier_stegius_desolating_touch:DeclareFunctions()
	-- ON_ATTACK (выдача атаки) вместо ON_ATTACK_LANDED: движок не генерирует
	-- landed-событие для целей-иллюзий, из-за чего пассивка на них не прокалась
	return { MODIFIER_EVENT_ON_ATTACK }
end

function modifier_stegius_desolating_touch:OnAttack(params)
	if not IsServer() then return end
	local caster = self:GetParent()
	if params.attacker ~= caster or caster:PassivesDisabled() then return end
	local target = params.target
	if not target or target:IsNull() then return end
	-- атаки иллюзий героя ВСЕГДА засчитываются основному герою — единый дебафф на цели.
	-- Если источник не найден — НЕ применяем (иначе инстансы от разных кастеров
	-- конфликтуют: FindModifierByNameAndCaster не находит чужой инстанс,
	-- создаётся новый, стаки сбрасываются к ~0)
	local ability = self:GetAbility()
	if caster:IsIllusion() then
		-- GetIllusionSource принимает СУЩНОСТЬ (внутри вызывает illusion:GetUnitName()),
		-- а не имя-строку — передача строки роняла обработчик с Runtime Error
		local main_hero = GetIllusionSource(caster)
		if not main_hero or main_hero:IsNull() then return end
		caster = main_hero
		-- дебафф вешается способностью ОСНОВНОГО героя, чтобы инстанс был единым
		local hero_ability = main_hero:FindAbilityByName("stegius_desolating_touch")
		if hero_ability and IsValidEntity(hero_ability) then ability = hero_ability end
	end
	if not ability or not IsValidEntity(ability) then return end

	local stacks = AbilityKV:Get(ability, "armor_per_hit")
	if caster:HasTalent("stegius_special_bonus_touch_armor") then
		stacks = stacks + 1
	end
	if target:IsBoss() then
		local current = target:GetModifierStackCount("modifier_stegius_desolating_touch_debuff", ability)
		local boss_limit = AbilityKV:Get(ability, "boss_max_armor")
		if caster:HasTalent("stegius_special_bonus_touch_boss_limit") then
			boss_limit = boss_limit + 20
		end
		stacks = math.max(0, math.min(stacks, boss_limit - current))
	end
	if stacks <= 0 and not target:IsBoss() then stacks = 1 end
	if stacks <= 0 then return end
	local duration = AbilityKV:Get(ability, "duration")
	if duration <= 0 then duration = 8 end

	-- refresh-паттерн (как soul_guardian damage_steal): стаки накапливаются,
	-- длительность обновляется; ищем дебафф ПО ИМЕНИ (любой инстанс), стаки через
	-- unit:SetModifierStackCount (надёжно). Все применения идут от основного героя,
	-- поэтому инстанс всегда один
	local modifier = target:FindModifierByName("modifier_stegius_desolating_touch_debuff")
	if not modifier then
		modifier = target:AddNewModifier(caster, ability, "modifier_stegius_desolating_touch_debuff", {duration = duration})
	end
	modifier:SetDuration(duration, true)
	target:SetModifierStackCount("modifier_stegius_desolating_touch_debuff", nil, modifier:GetStackCount() + stacks)
	target:EmitSound("Item_Desolator.Target")
	if not modifier_stegius_desolating_touch.lastProcPrint or GameRules:GetGameTime() - modifier_stegius_desolating_touch.lastProcPrint > 5 then
		modifier_stegius_desolating_touch.lastProcPrint = GameRules:GetGameTime()
		local orig_attacker = self:GetParent()
		print("[STEGIUS] OnAttack orig=" .. tostring(orig_attacker:GetUnitName()) .. " origIll=" .. tostring(orig_attacker:IsIllusion()) .. " target=" .. tostring(target:GetUnitName()) .. " isIll=" .. tostring(target:IsIllusion()) .. " +" .. tostring(stacks) .. " total=" .. tostring(modifier:GetStackCount()) .. " lvl=" .. tostring(ability:GetLevel()))
	end
end

-- стек-дебафф: -1 броня за стак (lua-модификатор, масштабируется по стекам)
modifier_stegius_desolating_touch_debuff = modifier_stegius_desolating_touch_debuff or class({})

function modifier_stegius_desolating_touch_debuff:IsDebuff() return true end
function modifier_stegius_desolating_touch_debuff:IsPurgable() return false end

function modifier_stegius_desolating_touch_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_stegius_desolating_touch_debuff:GetModifierPhysicalArmorBonus()
	return -self:GetStackCount()
end

-- ============================================================
-- ЕДИНЫЙ модификатор стат-талантов (+40 урона / +300 HP / −20% КД / +50 AS).
-- Значения ЗАХАРДКОЖЕНЫ: чтение из KV таланта (GetAbilityKeyValues/AbilityKV)
-- для special_bonus_base ненадёжно, поэтому баланс продублирован здесь —
-- держать синхронно со stegius_talents.txt. Проверка — только HasTalent
-- (факт взятия; доказанно работает — touch_armor). Эффект применяется
-- сразу и не устаревает.
-- ============================================================
modifier_stegius_talent_stats = modifier_stegius_talent_stats or class({})

function modifier_stegius_talent_stats:IsHidden() return true end
function modifier_stegius_talent_stats:IsPurgable() return false end
function modifier_stegius_talent_stats:RemoveOnDeath() return false end

function modifier_stegius_talent_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_stegius_talent_stats:HasTalent(talent_name)
	local hero = self:GetParent()
	if not hero or hero:IsNull() then return false end
	return hero:HasTalent(talent_name)
end

function modifier_stegius_talent_stats:OnCreated()
	local hero = self:GetParent()
	print("[STALENT] stats modifier created on " .. tostring(hero and hero:GetUnitName() or "?") .. " ability=" .. tostring(self:GetAbility()))
end

function modifier_stegius_talent_stats:GetModifierPreAttack_BonusDamage()
	local v = 0
	if self:HasTalent("stegius_special_bonus_attack_damage") then v = 40 end
	self:Diag(v)
	return v
end

function modifier_stegius_talent_stats:GetModifierHealthBonus()
	if self:HasTalent("stegius_special_bonus_health") then return 300 end
	return 0
end

function modifier_stegius_talent_stats:GetModifierPercentageCooldown()
	-- ⚠️ В этой сборке знак COOLDOWN_PERCENTAGE инвертирован: ПОЛОЖИТЕЛЬНОЕ
	-- значение = снижение перезарядки (конвенция проекта: quickening_charm
	-- bonus_cooldown 10 = −10% КД, spell_prism 12, octarine_core_2 30).
	-- Возврат отрицательного значения УВЕЛИЧИВАЕТ перезарядку (проверено в игре 2026-08-10).
	if self:HasTalent("stegius_special_bonus_wave_cooldown") then return 20 end
	return 0
end

function modifier_stegius_talent_stats:GetModifierAttackSpeedBonus_Constant()
	if self:HasTalent("stegius_special_bonus_rage_attack_speed") then return 50 end
	return 0
end

function modifier_stegius_talent_stats:Diag(v)
	local t = GameRules:GetGameTime()
	if not modifier_stegius_talent_stats.lastDiag or t - modifier_stegius_talent_stats.lastDiag > 15 then
		modifier_stegius_talent_stats.lastDiag = t
		local hero = self:GetParent()
		local name = "?"
		if hero and not hero:IsNull() then name = hero:GetUnitName() end
		print("[STALENT] " .. tostring(name)
			.. " dmgGet=" .. tostring(v)
			.. " | dmg=" .. tostring(self:HasTalent("stegius_special_bonus_attack_damage"))
			.. " hp=" .. tostring(self:HasTalent("stegius_special_bonus_health"))
			.. " cd=" .. tostring(self:HasTalent("stegius_special_bonus_wave_cooldown"))
			.. " as=" .. tostring(self:HasTalent("stegius_special_bonus_rage_attack_speed")))
	end
end
