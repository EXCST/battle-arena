item_legendary_book = class({})

function item_legendary_book:Precache(context)
    PrecacheResource("particle", "particles/custom/items/legendary_book/ground_effect.vpcf", context)
    PrecacheResource("model", "models/custom/items/legendary_book/legendary_book.vmdl", context)
end

function item_legendary_book:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    LegendaryBook:OpenBookForPlayer(caster:GetPlayerOwnerID())
end

function item_legendary_book:GetDamageReductionPercent()
    return self:GetSpecialValueFor("bonus_damage_reduction_pct")
end

function item_legendary_book:GetOutgoingDamagePercent()
    return self:GetSpecialValueFor("bonus_outgoing_damage_pct")
end

function item_legendary_book:GetMaxAbilities()
    return self:GetSpecialValueFor("max_abilities")
end

modifier_item_legendary_book_buff = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    IsDebuff = function()
        return false
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_ROSHDEF_INCOMING_DAMAGE_RESISTANCE_PERCENTAGE,
            MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
            MODIFIER_PROPERTY_TOOLTIP
        }
    end,
    GetModifierIncomingDamageResistance_Percentage = function(self)
        return self.bonusIncomingDamageReductionPct
    end,
    GetModifierTotalDamageOutgoing_Percentage = function(self)
        return self.bonusOutgoingDamagePct
    end,
    GetTexture = function(self)
        return self.buffIcon
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_legendary_book_buff:OnCreated()
    self.tooltipThing = 0
    self.ability = self:GetAbility()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
        return
    end
    self.bonusIncomingDamageReductionPct = self.bonusIncomingDamageReductionPct or 0
    self.bonusOutgoingDamagePct = self.bonusOutgoingDamagePct or 0
    self:SetHasCustomTransmitterData(true)
end

function modifier_item_legendary_book_buff:IsCanAddIncomingDamageReductionPercent(item, value)
    if(self.bonusIncomingDamageReductionPct + value > item:GetSpecialValueFor("bonus_damage_reduction_pct_max")) then
        return false
    end
    return true
end

function modifier_item_legendary_book_buff:IsCanAddOutgoingDamagePercent(item, value)
    return true
end

function modifier_item_legendary_book_buff:AddIncomingDamageReductionPercent(value)
    self.bonusIncomingDamageReductionPct = self.bonusIncomingDamageReductionPct + value
    self:SendBuffRefreshToClients()
end

function modifier_item_legendary_book_buff:AddOutgoingDamagePercent(value)
    self.bonusOutgoingDamagePct = self.bonusOutgoingDamagePct + value
    self:SendBuffRefreshToClients()
end

function modifier_item_legendary_book_buff:OnTooltip()
    local result = 0
    if(self.tooltipThing == 0) then
        result = self.bonusOutgoingDamagePct
    end
    if(self.tooltipThing == 1) then
        result = self.bonusIncomingDamageReductionPct
    end
    self.tooltipThing = self.tooltipThing + 1
    if(self.tooltipThing > 1) then
        self.tooltipThing = 0
    end
    return result
end

function modifier_item_legendary_book_buff:AddCustomTransmitterData()
    return
    {
        bonusIncomingDamageReductionPct = self.bonusIncomingDamageReductionPct,
        bonusOutgoingDamagePct = self.bonusOutgoingDamagePct
    }
end

function modifier_item_legendary_book_buff:HandleCustomTransmitterData(data)
    for k,v in pairs(data) do
        self[k] = v
    end
end

LinkLuaModifier("modifier_item_legendary_book_buff", "items/item_legendary_book", LUA_MODIFIER_MOTION_NONE, modifier_item_legendary_book_buff)