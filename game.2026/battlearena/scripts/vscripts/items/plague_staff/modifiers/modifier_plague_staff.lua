function IsBitSet(value, ...)
	local flags = bit.bor(...)
	return bit.band(value, flags) == flags
end

modifier_plague_staff = class({})

function modifier_plague_staff:IsHidden() return true end
function modifier_plague_staff:IsPurgable() return false end
function modifier_plague_staff:DestroyOnExpire() return false end
function modifier_plague_staff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_plague_staff:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_plague_staff:OnRefresh()
	if not IsValidEntity(self.ability) then return end

	self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
	self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
	self.bonus_agi = self.ability:GetSpecialValueFor("bonus_agi")
	self.bonus_armor = self.ability:GetSpecialValueFor("bonus_armor")
	self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
	self.bonus_hpregen = self.ability:GetSpecialValueFor("bonus_hpregen")
	self.bonus_mana = self.ability:GetSpecialValueFor("bonus_mana")
	self.bonus_spellamp = self.ability:GetSpecialValueFor("bonus_spellamp")

	self.chance = self.ability:GetSpecialValueFor("chance")
	self.magical_crit = self.ability:GetSpecialValueFor("magical_crit") - 100
end

function modifier_plague_staff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_plague_staff:GetModifierConstantHealthRegen() return self.bonus_hpregen end
function modifier_plague_staff:GetModifierBonusStats_Strength() return self.bonus_str end
function modifier_plague_staff:GetModifierBonusStats_Agility() return self.bonus_agi end
function modifier_plague_staff:GetModifierBonusStats_Intellect() return self.bonus_int end
function modifier_plague_staff:GetModifierPreAttack_BonusDamage() return self.bonus_damage end
function modifier_plague_staff:GetModifierSpellAmplify_Percentage() return self.bonus_spellamp end
function modifier_plague_staff:GetModifierPhysicalArmorBonus() return self.bonus_armor end
function modifier_plague_staff:GetModifierExtraManaBonus() return self.bonus_mana end

local PLAGUE_STAFF_EXCEPTIONS = {
	zuus_static_field = true,
	item_plague_staff = true,
	warlock_fatal_bonds = true,
	item_bfury = true,
	item_bfury_2 = true,
	item_demons_fury = true,
	item_holy_book = true,
	item_holy_book_2 = true,
	item_burning_book = true,
}

if IsServer() then
	function modifier_plague_staff:GetModifierTotalDamageOutgoing_Percentage(params)
		if not IsValidEntity(params.target) or not params.target:IsAlive() then return end
		if self.parent:GetTeam() == params.target:GetTeam() then return end
		if not params.inflictor then return end

		if self.parent:FindAllModifiersByName("modifier_plague_staff")[1] ~= self then return end
		if not RollPercentage(self.chance) then return end

		if IsBitSet(params.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) then return end
		if IsBitSet(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) then return end
		if params.damage_category and params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then return end

		local ability_name = params.inflictor:GetAbilityName()
		if PLAGUE_STAFF_EXCEPTIONS[ability_name] then return end

		SendOverheadEventMessage(self.parent, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, params.target, self.magical_crit / 100 * params.original_damage, nil)
		return self.magical_crit
	end
end
