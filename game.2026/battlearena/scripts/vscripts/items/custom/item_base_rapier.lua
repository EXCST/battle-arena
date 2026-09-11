require('items/generic_datadriven_item')

item_base_rapier = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_base_rapier"
	end
})

function item_base_rapier:IsRapierDropOnDeath()
	return false
end

function item_base_rapier:ApplyItemContainerEffects(itemContainer)

end

modifier_item_base_rapier = class({
	IsHidden = function()
		return true
	end,
	IsPurgable = function()
		return false
	end,
	IsPermanent = function()
		return true
	end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_EVENT_ON_DEATH
		}
	end,
	GetModifierPreAttack_BonusDamage = function(self)
		return self.bonusDmg
	end,
	GetModifierBonusStats_Strength = function(self)
		return self.bonusStr
	end,
	GetModifierBonusStats_Agility = function(self)
		return self.bonusAgi
	end,
	GetModifierBonusStats_Intellect = function(self)
		return self.bonusInt
	end,
	GetAttributes = function()
		return MODIFIER_ATTRIBUTE_MULTIPLE
	end
})

function modifier_item_base_rapier:OnCreated()
	self.item = self:GetAbility()
	self.bonusDmg = self.item:GetSpecialValueFor("rapier_dmg")
	self.bonusStr = self.item:GetSpecialValueFor("rapier_str")
	self.bonusAgi = self.item:GetSpecialValueFor("rapier_agi")
	self.bonusInt = self.item:GetSpecialValueFor("rapier_int")
	if(not IsServer()) then
		return
	end
	self.parent = self:GetParent()
	self.baseRapierCheckerModifier = self.parent:AddNewModifier(self.parent, self.item, "modifier_item_base_rapier_owner_checker", {duration = -1})
	self:StartIntervalThink(1)
end

function modifier_item_base_rapier:OnIntervalThink()
	if(self.item:IsNull() == true) then
		self:Destroy()
		return
	end
end

function modifier_item_base_rapier:OnRapierAddedToInventory()

end

function modifier_item_base_rapier:OnRapierRemoved()

end

function modifier_item_base_rapier:CheckIfOwnerHaveEnoughStats(owner, item)
	if(owner:IsIllusion() == true) then
		return true
	end
	if(not owner.GetStrength) then
		return false
	end
	local statsRequired = item:GetSpecialValueFor( "stats_required" )
	local statsFromRapier = item:GetSpecialValueFor( "rapier_str" ) + item:GetSpecialValueFor( "rapier_agi" ) + item:GetSpecialValueFor( "rapier_int" )
	local heroStats = owner:GetStrength(true) + owner:GetAgility(true) + owner:GetPrimaryStatValue()
	local heroStatsWithoutRapier =  heroStats - statsFromRapier
	return heroStatsWithoutRapier >= statsRequired, statsRequired-heroStatsWithoutRapier
end

function modifier_item_base_rapier:OnOwnerHaveMoreThanOneRapierType(owner, item)
	self:DropRapier(owner, item)
end

function modifier_item_base_rapier:OnOwnerHaveInsufficientStats(owner, item, insufficientStats)
	self:DropRapier(owner, item)
end

function modifier_item_base_rapier:DropRapier(owner, item)
	self._isRapierDroppedByForce = true
	Timers:CreateTimer(0.1, function() 
		-- 7.31 cause crash if something is null
		if(not owner or owner:IsNull() == true) then
			return
		end
		if(owner:IsTempestDouble() == true or owner:IsIllusion() == true) then
			item:Destroy()
		else
			owner:DropItemAtPositionImmediate(item, owner:GetAbsOrigin())
		end
	end)
end

function modifier_item_base_rapier:OnDestroy()
	if(not IsServer()) then
		return
	end
	if(self.baseRapierCheckerModifier and self.baseRapierCheckerModifier:IsNull() == false) then
		self.baseRapierCheckerModifier:ForceRefresh()
	end
	self:OnRapierRemoved()
	local rapier = self.item
	Timers:CreateTimer(0.15, function() 
		if(rapier and rapier:IsNull() == false) then
			local rapierContainer = rapier:GetContainer()
			if(rapierContainer and rapierContainer:IsNull() == false) then
				rapier:ApplyItemContainerEffects(rapierContainer)
			end
		end
	end)
