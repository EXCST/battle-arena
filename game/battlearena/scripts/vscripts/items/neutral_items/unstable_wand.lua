item_unstable_wand_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_unstable_wand_custom"
    end
})

function item_unstable_wand_custom:Precache(context)
    PrecacheResource("model", "models/courier/mighty_boar/mighty_boar.vmdl", context)
end

function item_unstable_wand_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_item_unstable_wand_custom_buff", {duration = self:GetSpecialValueFor("duration")})
    EmitSoundOn("Item.PigPole.Cast", caster)
end

modifier_item_unstable_wand_custom = class({
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
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        }
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.bonusAllStats
    end,
    GetModifierBonusStats_Agility = function(self)
        return self.bonusAllStats
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusAllStats
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_unstable_wand_custom:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_unstable_wand_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAllStats = self.ability:GetSpecialValueFor("all_stats")
end

modifier_item_unstable_wand_custom_buff = class({
    IsHidden = function() 
        return false 
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_MODEL_CHANGE
        }
    end,
    CheckState = function()
        return {
            [MODIFIER_STATE_HEXED] = true,
            [MODIFIER_STATE_SILENCED] = true
        }
    end,
    GetModifierMoveSpeedBonus_Percentage = function(self)
        return self.bonusMovespeedPct
    end,
    GetModifierModelChange = function(self)
        return "models/courier/mighty_boar/mighty_boar.vmdl"
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_unstable_wand_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
        return
    end
    Timers:CreateTimer(0.03, function()
        self:GetParent():StartGesture(ACT_DOTA_SPAWN)
    end, self)
end

function modifier_item_unstable_wand_custom_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusMovespeedPct = self.ability:GetSpecialValueFor("pig_movespeed_bonus_pct")
end


LinkLuaModifier("modifier_item_unstable_wand_custom", "items/neutral_items/unstable_wand", LUA_MODIFIER_MOTION_NONE, modifier_item_unstable_wand_custom)
LinkLuaModifier("modifier_item_unstable_wand_custom_buff", "items/neutral_items/unstable_wand", LUA_MODIFIER_MOTION_NONE, modifier_item_unstable_wand_custom_buff)
