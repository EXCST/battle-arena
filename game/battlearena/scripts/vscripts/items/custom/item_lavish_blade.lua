require('items/generic_datadriven_item')

item_lavish_blade = class({
	GetIntrinsicModifierName = function() return "modifier_item_lavish_blade" end
})

modifier_item_lavish_blade = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	} end,
	GetModifierPreAttack_BonusDamage = function(self) return self.bonus_damage end,
	GetModifierAttackSpeedBonus_Constant = function(self) return self.bonus_attack_speed end
})

function modifier_item_lavish_blade:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self:OnRefresh()

	if not IsServer() then return end
	self.targetTeam = self.ability:GetAbilityTargetTeam() or 0
	self.targetType = self.ability:GetAbilityTargetType() or 0
    self.targetFlags = self.ability:GetAbilityTargetFlags() or 0
    self:SetHasCustomTransmitterData(true)
end

function modifier_item_lavish_blade:AddCustomTransmitterData()
    return
    {
        bonus_damage = self.bonus_damage,
        bonus_attack_speed = self.bonus_attack_speed,
        crit_chance = self.crit_chance,
        crit_multplier = self.crit_multplier
    }
end

function modifier_item_lavish_blade:HandleCustomTransmitterData(data)
    self.bonus_damage = data.bonus_damage
    self.bonus_attack_speed = data.bonus_attack_speed
    self.crit_chance = data.crit_chance
    self.crit_multplier = data.crit_multplier
end

function modifier_item_lavish_blade:OnRefresh()
	if (not IsServer()) then return end
	self.ability = self:GetAbility() or self.ability
	if not self.ability then return end

	self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
	self.bonus_attack_speed = self.ability:GetSpecialValueFor("bonus_attack_speed")
	self.crit_chance = self.ability:GetSpecialValueFor("crit_chance")
	self.crit_multplier = self.ability:GetSpecialValueFor("crit_multiplier")
end

function modifier_item_lavish_blade:GetModifierPreAttack_CriticalStrike()
	if RollPercentage(self.crit_chance) == false then
		return
	end
	return self.crit_multplier
end

function modifier_item_lavish_blade:GetCritDamage()
	return self.crit_multplier / 100
end

function modifier_item_lavish_blade:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self.parent then return end
	if keys.target:GetTeam() == self.parent:GetTeam() then return end
	if(UnitFilter(keys.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
		return
	end
	keys.target:AddNewModifier(self.parent, self.ability, "modifier_item_lavish_blade_debuff", {duration = 0.03})
end

modifier_item_lavish_blade_debuff = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_TOTAL_PERCENTAGE
	} end,
	GetModifierPhysicalArmorBonus = function(self) return self.armor_penetration end,
	GetModifierPhysicalArmorTotal_Percentage = function(self) return self.armor_penetration_pct end,
})

function modifier_item_lavish_blade_debuff:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_item_lavish_blade_debuff:OnRefresh()
	if (not IsServer()) then return end
	self.ability = self:GetAbility() or self.ability
	if not self.ability then return end

	self.armor_penetration = -self.ability:GetSpecialValueFor("armor_penetration")
	self.armor_penetration_pct = -self.ability:GetSpecialValueFor("armor_penetration_pct")
end

LinkLuaModifier("modifier_item_lavish_blade", "items/custom/item_lavish_blade", LUA_MODIFIER_MOTION_NONE, modifier_item_lavish_blade)
LinkLuaModifier("modifier_item_lavish_blade_debuff", "items/custom/item_lavish_blade", LUA_MODIFIER_MOTION_NONE, modifier_item_lavish_blade_debuff)