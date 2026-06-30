item_fire_striders = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_fire_striders"
    end
})

modifier_item_fire_striders = class({
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
            MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
        }
    end,
    GetModifierMoveSpeedBonus_Constant = function(self)
        return self.bonusMovespeed
    end,
    GetModifierMagicalResistanceBonus = function(self)
        return self.bonusSpellResistance
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_fire_striders:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self:StartIntervalThink(0.2)
end

function modifier_item_fire_striders:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusMovespeed = self.ability:GetSpecialValueFor("bonus_movement_speed")
    self.bonusSpellResistance = self.ability:GetSpecialValueFor("bonus_magic_resistance")
end

function modifier_item_fire_striders:OnIntervalThink()
    if(self.parent:IsAffectedByLava() == true) then
        self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_fire_striders_buff", {duration = -1})
    else
        self.parent:RemoveModifierByName("modifier_item_fire_striders_buff")
    end
end

function modifier_item_fire_striders:OnDestroy()
    if(not IsServer()) then
        return
    end
    self.parent:RemoveModifierByName("modifier_item_fire_striders_buff")
end

modifier_item_fire_striders_buff = class({
    IsHidden = function() 
        return false 
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
            MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
        }
    end,
    GetModifierHealthRegenPercentage = function(self)
        return self.bonusHpRegenPctLava
    end,
    GetModifierMoveSpeedBonus_Percentage = function(self)
        return self.bonusMovementSpeedPctLaval
    end
})

function modifier_item_fire_striders_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self:StartIntervalThink(0.25)
end

function modifier_item_fire_striders_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHpRegenPctLava = self.ability:GetSpecialValueFor("bonus_hp_regen_in_lava_pct")
    self.bonusMovementSpeedPctLaval = self.ability:GetSpecialValueFor("bonus_movement_speed_in_lava_pct")
end

function modifier_item_fire_striders_buff:OnIntervalThink()
    -- idk how they manage to do that
    if(self.parent:HasModifier("modifier_item_fire_striders") == false) then
        self:Destroy()
    end
end

LinkLuaModifier("modifier_item_fire_striders", "items/neutral_items/fire_striders", LUA_MODIFIER_MOTION_NONE, modifier_item_fire_striders)
LinkLuaModifier("modifier_item_fire_striders_buff", "items/neutral_items/fire_striders", LUA_MODIFIER_MOTION_NONE, modifier_item_fire_striders_buff)