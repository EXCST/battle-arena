require('items/generic_datadriven_item')

item_scout_boots = class({
    GetIntrinsicModifierName = function() 
        return "modifier_item_scout_boots" 
    end
})

modifier_item_scout_boots = class({
	IsHidden = function() 
		return true 
	end,
	IsPurgable = function()
		return false
	end,
	IsPurgeException = function()
		return false
	end,
    DeclareFunctions = function() 
        return 
        {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT_UNIQUE,
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
        } 
    end,
    GetModifierMoveSpeedBonus_Constant_Unique = function(self) 
        return self.ms_bonus 
    end,
    GetModifierBonusStats_Strength = function(self) 
        return self.str_bonus 
    end,
    GetModifierBonusStats_Agility = function(self) 
        return self.agi_bonus 
    end,
    GetModifierBonusStats_Intellect = function(self) 
        return self.int_bonus 
    end,
    GetAttributes = function()
        return MODIFIER_ATTRIBUTE_MULTIPLE
    end
})

function modifier_item_scout_boots:OnCreated()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self:OnRefresh()

end

function modifier_item_scout_boots:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.ms_bonus = self.ability:GetSpecialValueFor("ms_bonus")
    self.str_bonus = self.ability:GetSpecialValueFor("str_bonus")
    self.agi_bonus = self.ability:GetSpecialValueFor("agi_bonus")
    self.int_bonus = self.ability:GetSpecialValueFor("int_bonus")
    if(not IsServer()) then
        return
    end
    self.buffModifier = self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_scout_boots_buff", {duration = -1})
    if self.ability:GetLevel() == 3 then
        self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_boots_of_travel", nil)
    elseif self.ability:GetLevel() > 3 then
        self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_boots_of_travel_2", nil)
    end
end

function modifier_item_scout_boots:OnDestroy()
    if self.ability:GetLevel() == 3 then
        self.parent:RemoveModifierByName("modifier_item_boots_of_travel")
    elseif self.ability:GetLevel() > 3 then
        self.parent:RemoveModifierByName("modifier_item_boots_of_travel_2")
    end
end

modifier_item_scout_boots_buff = class({
    IsHidden = function(self)
        return not self.parent:HasModifier("modifier_item_scout_boots") or true
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
    RemoveOnDeath = function()
        return false
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT
        }
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_scout_boots_buff:OnCreated()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.walked_distance = 0
    self.position = self.parent:GetAbsOrigin()
    self:OnRefresh()
end

function modifier_item_scout_boots_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonusMovementSpeedPerStack = self.ability:GetSpecialValueFor("ms_per_stack")
    self.distance_for_stack = self.ability:GetSpecialValueFor("distance_for_stack")
    self.max_stacks = self.ability:GetSpecialValueFor("max_stacks")
    self.stack_interval = self.ability:GetSpecialValueFor("stack_interval")
 
    if(IsServer()) then
        self:StartIntervalThink(self.stack_interval)
    end

    if(IsClient()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    end
end

function modifier_item_scout_boots_buff:OnIntervalThink()
    if(self.parent:HasModifier("modifier_item_scout_boots") == false) then
        return
    end
    
    if self:GetStackCount() < self.max_stacks then
        self:SetStackCount(math.min(self:GetStackCount()+1, self.max_stacks))
    end
end
--[[
function modifier_item_scout_boots_buff:OnIntervalThink()
    if(self.parent:HasModifier("modifier_item_scout_boots") == false) then
        return
    end
    local position = self:GetParent():GetAbsOrigin()
    local distanceMoved = CalculateDistance(self.position, position)
    self.walked_distance = self.walked_distance + distanceMoved
    local complete = self.walked_distance / self.distance_for_stack
    if complete >= 1 then
        if self:GetStackCount() < self.max_stacks then
            self:SetStackCount(math.min(self:GetStackCount()+1, self.max_stacks))
        end
        self.walked_distance = 0
    end
    self.position = position
end]]

function modifier_item_scout_boots_buff:GetModifierMoveSpeedBonus_Constant()
    if(self.parent:HasModifier("modifier_item_scout_boots") == false) then
        return 0
    end
    return self:GetStackCount() * self.bonusMovementSpeedPerStack
end

item_scout_boots_1 = class(item_scout_boots)
item_scout_boots_2 = class(item_scout_boots)
item_scout_boots_3 = class(item_scout_boots)
item_scout_boots_4 = class(item_scout_boots)

--[[
function item_scout_boots_3:OnSpellStart()
    if(not IsServer()) then
        return
    end
    BeginTeleport(self:GetCaster(), self)
end

function item_scout_boots_3:OnChannelFinish(bInterrupted)
    if(not IsServer()) then
        return
    end
    EndTeleport(self:GetCaster(), bInterrupted)
end]]


LinkLuaModifier("modifier_item_scout_boots", "items/item_scout_boots", LUA_MODIFIER_MOTION_NONE, modifier_item_scout_boots)
LinkLuaModifier("modifier_item_scout_boots_buff", "items/item_scout_boots", LUA_MODIFIER_MOTION_NONE, modifier_item_scout_boots_buff)
