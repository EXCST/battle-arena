-- ============================================================
-- BATTLE ARENA — Heart of Tarrasque (item_heart / item_heart_2)
-- Реализует механику ровно по описанию предмета:
--   +STR / +HP / +% МАКС. здоровья в секунду (per-level: уровень = ItemBaseLevel)
--   Пассивка «Regeneration Amplification»: +hp_regen_amp% ко ВСЕМ пассивным
--   регенам; отключается на cooldown_melee (ближний) / cooldown_ranged_tooltip
--   (дальний) секунд после урона от вражеского героя или Рошана.
--
-- ⚠️ Реген «% макс. здоровья/сек» — движковое MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE
-- даёт % от БАЗОВОГО HP (мало при огромных пулах) → считаем сами тикером
-- от GetMaxHealth() (паттерн AAF health_deficit) через HEALTH_REGEN_CONSTANT.
-- ============================================================

require('lib/ability_kv')

item_heart_2 = item_heart_2 or class({})

LinkLuaModifier("modifier_item_heart_2", "items/item_heart_2", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_heart_2_amp_disabled", "items/item_heart_2", LUA_MODIFIER_MOTION_NONE)

if not MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE then
	print("[HEART] WARNING: MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE is nil in this build")
end

function item_heart_2:GetIntrinsicModifierName()
	return "modifier_item_heart_2"
end

item_heart = class(item_heart_2)


modifier_item_heart_2 = modifier_item_heart_2 or class({})

function modifier_item_heart_2:IsHidden() return true end
function modifier_item_heart_2:IsPurgable() return false end
function modifier_item_heart_2:RemoveOnDeath() return false end
function modifier_item_heart_2:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_heart_2:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
	if MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE then
		table.insert(funcs, MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE)
	end
	return funcs
end

function modifier_item_heart_2:OnCreated()
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.bonus_hp_regen = 0
	self:StartIntervalThink(0.2)
	self:OnIntervalThink()
	print("[HEART] modifier created on " .. (self.parent and self.parent:GetUnitName() or "?") .. " ability=" .. tostring(self:GetAbility() and self:GetAbility():GetAbilityName()))
end

-- ⚠️ Интринзик: GetAbility() в OnCreated = nil → значения читаем НА ЛЕТУ
-- в геттерах через AbilityKV:Get (per-level по GetLevel() = ItemBaseLevel).
function modifier_item_heart_2:GetModifierBonusStats_Strength()
	local v = AbilityKV:Get(self:GetAbility(), "bonus_strength")
	if not v or v <= 0 then return 0 end
	return v
end

function modifier_item_heart_2:GetModifierHealthBonus()
	local v = AbilityKV:Get(self:GetAbility(), "bonus_health")
	if not v or v <= 0 then return 0 end
	return v
end

-- Реген = hp_regen% от ТЕКУЩЕГО макс. HP в секунду.
-- Пересчитываем тикером; клиенту значение уходит через SetStackCount.
function modifier_item_heart_2:OnIntervalThink()
	if self.parent and not self.parent:IsNull() then
		local pct = AbilityKV:Get(self:GetAbility(), "hp_regen")
		if not pct or pct <= 0 then pct = 0 end
		self.bonus_hp_regen = pct * self.parent:GetMaxHealth() / 100.0
		self:SetStackCount(math.floor(pct * 100))
	end
end

function modifier_item_heart_2:GetModifierConstantHealthRegen()
	if IsClient() then
		return (self:GetStackCount() / 100.0) * self:GetParent():GetMaxHealth() / 100.0
	end
	return self.bonus_hp_regen or 0
end

function modifier_item_heart_2:GetModifierHPRegenAmplify_Percentage()
	if self:GetParent():HasModifier("modifier_item_heart_2_amp_disabled") then
		return 0
	end
	local v = AbilityKV:Get(self:GetAbility(), "hp_regen_amp")
	if not v or v <= 0 then return 0 end
	return v
end

function modifier_item_heart_2:OnTakeDamage(params)
	if not IsServer() then return end

	local parent = self:GetParent()
	if parent:IsNull() then return end

	local attacker = params and params.attacker
	if not attacker or attacker:IsNull() then return end
	if attacker == parent then return end
	if not params.damage or params.damage <= 0 then return end

	-- только урон от ВРАЖЕСКОГО героя (вкл. иллюзии) или Рошана
	if attacker:GetTeamNumber() == parent:GetTeamNumber() then return end
	local isRoshan = attacker:GetUnitName() == "npc_dota_roshan"
	if not isRoshan and not attacker:IsHero() then return end

	local cooldown_key = parent:IsMelee() and "cooldown_melee" or "cooldown_ranged_tooltip"
	local cooldown = AbilityKV:Get(self:GetAbility(), cooldown_key)
	if not cooldown or cooldown <= 0 then cooldown = 5 end

	if parent:HasModifier("modifier_item_heart_2_amp_disabled") then
		parent:RemoveModifierByName("modifier_item_heart_2_amp_disabled")
	end
	parent:AddNewModifier(parent, self:GetAbility(), "modifier_item_heart_2_amp_disabled", { duration = cooldown })
end


modifier_item_heart_2_amp_disabled = modifier_item_heart_2_amp_disabled or class({})

function modifier_item_heart_2_amp_disabled:IsHidden() return true end
function modifier_item_heart_2_amp_disabled:IsPurgable() return false end
function modifier_item_heart_2_amp_disabled:RemoveOnDeath() return false end
