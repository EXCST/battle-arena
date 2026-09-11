require('items/generic_datadriven_item')


item_error = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_error_custom"
    end
})

modifier_item_error_custom = class({
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
		return {
            MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
            MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
		}
	end
})

function modifier_item_error_custom:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()
	self:RefreshAllItemStats()
end

function modifier_item_error_custom:OnRefresh()
	self.ability = self:GetAbility() or self.ability
	if(not self.ability) then
		return
	end
	self.bonusStatsFromItems = (1 + (self.ability:GetSpecialValueFor("bonus_stats_from_items_pct") / 100))
	self.bonusStr = self.ability:GetSpecialValueFor("bonus_str")
	self.bonusAgi = self.ability:GetSpecialValueFor("bonus_agi")
	self.bonusInt = self.ability:GetSpecialValueFor("bonus_int")
	self.bonusATK = self.ability:GetSpecialValueFor("bonus_atk")
	self.bonusAmp = self.ability:GetSpecialValueFor("bonus_amp")
end

function modifier_item_error_custom:GetModifierBonusStats_Strength()
	return self.bonusStr
end

function modifier_item_error_custom:GetModifierBonusStats_Agility()
	return self.bonusAgi
end

function modifier_item_error_custom:GetModifierBonusStats_Intellect()
	return self.bonusInt
end

function modifier_item_error_custom:GetModifierPreAttack_BonusDamage()
	return self.bonusATK
end

function modifier_item_error_custom:GetModifierSpellAmplify_Percentage()
	return self.bonusAmp
end

function modifier_item_error_custom:GetModifierOverrideAbilitySpecial(params)
	if (self:GetParent() == nil or params.ability == nil) then
		return 0
	end
	local szAbilityName = params.ability:GetAbilityName()
	local szSpecialValueName = params.ability_special_value
	if (szAbilityName == nil or szSpecialValueName == nil) then
		return 0
	end
	if(params.ability == self.ability) then
		return 0
	end
    local bIsItemAbility = params.ability:IsItem()
	if (bIsItemAbility == true) then
		return 1
	end
	return 0
end

function modifier_item_error_custom:GetModifierOverrideAbilitySpecialValue(params)
    local hAbility = params.ability
	if(hAbility == self.ability) then
		return 0
	end
	local szSpecialValueName = params.ability_special_value
    local nSpecialValueLevel = params.ability_special_level
	local nBaseSpecialValue = hAbility:GetLevelSpecialValueNoOverride(szSpecialValueName, nSpecialValueLevel)
	-- ?? how
	if(szSpecialValueName == "AbilityManaCost" or szSpecialValueName == "AbilityCharges" or szSpecialValueName == "AbilityCooldown") then
		return nBaseSpecialValue
	end
	return nBaseSpecialValue * self.bonusStatsFromItems
end

function modifier_item_error_custom:RefreshAllItemStats()
	if(not IsServer()) then
		return
	end
	if(self.parent._itemErrorRefreshTimer) then
		Timers:RemoveTimer(self.parent._itemErrorRefreshTimer)
	end
	self.parent._itemErrorRefreshTimer = Timers:CreateTimer(0.05, function()
		local ACTIVE_INVENTORY_SLOTS = 6
		for i=0, ACTIVE_INVENTORY_SLOTS - 1 do
			local itemInInventory = self.parent:GetItemInSlot(i)
			if(itemInInventory and itemInInventory:IsNull() == false) then
				itemInInventory:RefreshIntrinsicModifier()
			end
		end
		local neutralItem = self.parent:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
		if(neutralItem and neutralItem:IsNull() == false) then
			neutralItem:RefreshIntrinsicModifier()
		end
		self.parent:CalculateGenericBonuses()
		self.parent:CalculateStatBonus(true)
		local modifiers = self.parent:FindAllModifiers()
		for _, modifier in pairs(modifiers) do
			modifier:ForceRefresh()
		end
	end, self)
end

function modifier_item_error_custom:OnDestroy()
	if(not IsServer()) then
		return
	end
	self:RefreshAllItemStats()
end


LinkLuaModifier("modifier_item_error_custom", "items/custom/item_error", LUA_MODIFIER_MOTION_NONE, modifier_item_error_custom)
