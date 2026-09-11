require('items/generic_datadriven_item')

item_base_that_require_stats = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_base_that_require_stats"
    end
})

function item_base_that_require_stats:GetStatsFromThisItem()
    return 0
end

function item_base_that_require_stats:GetRequiredStats()
    return 0
end

modifier_item_base_that_require_stats = class({
	IsHidden = function()
		return true
	end,
	IsPurgable = function()
		return false
	end,
    IsPurgeException = function()
		return false
	end,
	IsPermanent = function()
		return true
	end,
    RemoveOnDeath = function()
        return false
    end,
	GetAttributes = function()
		return MODIFIER_ATTRIBUTE_MULTIPLE
	end
})

function modifier_item_base_that_require_stats:OnCreated()
    self._parent = self:GetParent()
	self._item = self:GetAbility()
    self:OnRefresh()
    if self._parent:IsIllusion() then
        -- without it will be crashed, when you pick up illusion
        return
    end
    if(not IsServer()) then
        return
    end
    self:OnItemAdded(self._parent, self._item)
    self:OnIntervalThink()
	self:StartIntervalThink(1)
end

function modifier_item_base_that_require_stats:OnRefresh()
    self._item = self._item or self:GetAbility()
	if(not self._item or self._item:IsNull()) then
        return
    end
    self:OnItemRefreshed(self._parent, self._item)
end

function modifier_item_base_that_require_stats:OnItemRefreshed(owner, item)

end

function modifier_item_base_that_require_stats:OnItemAdded(owner, item)

end

function modifier_item_base_that_require_stats:OnItemRemoved(owner, item)

end

function modifier_item_base_that_require_stats:OnIntervalThink()
    if(self._parent.GetStrength == nil) then
        self:DropOnGround()
        return
    end
    local sum = self._parent:GetStrength(true) + self._parent:GetAgility(true) + self._parent:GetPrimaryStatValue()
    local missingStats = self._item:GetRequiredStats() - (sum - self._item:GetStatsFromThisItem())
    if(self._item:GetRequiredStats() > (sum - self._item:GetStatsFromThisItem())) then
        self:OnItemOwnerStatsNotEnough(self._parent, self._item, missingStats)
        self:DropOnGround()
    end
end

function modifier_item_base_that_require_stats:OnDestroy()
    if(not IsServer()) then
        return
    end
    self:OnItemRemoved(self._parent, self._item)
end

function modifier_item_base_that_require_stats:DropOnGround()
    Timers:CreateTimer(0.1, function() 
		if(not self._parent or self._parent:IsNull() == true) then
			return
		end
		if(self._parent:IsTempestDouble() == true or self._parent:IsIllusion() == true) then
			self._item:Destroy()
		else
			self._parent:DropItemAtPositionImmediate(self._item, self._parent:GetAbsOrigin())
		end
	end)
end

function modifier_item_base_that_require_stats:OnItemOwnerStatsNotEnough(owner, item, missingStats)

end