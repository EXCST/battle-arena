item_fusion_rune_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_fusion_rune_custom"
    end
})

function item_fusion_rune_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local runes = CustomRunes:GetAllRegisteredRunesByType(RUNE_TYPE_POWERUP)
    for _, runeName in pairs(runes) do
        CustomRunes:ApplyRuneEffect(caster, runeName)
    end
end

modifier_item_fusion_rune_custom = class({
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
            MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
        }
    end,
    GetModifierTotalDamageOutgoing_Percentage = function(self)
        return self.bonusOutgoingDamagePct
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_fusion_rune_custom:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_fusion_rune_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusOutgoingDamagePct = self.ability:GetSpecialValueFor("bonus_outgoing_damage_pct")
end

LinkLuaModifier("modifier_item_fusion_rune_custom", "items/neutral_items/fusion_rune", LUA_MODIFIER_MOTION_NONE, modifier_item_fusion_rune_custom)