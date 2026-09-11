-- ============================================================================
-- Battle Arena: Augments — base class for boon modifiers
-- ============================================================================

modifier_augment_base = class({ bonus = 0 })


function modifier_augment_base:IsHidden() return true end
function modifier_augment_base:IsPurgable() return false end
function modifier_augment_base:RemoveOnDeath() return false end


function modifier_augment_base:RefreshOnLevelGained()
	if not IsServer() then return end

	self.parent = self:GetParent()

	if not self.parent:IsRealHero() or self.parent:IsIllusion() or self.parent:IsClone()
	or self.parent:GetUnitLabel() == "spirit_bear" then
		return
	end

	self.level_gained_listener = ListenToGameEvent("dota_player_gained_level", function(event)
		if self:IsNull() then return end
		if not event.player_id then return end

		local hero = PlayerResource:GetSelectedHeroEntity(event.player_id)
		if IsValidEntity(hero) and hero == self.parent then
			self:ForceRefresh()
		end
	end, self)
end


function modifier_augment_base:OnDestroy()
	if not IsServer() then return end

	if self.level_gained_listener then
		StopListeningToGameEvent(self.level_gained_listener)
		self.level_gained_listener = nil
	end
end


function modifier_augment_base:RefreshStats()
	self.bonus = 0
end


--- Total bonus of one boon stat, applying the per-pick rolled factor.
function modifier_augment_base:ComputeStat(stat_name, multiplier)
	self.bonus_per_upgrade = self:GetStatFor(stat_name)

	local def = AugmentCatalog.catalog_data[self.aug_name]

	local total = AugmentMath:ComputeBonus(self.parent or self:GetParent(), self.bonus_per_upgrade, self:GetStackCount(), def or {})

	-- the per-pick variance granted on pick
	local record
	if IsServer() then
		record = ((self.parent or self:GetParent()).augment_state or {}).generic or {}
		record = record[self.aug_name]
	else
		local store = CustomNetTables:GetTableValue("augment_store", tostring(self:GetParent():GetPlayerOwnerID())) or {}
		record = (store.generic or {})[self.aug_name]
	end

	if record and record.rolled_factor then
		total = total * record.rolled_factor
	end

	total = total * (multiplier or 1)
	self.bonus = total

	return AugmentMath:Round1(total)
end
