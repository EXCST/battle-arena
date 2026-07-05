require('items/generic_datadriven_item')

item_bane_blade = class({
	GetIntrinsicModifierName = function() return "modifier_item_bane_blade" end
})

modifier_item_bane_blade = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	IsPurgeException = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PROJECTILE_NAME,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	} end,
	GetModifierPreAttack_BonusDamage = function(self) return self.bonus_damage end,
	GetModifierBonusStats_Strength = function(self) return self.bonus_allstats end,
	GetModifierBonusStats_Agility = function(self) return self.bonus_allstats end,
	GetModifierBonusStats_Intellect = function(self) return self.bonus_allstats end,
	GetModifierProjectileName = function() return "particles/units/heroes/hero_viper/viper_poison_attack.vpcf" end
})

function modifier_item_bane_blade:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self:OnRefresh()
end

function modifier_item_bane_blade:OnRefresh()
	if (not IsServer()) then return end
	self.ability = self:GetAbility() or self.ability
	if not self.ability then return end

	self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
	self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
	self.debuff_duration = self.ability:GetSpecialValueFor("debuff_duration")

	self.targetType = self.ability:GetAbilityTargetType()
    self.targetFlags = self.ability:GetAbilityTargetFlags()
	self.targetTeam = self.ability:GetAbilityTargetTeam()
end

function modifier_item_bane_blade:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self.parent then return end
	if keys.target:GetTeam() == self.parent:GetTeam() then return end
	if(UnitFilter(keys.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
		return
	end
	keys.target:AddNewModifier(self.parent, self.ability, "modifier_item_bane_blade_debuff", {duration = self.debuff_duration})
end

modifier_item_bane_blade_debuff = class({
	IsPurgable = function() return false end,
    IsPurgeException = function() return false end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    } end,
    GetModifierPhysicalArmorBonus = function(self)
		return(self.debuff_armor + self.debuff_armor_stack * self:GetStackCount()) * (-1)
    end
})

function modifier_item_bane_blade_debuff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()

    self:SetStackCount(0)
    self:StartIntervalThink(1)
end

function modifier_item_bane_blade_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.debuff_armor = self.ability:GetSpecialValueFor("debuff_armor")
    self.debuff_armor_stack = self.ability:GetSpecialValueFor("debuff_armor_stack")
    self.debuff_max_stack = self.ability:GetSpecialValueFor("debuff_max_stack")

	self.debuff_dps = self.ability:GetSpecialValueFor("debuff_dps")
    self.debuff_dps_stat = self.ability:GetSpecialValueFor("debuff_dps_stat_pct") / 100 * (self:GetCaster():GetStrength() + self:GetCaster():GetAgility() + self:GetCaster():GetPrimaryStatValue())

    self.hDamageTable = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        ability = self.ability,
        damage = self.debuff_dps + self.debuff_dps_stat,
        damage_type = DAMAGE_TYPE_MAGICAL
    }
end

function modifier_item_bane_blade_debuff:OnIntervalThink()
	if not IsServer() then return end
    if self:GetStackCount() < self.debuff_max_stack then
        self:IncrementStackCount()
    end

	local damageDone = ApplyDamage(self.hDamageTable)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self.hDamageTable.victim, damageDone, nil)
end

LinkLuaModifier("modifier_item_bane_blade", "items/custom/item_bane_blade", LUA_MODIFIER_MOTION_NONE, modifier_item_bane_blade)
LinkLuaModifier("modifier_item_bane_blade_debuff", "items/custom/item_bane_blade", LUA_MODIFIER_MOTION_NONE, modifier_item_bane_blade_debuff)
