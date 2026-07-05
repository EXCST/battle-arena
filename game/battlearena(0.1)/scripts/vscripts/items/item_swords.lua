require('items/generic_datadriven_item')

item_sange_yasha_kaya_base = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_sange_yasha_kaya"
    end
})

function item_sange_yasha_kaya_base:OnHeroLevelUp()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local modifier = caster:FindModifierByName("modifier_item_sange_yasha_kaya_buff")
    if(modifier) then
        local bonusStrengthPerLevel = self:GetSpecialValueFor("bonus_str_per_lvl")
        local bonusAgilityPerLevel = self:GetSpecialValueFor("bonus_agi_per_lvl")
        local bonusIntellectPerLevel = self:GetSpecialValueFor("bonus_int_per_lvl")
        modifier:AddStack(self, bonusStrengthPerLevel, bonusAgilityPerLevel, bonusIntellectPerLevel)
    end
end

item_sange_custom_1 = class(item_sange_yasha_kaya_base)
item_sange_custom_2 = class(item_sange_yasha_kaya_base)
item_sange_custom_3 = class(item_sange_yasha_kaya_base)
item_yasha_custom_1 = class(item_sange_yasha_kaya_base)
item_yasha_custom_2 = class(item_sange_yasha_kaya_base)
item_yasha_custom_3 = class(item_sange_yasha_kaya_base)
item_kaya_custom_1 = class(item_sange_yasha_kaya_base)
item_kaya_custom_2 = class(item_sange_yasha_kaya_base)
item_kaya_custom_3 = class(item_sange_yasha_kaya_base)
item_sange_yasha_custom_1 = class(item_sange_yasha_kaya_base)
item_sange_yasha_custom_2 = class(item_sange_yasha_kaya_base)
item_sange_yasha_custom_3 = class(item_sange_yasha_kaya_base)
item_sange_kaya_custom_1 = class(item_sange_yasha_kaya_base)
item_sange_kaya_custom_2 = class(item_sange_yasha_kaya_base)
item_sange_kaya_custom_3 = class(item_sange_yasha_kaya_base)
item_yasha_kaya_custom_1 = class(item_sange_yasha_kaya_base)
item_yasha_kaya_custom_2 = class(item_sange_yasha_kaya_base)
item_yasha_kaya_custom_3 = class(item_sange_yasha_kaya_base)
item_sange_yasha_kaya_custom_1 = class(item_sange_yasha_kaya_base)
item_sange_yasha_kaya_custom_2 = class(item_sange_yasha_kaya_base)
item_sange_yasha_kaya_custom_3 = class(item_sange_yasha_kaya_base)
item_imba_magic_armlet = class(item_sange_yasha_kaya_base)
item_imba_magic_armlet_1 = class(item_sange_yasha_kaya_base)
item_imba_magic_armlet_2 = class(item_sange_yasha_kaya_base)
item_imba_magic_armlet_3 = class(item_sange_yasha_kaya_base)
item_imba_magic_armlet_4 = class(item_sange_yasha_kaya_base)

modifier_item_sange_yasha_kaya = class({
    IsHidden = function() 
        return true 
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
            MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE
        }
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.bonusStrength
    end,
    GetModifierBonusStats_Agility = function(self)
        return self.bonusAgility
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusIntellect
    end,
    GetModifierStatusResistanceStacking = function(self)
        return self.bonusStatusResistance
    end,
    GetModifierHPRegenAmplify_Percentage = function(self)
        return self.bonusHealingAmp
    end,
    GetModifierLifestealRegenAmplify_Percentage = function(self)
        return self.bonusLifestealAmp
    end,
    GetModifierAttackSpeedBonus_Constant = function(self)
        return self.bonusAttackSpeed
    end,
    GetModifierMoveSpeedBonus_Percentage = function(self)
        return self.bonusMovementSpeedPct
    end,
    GetModifierSpellAmplify_Percentage = function(self)
        return self.bonusSpellAmplificatonPct
    end,
    GetModifierMPRegenAmplify_Percentage = function(self)
        return self.bonusManaRegenerationAmplifyPct
    end,
    GetModifierSpellLifestealRegenAmplify_Percentage = function(self)
        return self.bonusSpellLifestealAmp
    end
})

function modifier_item_sange_yasha_kaya:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_sange_yasha_kaya_buff", {duration = -1})
end