end

function modifier_item_base_rapier:OnDeath(kv)
	if(not IsServer()) then
		return
	end
	if (kv.unit ~= self.parent) then
		return
	end
	if(self.parent:IsReincarnating() == true) then
		return
	end
	if(self.item:IsRapierDropOnDeath() == false) then
		return
	end
	self:DropRapier(self.parent, self.item)
end

modifier_item_base_rapier_owner_checker = class({
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
	IsPermanent = function()
		return true
	end
})

function modifier_item_base_rapier_owner_checker:OnCreated()
	self.parent = self:GetParent()
	if(not IsServer()) then
		return
	end
	self._allRapiers = self:GetAllRapiersNames()
	self._firstTick = true
	self:StartIntervalThink(0.05)
end

function modifier_item_base_rapier_owner_checker:OnRefresh()
	if(not IsServer()) then
		return
	end
	self:OnIntervalThink()
end

function modifier_item_base_rapier_owner_checker:OnIntervalThink()
	local allRapiers = self:FindAllRapiers()
	if(#allRapiers == 0) then
		self:Destroy()
		return
	end
	for _, rapier in pairs(allRapiers) do
		self:CheckOwner(rapier, allRapiers)
	end
	if(self._firstTick) then
		self:StartIntervalThink(1)
		self._firstTick = nil
	end
end

function modifier_item_base_rapier_owner_checker:GetAllRapiersNames()
	return {
		"modifier_item_item_fire_rapier",
		"modifier_item_earth_rapier",
		"modifier_item_imba_skadi", -- ice rapier
		"modifier_item_wind_rapier",
		"modifier_item_water_rapier",
		"modifier_item_nature_rapier"
	}
end

function modifier_item_base_rapier_owner_checker:FindAllRapiers()
	local result = {}
	for _, rapierName in pairs(self._allRapiers) do
		local rapier = self.parent:FindModifierByName(rapierName)
		if(rapier) then
			table.insert(result, rapier)
		end
	end
	return result
end

function modifier_item_base_rapier_owner_checker:GetCurrentRapiersAmount(allRapiersModifiers)
	local result = 0
	for _, rapierModifier in pairs(allRapiersModifiers) do
		if(not rapierModifier._isRapierDroppedByForce) then
			result = result + 1
		end
	end
	return result
end

function modifier_item_base_rapier_owner_checker:GetMaxRapiersAmount()
	local itemElementalOrb = self.parent:FindModifierByName("modifier_item_elemental_orb")
	if(itemElementalOrb and itemElementalOrb.GetMaxRapiersAmount) then
		return tonumber(itemElementalOrb:GetMaxRapiersAmount()) or 1
	end
	return 1
end

function modifier_item_base_rapier_owner_checker:CheckOwner(rapierModifier, allRapiersModifiers)
	if(not IsServer()) then
		return
	end
	local owner = self.parent
	if(owner:IsTempestDouble() == true) then
		self.parent:RemoveItem(rapierModifier.item)
		return
	end
	local ownerIsValid = owner:IsRealHero()
	if(ownerIsValid == false and owner:IsIllusion() == false) then
		rapierModifier:DropRapier(owner, rapierModifier.item)
		return
	end
	local maxRapiersAmount = self:GetMaxRapiersAmount()
	if(self:GetCurrentRapiersAmount(allRapiersModifiers) > maxRapiersAmount) then
		rapierModifier:OnOwnerHaveMoreThanOneRapierType(owner, rapierModifier.item)
		return
	end
	local ownerHaveEnoughStats, missingOwnerStats = rapierModifier:CheckIfOwnerHaveEnoughStats(owner, rapierModifier.item)
	if(ownerHaveEnoughStats == true) then
		if(not rapierModifier._OnRapierAddedToInventoryEventCalled) then
			rapierModifier:OnRapierAddedToInventory()
			rapierModifier._OnRapierAddedToInventoryEventCalled = true
		end
		return
	end
    rapierModifier:OnOwnerHaveInsufficientStats(owner, rapierModifier.item, missingOwnerStats)
end


LinkLuaModifier("modifier_item_base_rapier", "items/custom/item_base_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_base_rapier)
LinkLuaModifier("modifier_item_base_rapier_owner_checker", "items/custom/item_base_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_base_rapier_owner_checker)
