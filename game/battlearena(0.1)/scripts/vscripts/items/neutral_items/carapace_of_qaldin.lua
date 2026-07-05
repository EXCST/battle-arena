item_carapace_of_qaldin_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_carapace_of_qaldin_custom"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("radius")
    end
})

modifier_item_carapace_of_qaldin_custom = class({
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
            MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_PHYSICAL_ARMOR_BONUS_TOTAL_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_HEAL_CAUSED_PERCENTAGE
        }
    end,
    IsAuraActiveOnDeath = function()
        return false
    end,
    GetAuraRadius = function(self)
        return self.radius
    end,
    GetAuraSearchFlags = function(self)
        return self.targetFlags
    end,
    GetAuraSearchTeam = function(self)
        return self.targetTeam
    end,
    IsAura = function()
        return true
    end,
    GetAuraSearchType = function(self)
        return self.targetType
    end,
    GetModifierAura = function()
        return "modifier_item_carapace_of_qaldin_custom_buff"
    end,
    GetAuraDuration = function()
        return 0
    end,
    GetModifierHPRegenAmplify_Percentage = function(self)
        return self.bonusHealthRegenerationAmplifyPct
    end,
    GetModifierLifestealRegenAmplify_Percentage = function(self)
        return self.bonusHealthRegenerationAmplifyPct
    end,
    GetModifierSpellLifestealRegenAmplify_Percentage = function(self)
        return self.bonusHealthRegenerationAmplifyPct
    end,
    GetModifierHealCaused_Percentage = function(self)
        return self.bonusHealthRegenerationAmplifyPct
    end,
    GetModifierPhysicalArmorTotal_Percentage = function(self)
        return self.bonusArmorPct
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_carapace_of_qaldin_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
end

function modifier_item_carapace_of_qaldin_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealthRegenerationAmplifyPct = self.ability:GetSpecialValueFor("health_regeneration_amp_pct")
    self.bonusArmorPct = self.ability:GetSpecialValueFor("bonus_armor_pct")
    self.radius = self.ability:GetCastRange()
end

function modifier_item_carapace_of_qaldin_custom:GetAuraEntityReject(npc)
    return npc == self.parent
end

modifier_item_carapace_of_qaldin_custom_buff = class({
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
            MODIFIER_EVENT_ON_ATTACK_LANDED,
            MODIFIER_PROPERTY_TOOLTIP
        }
    end,
    OnTooltip = function(self)
        return self.damageToLifesteal * 100
    end
})

function modifier_item_carapace_of_qaldin_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.auraOwner = self:GetAuraOwner()
    self.parent = self:GetParent()
end

function modifier_item_carapace_of_qaldin_custom_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.damageToLifesteal = self.ability:GetSpecialValueFor("ally_damage_to_owner_hp_pct") / 100
end

function modifier_item_carapace_of_qaldin_custom_buff:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    self.auraOwner:PerformLifesteal(kv.target, kv.damage * self.damageToLifesteal)
end

LinkLuaModifier("modifier_item_carapace_of_qaldin_custom", "items/neutral_items/carapace_of_qaldin", LUA_MODIFIER_MOTION_NONE, modifier_item_carapace_of_qaldin_custom)
LinkLuaModifier("modifier_item_carapace_of_qaldin_custom_buff", "items/neutral_items/carapace_of_qaldin", LUA_MODIFIER_MOTION_NONE, modifier_item_carapace_of_qaldin_custom_buff)