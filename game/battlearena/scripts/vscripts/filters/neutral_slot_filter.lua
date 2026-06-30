NeutralSlotFilter = {}
NeutralSlot = {}

local NEUTRAL_SLOT_INDEX = 16

function NeutralSlot:_init()
    local kv = LoadKeyValues("scripts/npc/neutral_slot_items.txt")
    self.kv_data = kv
    if kv and kv.root then
        self.kv_data = kv.root
    end
end

function NeutralSlot:NeedToNeutralSlot(item_name)
    return self.kv_data[item_name] ~= nil
end

function NeutralSlot:GetSlotIndex()
    return NEUTRAL_SLOT_INDEX
end

NeutralSlot:_init()

function NeutralSlotFilter:ItemAddedToInventoryFilter(event)

	if not event.item_entindex_const then return true end
	if not event.inventory_parent_entindex_const then return true end
	local hItem = EntIndexToHScript(event.item_entindex_const)

	if not hItem or hItem:IsNull() then return true end

	local hUnit = EntIndexToHScript(event.inventory_parent_entindex_const)
	if not hUnit then return true end
	if hUnit:IsNull() then return true end
	if not hUnit:IsRealHero() then return true end
	
	if NeutralSlot:NeedToNeutralSlot( hItem:GetName() ) then
		local slotIndex = NeutralSlot:GetSlotIndex()
		if not slotIndex then return true end
		local itemInSlot = hUnit:GetItemInSlot(slotIndex)

		if not itemInSlot then
			-- just practical heuristic, when hero take item from another unit/from ground event.item_parent_entindex_const != event.inventory_parent_entindex_const
			-- never ask me about this dirty hack.
			local isStash = event.item_parent_entindex_const == event.inventory_parent_entindex_const

			if not isStash or hUnit:IsInRangeOfShop(DOTA_SHOP_HOME, true) then
				event.suggested_slot = NeutralSlot:GetSlotIndex()
			end
		end
	end

	return true
end

function NeutralSlotFilter:ExecuteOrderFilter( event )

	if (event.order_type == DOTA_UNIT_ORDER_MOVE_ITEM) then
			local unit = EntIndexToHScript(event.units["0"])
			if not unit then return true end
			if not unit:IsRealHero() then return true end
			local item = EntIndexToHScript(event.entindex_ability)
			if not item then return true end
			local slot = item:GetItemSlot()
			
			local neutral_item = unit:GetItemInSlot(NEUTRAL_SLOT_INDEX)
			if not neutral_item or (event.entindex_target == NEUTRAL_SLOT_INDEX) and neutral_item:GetAbilityName() ~= 'item_golden_lock' then
				unit:SwapItems(slot, NEUTRAL_SLOT_INDEX)
				return true
			end
			if (slot == NEUTRAL_SLOT_INDEX) and item:GetAbilityName() ~= 'item_golden_lock' and event.entindex_target ~= DOTA_ITEM_TP_SCROLL then
				unit:SwapItems(event.entindex_target, NEUTRAL_SLOT_INDEX)
				return true
			end
	end
	return true
end