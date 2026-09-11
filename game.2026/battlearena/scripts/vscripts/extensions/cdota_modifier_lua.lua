if IsServer() then
	-- Independent Stacks
	function CDOTA_Modifier_Lua:AddIndependentStack(count, duration, limit, remove_on_expire)
		self.independent_stack_timers = self.independent_stack_timers or {}
		self.current_stack_count = self.current_stack_count or 0

		local stacks_increment = count or 1
		self.current_stack_count = self.current_stack_count + stacks_increment

		local timer_name = Timers:CreateTimer(duration or self:GetRemainingTime(), function(inner_timer_name)
			if not self or self:IsNull() then return end

			self.current_stack_count = self.current_stack_count - stacks_increment

			local new_stack_count = limit and math.min(self.current_stack_count, limit) or self.current_stack_count
			self:SetStackCount(new_stack_count)

			self.independent_stack_timers[inner_timer_name] = nil
			if new_stack_count == 0 and self:GetDuration() == -1 and remove_on_expire then self:Destroy() end
		end)

		self.independent_stack_timers[timer_name] = true

		local new_stack_count = limit and math.min(self.current_stack_count, limit) or self.current_stack_count
		self:SetStackCount(new_stack_count)

		if duration > self:GetRemainingTime() then
			self:SetDuration(duration, true)
		end
	end


	function CDOTA_Modifier_Lua:CancelIndependentStacks()
		for timer_name, _ in pairs(self.independent_stack_timers or {}) do
			Timers:RemoveTimer(timer_name)
			self.independent_stack_timers[timer_name] = nil
		end
		self.current_stack_count = 0
		self:SetStackCount(0)
	end
end

-- shared between server and client
function CDOTA_Modifier_Lua:GetStatFor(stat_name)
	if self.upgrade_values and self.upgrade_values[stat_name] then return self.upgrade_values[stat_name] end

	if not self.aug_name then
		self.aug_name = "aug_" .. self:GetName():gsub("modifier_aug_", "")
	end

	local def = AugmentCatalog.catalog_data[self.aug_name]
	if not def then return nil end

	return (def.stats or {})[stat_name]
end


function CDOTA_Modifier_Lua:GetStatForExplicit(boon_name, stat_name)
	if self.upgrade_values and self.upgrade_values[stat_name] then return self.upgrade_values[stat_name] end

	local def = AugmentCatalog.catalog_data[boon_name]
	if not def then return 0 end

	return (def.stats or {})[stat_name] or 0
end


function CDOTA_Modifier_Lua:GetParentPrimaryAttribute()
	return self:GetParent():GetModifierStackCount("modifier_augment_primary_reader", self:GetParent())
end
