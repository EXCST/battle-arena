item_stonework_pendant_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_stonework_pendant_custom"
    end
})

modifier_item_stonework_pendant_custom = class({
    IsHidden = function() 
        return true 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_ROSHDEF_SPELL_LIFESTEAL,
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
            MODIFIER_PROPERTY_SPELLS_REQUIRE_HP,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    GetModifierSpellLifestealPercantage = function(self)
        return self.bonusSpellLifesteal
    end,
    GetModifierSpellsRequireHP = function(self)
        return self.manaToHpRatio
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_stonework_pendant_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.bonusHealth = self.parent:GetMaxMana(true)
    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
    self:SetHasCustomTransmitterData(true)
end

function modifier_item_stonework_pendant_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusSpellLifesteal = self.ability:GetSpecialValueFor("bonus_spell_lifesteal_pct")
    self.manaToHpRatio = self.ability:GetSpecialValueFor("manacost_to_hpcost_pct") / 100
end

function modifier_item_stonework_pendant_custom:OnIntervalThink()
    self.bonusHealth = self.parent:GetMaxMana(true)
    self.bonusHealthRegen = self.parent:GetManaRegen(true)  
    if(IsServer()) then
        if(self.parent.CalculateStatBonus) then
            self.parent:CalculateStatBonus(true)
        else
            self.parent:CalculateGenericBonuses()
        end
    end
end

function modifier_item_stonework_pendant_custom:AddCustomTransmitterData()
    return
    {
        bonusHealthRegen = self.bonusHealthRegen
    }
end

function modifier_item_stonework_pendant_custom:HandleCustomTransmitterData(data)
    self.bonusHealthRegen = data.bonusHealthRegen
end

function modifier_item_stonework_pendant_custom:GetModifierExtraManaBonus()
    if (self.bonusHealth == nil) then
        return 0
    end
    return -self.bonusHealth
end

function modifier_item_stonework_pendant_custom:GetModifierConstantManaRegen()
    return 0
end

function modifier_item_stonework_pendant_custom:GetModifierBonusHealth()
    if (self.bonusHealth == nil) then
        return 0
    end
    return self.bonusHealth
end

function modifier_item_stonework_pendant_custom:GetModifierConstantHealthRegen()
    if (self.bonusHealthRegen == nil) then
        return 0
    end
    return self.bonusHealthRegen
end

LinkLuaModifier("modifier_item_stonework_pendant_custom", "items/neutral_items/stonework_pendant", LUA_MODIFIER_MOTION_NONE, modifier_item_stonework_pendant_custom)