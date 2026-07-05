item_rune_keeper = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_rune_keeper"
    end
})

modifier_item_rune_keeper = class({
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
            MODIFIER_PROPERTY_ROSHDEF_BONUS_BOUNTY_GOLD,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_BOUNTY_GOLD_PERCENTAGE,
            MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
            MODIFIER_EVENT_ROSHDEF_ON_RUNE_PICKED_UP
        }
    end,
    GetModifierMoveSpeedBonus_Constant = function(self)
        return self.bonusMovespeed
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_rune_keeper:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.ability:SetCurrentCharges(GameRules:GetRuneKeeperRunesPickedUp())
end

function modifier_item_rune_keeper:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusMovespeed = self.ability:GetSpecialValueFor("bonus_movespeed")
    self.bonusBountyGoldPerStack = self.ability:GetSpecialValueFor("bounty_bonus_gold")
    self.stacksPerBountyRune = self.ability:GetSpecialValueFor("bounty_stacks_per_rune")
    self.bonusBountyGoldPctPerStackMax = self.ability:GetSpecialValueFor("bounty_bonus_gold_pct_max")
    self.bonusBountyGoldPctPerStack = self.ability:GetSpecialValueFor("bounty_bonus_gold_per_stack_pct")
    self.maxStacks = math.floor((self.bonusBountyGoldPctPerStackMax / self.bonusBountyGoldPctPerStack) + 0.5)
end

function modifier_item_rune_keeper:GetModifierBonusBountyGoldPercentage()
    return self.ability:GetCurrentCharges() * self.bonusBountyGoldPctPerStack
end

function modifier_item_rune_keeper:GetModifierBonusBountyGold()
    return self.bonusBountyGoldPerStack
end

function modifier_item_rune_keeper:OnRunePickedUp(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    if(kv.rune ~= "item_rune_bounty_custom") then
        return
    end
    local newCharges = math.min(self.maxStacks, GameRules:GetRuneKeeperRunesPickedUp() + 1)
    GameRules:SetRuneKeeperRunesPickedUp(newCharges)
    self.ability:SetCurrentCharges(newCharges)
end

LinkLuaModifier("modifier_item_rune_keeper", "items/neutral_items/rune_keeper", LUA_MODIFIER_MOTION_NONE, modifier_item_rune_keeper)