function modifier_item_sange_yasha_kaya:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusStrength = math.max(self.bonusStrength or 0, self.ability:GetSpecialValueFor("bonus_str"))
    self.bonusAgility = math.max(self.bonusAgility or 0, self.ability:GetSpecialValueFor("bonus_agi"))
    self.bonusIntellect = math.max(self.bonusIntellect or 0, self.ability:GetSpecialValueFor("bonus_int"))
    self.bonusStatusResistance = math.max(self.bonusStatusResistance or 0, self.ability:GetSpecialValueFor("status_resistance"))
    self.bonusHealingAmp = math.max(self.bonusHealingAmp or 0, self.ability:GetSpecialValueFor("hp_regen_amp"))
    self.bonusLifestealAmp = math.max(self.bonusLifestealAmp or 0, self.ability:GetSpecialValueFor("lifesteal_regen_amp"))
    self.bonusAttackSpeed = math.max(self.bonusAttackSpeed or 0, self.ability:GetSpecialValueFor("bonus_attack_speed"))
    self.bonusMovementSpeedPct = math.max(self.bonusMovementSpeedPct or 0, self.ability:GetSpecialValueFor("movement_speed_percent_bonus"))
    self.bonusSpellAmplificatonPct = math.max(self.bonusSpellAmplificatonPct or 0, self.ability:GetSpecialValueFor("spell_amp"))
    self.bonusManaRegenerationAmplifyPct = math.max(self.bonusManaRegenerationAmplifyPct or 0, self.ability:GetSpecialValueFor("mana_regen_multiplier"))
    self.bonusSpellLifestealAmp = math.max(self.bonusSpellLifestealAmp or 0, self.ability:GetSpecialValueFor("spell_lifesteal_amp"))
end

modifier_item_sange_yasha_kaya_buff = class({
    IsHidden = function() 
        return false 
    end,
    IsPurgable = function()
        return false
    end,
    IsDebuff = function()
        return false    
    end,
    IsPurgeException = function()
        return false
    end,
    RemoveOnDeath = function()
        return false
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_TOOLTIP
        }
    end,
    GetAttributes = function() 
        return MODIFIER_ATTRIBUTE_PERMANENT 
    end,
    GetTexture = function(self)
        return "item_halloween_candy"
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.totalStr
    end,
    GetModifierBonusStats_Agility = function(self)
        return self.totalAgi
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.totalInt
    end
})

function modifier_item_sange_yasha_kaya_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self.totalStr = 0
    self.totalAgi = 0
    self.totalInt = 0
    self.tooltipThing = 0
    if(not IsServer()) then
        return
    end
    self:SetHasCustomTransmitterData(true)
end

function modifier_item_sange_yasha_kaya_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
end

function modifier_item_sange_yasha_kaya_buff:AddStack(item, str, agi, int)
    if(self.ability ~= item) then
        return
    end
    self.totalStr = self.totalStr + str
    self.totalAgi = self.totalAgi + agi
    self.totalInt = self.totalInt + int
    self:SendBuffRefreshToClients()
end

function modifier_item_sange_yasha_kaya_buff:AddCustomTransmitterData()
    return
    {
        totalStr = self.totalStr,
        totalAgi = self.totalAgi,
        totalInt = self.totalInt
    }
end

function modifier_item_sange_yasha_kaya_buff:HandleCustomTransmitterData(data)
    for k,v in pairs(data) do
        self[k] = v
    end
end

function modifier_item_sange_yasha_kaya_buff:OnTooltip()
    local result = 0
    if(self.tooltipThing == 0) then
        result = self.totalStr
    end
    if(self.tooltipThing == 1) then
        result = self.totalAgi
    end
    if(self.tooltipThing == 2) then
        result = self.totalInt
    end
    self.tooltipThing = self.tooltipThing + 1
    if(self.tooltipThing > 2) then
        self.tooltipThing = 0
    end
    return result
end

LinkLuaModifier("modifier_item_sange_yasha_kaya", "items/item_swords", LUA_MODIFIER_MOTION_NONE, modifier_item_sange_yasha_kaya)
LinkLuaModifier("modifier_item_sange_yasha_kaya_buff", "items/item_swords", LUA_MODIFIER_MOTION_NONE, modifier_item_sange_yasha_kaya_buff)