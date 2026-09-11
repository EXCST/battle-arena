require('lib/ability_kv')

-- ⚠️ Клиентские хардкоды (на клиенте нет GetAbilityKeyValues → AbilityKV:Get = 0).
-- Держать синхронно с AbilityValues в hero_saber.txt!
local CLIENT_RANGED_EVASION = { 10, 15, 20, 25, 30, 35, 40 }
local CLIENT_MELEE_BLOCK_CHANCE = 100
local CLIENT_MELEE_DAMAGE_PCT = { 10.0, 12.5, 15.0, 17.5, 20.0, 22.5, 25.0 }

local function getLevel(ability)
	if not ability or not IsValidEntity(ability) then return 1 end
	return math.max(1, ability:GetLevel() or 1)
end

local function perLevel(tbl, ability)
	local lvl = getLevel(ability)
	return tbl[math.min(lvl, #tbl)] or 0
end


saber_instinct = class({
	GetIntrinsicModifierName = function() return "modifier_saber_instinct" end,
})


modifier_saber_instinct = class({
	IsHidden   = function() return true end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	} end,
})

-- Уклонение от дальних атак (шанс) и блок части урона ближнего боя (шанс × %).
-- Модификатор входящего урона: возвращает ДОБАВКУ к урону в процентах
-- (0 = урон как есть, -100 = полное игнорирование).
function modifier_saber_instinct:GetModifierIncomingDamage_Percentage(params)
	if not IsServer() then return 0 end

	local parent = self:GetParent()
	if not parent or parent:IsNull() then return 0 end
	local attacker = params.attacker
	if not attacker or attacker:IsNull() then return 0 end

	-- Только автоатаки (не способности): у способностей params.ability не nil
	if params.ability ~= nil and IsValidEntity(params.ability) then return 0 end
	-- Только физический урон от атаки
	if params.damage_type ~= DAMAGE_TYPE_PHYSICAL then return 0 end

	local ability = self:GetAbility()
	if not ability or not IsValidEntity(ability) then return 0 end

	local cap = attacker:GetAttackCapability()
	if cap == DOTA_UNIT_CAP_RANGED_ATTACK then
		local chance = AbilityKV:Get(ability, "ranged_evasion_pct")
		if chance <= 0 then chance = perLevel(CLIENT_RANGED_EVASION, ability) end
		if RandomInt(1, 100) <= chance then
			return -100 -- уклонилась: урон игнорируется
		end
	elseif cap == DOTA_UNIT_CAP_MELEE_ATTACK then
		local blockChance = AbilityKV:Get(ability, "melee_block_chance")
		if blockChance <= 0 then blockChance = CLIENT_MELEE_BLOCK_CHANCE end
		if RandomInt(1, 100) <= blockChance then
			local blockPct = AbilityKV:Get(ability, "melee_damage_pct")
			if blockPct <= 0 then blockPct = perLevel(CLIENT_MELEE_DAMAGE_PCT, ability) end
			return -blockPct -- блокируется часть урона
		end
	end

	return 0
end
