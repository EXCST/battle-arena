item_ninja_gear_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_ninja_gear_custom"
    end
})

function item_ninja_gear_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_item_ninja_gear_custom_buff", {duration = self:GetSpecialValueFor("duration")})
    EmitSoundOn("Item.NinjaGear.Cast", caster)
end

item_smoke_of_deceit_custom = class(item_ninja_gear_custom)

function item_smoke_of_deceit_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_item_smoke_of_deceit_custom_buff", {duration = self:GetSpecialValueFor("duration")})
    EmitSoundOn("Item.NinjaGear.Cast", caster)
    self:SpendCharge()
    if(self:GetCurrentCharges() < 1) then
        self:Destroy()
    end
end

modifier_item_ninja_gear_custom = class({
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
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT
        }
    end,
    GetModifierBonusStats_Agility = function(self)
        return self.bonusAgility
    end,
    GetModifierMoveSpeedBonus_Constant = function(self)
        return self.bonusMovespeed
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_ninja_gear_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_ninja_gear_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAgility = self.ability:GetSpecialValueFor("bonus_agility")
    self.bonusMovespeed = self.ability:GetSpecialValueFor("passive_movement_bonus")
end

modifier_item_ninja_gear_custom_buff = class({
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
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
            MODIFIER_EVENT_ON_ATTACK_LANDED,
            MODIFIER_EVENT_ON_ABILITY_EXECUTED
        }
    end,
    CheckState = function()
        return {
            [MODIFIER_STATE_INVISIBLE] = true
        }
    end,
    GetModifierBonusStats_Agility = function(self)
        return self.bonusAgility
    end,
    GetModifierMoveSpeedBonus_Percentage = function(self)
        return self.bonusMovespeedPct
    end,
    GetModifierInvisibilityLevel = function()
        return 1
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_ninja_gear_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    end
end

function modifier_item_ninja_gear_custom_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusMovespeedPct = self.ability:GetSpecialValueFor("bonus_movement_speed")
end

function modifier_item_ninja_gear_custom_buff:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    self:Destroy()
end

function modifier_item_ninja_gear_custom_buff:OnAbilityExecuted(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    self:Destroy()
end

modifier_item_smoke_of_deceit_custom_buff = class(modifier_item_ninja_gear_custom_buff)

LinkLuaModifier("modifier_item_ninja_gear_custom", "items/neutral_items/ninja_gear", LUA_MODIFIER_MOTION_NONE, modifier_item_ninja_gear_custom)
LinkLuaModifier("modifier_item_ninja_gear_custom_buff", "items/neutral_items/ninja_gear", LUA_MODIFIER_MOTION_NONE, modifier_item_ninja_gear_custom_buff)
LinkLuaModifier("modifier_item_smoke_of_deceit_custom_buff", "items/neutral_items/ninja_gear", LUA_MODIFIER_MOTION_NONE, modifier_item_smoke_of_deceit_custom_buff)