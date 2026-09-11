--[[
	StatDamage: бонусный урон к способностям/предметам в зависимости от характеристики кастера.
	Регистрация: StatDamage:Register("имя_способности", { key = "damage_pct", stat = "primary" })
		key  - ключ в AbilityValues способности (значение в процентах)
		stat - primary | str | agi | int
	Бонус начисляется через DamageFilter: event.damage += pct/100 * стат.
	Фильтр никогда не блокирует урон и не вызывает ApplyDamage (нет ре-входа).
]]

StatDamage = StatDamage or class({})

StatDamage.registry = StatDamage.registry or {}

function StatDamage:Register(ability_name, cfg)
	cfg = cfg or {}
	cfg.key = cfg.key or "damage_pct"
	cfg.stat = cfg.stat or "primary"
	self.registry[ability_name] = cfg
	print("[StatDamage] registered: " .. ability_name .. " (key=" .. cfg.key .. ", stat=" .. cfg.stat .. ")")
end

function StatDamage:_GetStatValue(unit, stat)
	if stat == "str" then
		return unit:GetStrength(true)
	elseif stat == "agi" then
		return unit:GetAgility(true)
	elseif stat == "int" then
		return unit:GetIntellect(true)
	end
	return unit:GetPrimaryStatValue()
end

function StatDamage:_GetBonus(inflictor, attacker)
	local cfg = self.registry[inflictor:GetAbilityName()]
	if not cfg then return 0 end
	if not attacker or not IsValidEntity(attacker) then return 0 end
	if not attacker.GetPrimaryStatValue then return 0 end

	local pct = inflictor:GetSpecialValueFor(cfg.key) or 0
	if pct <= 0 then return 0 end

	return pct / 100 * self:_GetStatValue(attacker, cfg.stat)
end

function StatDamage:DamageFilter(event)
	if not event.entindex_inflictor_const then return true end

	local inflictor = EntIndexToHScript(event.entindex_inflictor_const)
	if not inflictor or not inflictor.GetAbilityName then return true end
	if not self.registry[inflictor:GetAbilityName()] then return true end

	local attacker = event.entindex_attacker_const and EntIndexToHScript(event.entindex_attacker_const) or nil
	local bonus = self:_GetBonus(inflictor, attacker)
	if bonus > 0 then
		event.damage = event.damage + bonus
	end

	return true
end

--====================================================
-- Реестр способностей и предметов со стат-уроном
--====================================================
StatDamage:Register("item_radiance",    { key = "damage_from_stat" })
StatDamage:Register("item_radiance_2",  { key = "damage_from_stat" })
StatDamage:Register("item_radiance_3",  { key = "damage_from_stat" })
StatDamage:Register("pudge_meat_hook",  { key = "damage_pct" })
