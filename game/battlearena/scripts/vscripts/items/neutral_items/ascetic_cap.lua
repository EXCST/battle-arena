item_ascetic_cap_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_ascetic_cap_custom"
    end
})

function item_ascetic_cap_custom:Precache(context)
    PrecacheResource("particle", "particles/items4_fx/ascetic_cap.vpcf", context)
end

modifier_item_ascetic_cap_custom = class({
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
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_EVENT_ROSHDEF_ON_PRE_MODIFIER_ADDED
        }
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.bonusStrength
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_ascetic_cap_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_ascetic_cap_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusStrength = self.ability:GetSpecialValueFor("bonus_strength")
    self.duration = self.ability:GetSpecialValueFor("duration")
end

function modifier_item_ascetic_cap_custom:OnPreModifierAdded(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    if(self.ability:IsCooldownReady() == false) then
        return
    end
    if(kv.modifier:IsDebuff() == false) then
        return
    end
    self.parent:AddNewModifier(
        self.parent, 
        self.ability, 
        "modifier_item_ascetic_cap_custom_buff", 
        {
            duration = self.duration
        }
    )
    self.ability:UseResources(true, false, true, true)
    EmitSoundOn("Item.AsceticCap.Cast", self.parent)
end

modifier_item_ascetic_cap_custom_buff = class({
    IsHidden = function() 
        return false 
    end,
    IsDebuff = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
        }
    end,
    GetModifierStatusResistanceStacking = function(self)
        return self.bonusStatusResistance
    end,
    GetTexture = function(self)
        return self.buffIcon
    end,
    GetEffectName = function()
        return "particles/items4_fx/ascetic_cap.vpcf"
    end
})

function modifier_item_ascetic_cap_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    end
end

function modifier_item_ascetic_cap_custom_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusStatusResistance = self.ability:GetSpecialValueFor("status_resistance")
end

LinkLuaModifier("modifier_item_ascetic_cap_custom", "items/neutral_items/ascetic_cap", LUA_MODIFIER_MOTION_NONE, modifier_item_ascetic_cap_custom)
LinkLuaModifier("modifier_item_ascetic_cap_custom_buff", "items/neutral_items/ascetic_cap", LUA_MODIFIER_MOTION_NONE, modifier_item_ascetic_cap_custom_buff)
