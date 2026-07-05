require("items/item_boss_drop_base")
item_angels_armor = item_angels_armor or class(item_boss_drop_base)

LinkLuaModifier("modifier_angels_armor", "items/angels_armor/angels_armor", LUA_MODIFIER_MOTION_NONE)

function item_angels_armor:GetIntrinsicModifierName() return "modifier_angels_armor" end

modifier_angels_armor = modifier_angels_armor or class({})

function modifier_angels_armor:IsHidden() return true end
function modifier_angels_armor:IsPurgable() return false end
function modifier_angels_armor:RemoveOnDeath() return false end
function modifier_angels_armor:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_angels_armor:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_angels_armor:OnRefresh()
	if not IsValidEntity(self.ability) then return end

	self.armor = self.ability:GetSpecialValueFor("armor")
	self.attack_speed = self.ability:GetSpecialValueFor("attack_speed")
	self.health = self.ability:GetSpecialValueFor("health")
	self.all_stats = self.ability:GetSpecialValueFor("all_stats")
end

function modifier_angels_armor:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- GetModifierPhysicalArmorBonus
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, -- GetModifierAttackSpeedBonus_Constant
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS, -- GetModifierExtraHealthBonus
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, -- GetModifierBonusStats_Strength
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS, -- GetModifierBonusStats_Agility
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
	}
end

function modifier_angels_armor:GetModifierPhysicalArmorBonus() return self.armor end
function modifier_angels_armor:GetModifierAttackSpeedBonus_Constant() return self.attack_speed end
function modifier_angels_armor:GetModifierExtraHealthBonus() return self.health end
function modifier_angels_armor:GetModifierBonusStats_Strength() return self.all_stats end
function modifier_angels_armor:GetModifierBonusStats_Agility() return self.all_stats end
function modifier_angels_armor:GetModifierBonusStats_Intellect() return self.all_stats end
