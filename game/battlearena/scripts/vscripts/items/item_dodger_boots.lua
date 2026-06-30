require('items/generic_datadriven_item')


item_dodger_boots = class({
	GetIntrinsicModifierName = function() return "modifier_item_dodger_boots" end
})
function item_dodger_boots:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_item_dodger_boots_active", {duration = self:GetSpecialValueFor("duration")})
end

modifier_item_dodger_boots = class({
	IsHidden = function() return true end,
	IsItem = function() return true end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT_UNIQUE,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	} end,
	GetModifierMoveSpeedBonus_Constant_Unique = function(self) return self.bonus_ms end,
	GetModifierPreAttack_BonusDamage = function(self) return self.bonus_damage end,
	GetModifierAttackSpeedBonus_Constant = function(self) return self.bonus_attack_speed end
})

function modifier_item_dodger_boots:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.bonus_ms = self:GetAbility():GetSpecialValueFor("bonus_ms")
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
	self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
	self:OnRefresh()
end

function modifier_item_dodger_boots:OnRefresh()
	if self.ability:GetLevel() == 3 then
        self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_boots_of_travel", nil)
    elseif self.ability:GetLevel() > 3 then
        self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_boots_of_travel_2", nil)
    end
end

function modifier_item_dodger_boots:OnDestroy()
	if self.ability:GetLevel() == 3 then
        self.parent:RemoveModifierByName("modifier_item_boots_of_travel")
    elseif self.ability:GetLevel() > 3 then
        self.parent:RemoveModifierByName("modifier_item_boots_of_travel_2")
    end
end
modifier_item_dodger_boots_active = class({
	IsHidden = function() return false end,
	IsPurgable = function() return true end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ROSHDEF_EVASION_CONSTANT
	} end,
	GetModifierMoveSpeedBonus_Percentage = function(self) return self.active_ms_bonus_pct end,
	GetModifierEvasion_Constant = function(self) return self.active_evasion_bonus end,
	GetEffectName = function() return "particles/econ/events/ti8/phase_boots_ti8.vpcf" end,
	GetEffectAttachType = function() return PATTACH_ABSORIGIN_FOLLOW end,
	CheckState = function() return {
		[MODIFIER_STATE_NO_UNIT_COLLISION ] = true
	} end,
	GetTexture = function(self) return self:GetAbility():GetAbilityTextureName() end
})


function modifier_item_dodger_boots_active:OnCreated()
	self.active_ms_bonus_pct = self:GetAbility():GetSpecialValueFor("active_ms_bonus_pct")
	self.active_evasion_bonus = self:GetAbility():GetSpecialValueFor("active_evasion_bonus")
end

item_dodger_boots_1 = class(item_dodger_boots)
item_dodger_boots_2 = class(item_dodger_boots)
item_dodger_boots_3 = class(item_dodger_boots)
item_dodger_boots_4 = class(item_dodger_boots)


LinkLuaModifier("modifier_item_dodger_boots", "items/item_dodger_boots", 0, modifier_item_dodger_boots)
LinkLuaModifier("modifier_item_dodger_boots_active", "items/item_dodger_boots", 0, modifier_item_dodger_boots_active)
