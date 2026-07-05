require('items/generic_datadriven_item')


item_golean_helm = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_golean_helm"
	end,
})

item_golean_helm_1 = class(item_golean_helm)
item_golean_helm_2 = class(item_golean_helm)
item_golean_helm_3 = class(item_golean_helm)

item_trickster_mask_1 = class(item_golean_helm)
item_trickster_mask_2 = class(item_golean_helm)
item_trickster_mask_3 = class(item_golean_helm)

item_orjony_head_1 = class(item_golean_helm)
item_orjony_head_2 = class(item_golean_helm)
item_orjony_head_3 = class(item_golean_helm)

modifier_item_golean_helm = class({
	IsHidden = function()
		return true
	end,
	IsPurgable = function()
		return false
	end,
	IsPurgeException = function()
		return false
	end,
	RemoveOnDeath = function()
		return false
	end,
	DeclareFunctions = function()
		return
		{
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
		}
	end,
	GetModifierBonusStats_Strength = function(self)
		return self.bonus_str
	end,
})

function modifier_item_golean_helm:GetModifierStatusResistanceStacking()
	return self:GetStackCount() == 1 and self.status_resist_pct or self.night_status_resist_pct
end


function modifier_item_golean_helm:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
	if(not IsServer()) then
		return
	end
	self:OnIntervalThink()
	self:StartIntervalThink(1)
end

function modifier_item_golean_helm:OnIntervalThink()
	if not IsServer() then return end
	if GameRules:IsDaytime() then
		self:SetStackCount(1)
	else
		self:SetStackCount(0)
	end
end

function modifier_item_golean_helm:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability) then
        return
    end

    self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
    self.status_resist_pct = self.ability:GetSpecialValueFor("status_resist_pct")
    self.night_status_resist_pct = self.ability:GetSpecialValueFor("night_status_resist_pct")

	if(not IsServer()) then
		return
	end
end

function modifier_item_golean_helm:AddCustomTransmitterData()
    return
    {
        bonus_str = self.bonus_str,
        status_resist_pct = self.status_resist_pct,
        night_status_resist_pct = self.night_status_resist_pct
    }
end

function modifier_item_golean_helm:HandleCustomTransmitterData(data)
    self.bonus_str = data.bonus_str
    self.status_resist_pct = data.status_resist_pct
    self.night_status_resist_pct = data.night_status_resist_pct
end

LinkLuaModifier("modifier_item_golean_helm", "items/item_golean_helm", LUA_MODIFIER_MOTION_NONE, modifier_item_golean_helm)

