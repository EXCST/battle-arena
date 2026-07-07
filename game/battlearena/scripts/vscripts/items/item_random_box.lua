local items_list = {
	[1] = {
		"item_base_str_1",
		"item_base_agi_1",
		"item_base_int_1",
		"item_base_allstats_1",
		"item_base_damage_1",
		"item_base_attack_speed_1",
		"item_base_armor_1",
		"item_base_health_1",
		"item_base_hp_regen_1",
		"item_base_mana_1",
		"item_base_mp_regen_1",
	},
	[2] = {
		"item_base_str_2",
		"item_base_agi_2",
		"item_base_int_2",
		"item_base_allstats_2",
		"item_base_damage_2",
		"item_base_attack_speed_2",
		"item_base_armor_2",
		"item_base_health_2",
		"item_base_hp_regen_2",
		"item_base_mana_2",
		"item_base_mp_regen_2",
	},
	[3] = {
		"item_base_str_3",
		"item_base_agi_3",
		"item_base_int_3",
		"item_base_allstats_3",
		"item_base_damage_3",
		"item_base_attack_speed_3",
		"item_base_armor_3",
		"item_base_health_3",
		"item_base_hp_regen_3",
		"item_base_mana_3",
		"item_base_mp_regen_3",
	},
	[4] = {
		"item_base_str_4",
		"item_base_agi_4",
		"item_base_int_4",
		"item_base_allstats_4",
		"item_base_damage_4",
		"item_base_attack_speed_4",
		"item_base_armor_4",
		"item_base_health_4",
		"item_base_hp_regen_4",
		"item_base_mana_4",
		"item_base_mp_regen_4",
	},

}

item_random_box = class{}

function item_random_box:OnSpellStart()
	local hCaster = self:GetCaster()
	local nPlayer = hCaster:GetPlayerOwnerID()
	local chance_tier_1 = self:GetSpecialValueFor('chance_tier_1')
	local chance_tier_2 = self:GetSpecialValueFor('chance_tier_2')
	local chance_tier_3 = self:GetSpecialValueFor('chance_tier_3')
	local chance_tier_4 = self:GetSpecialValueFor('chance_tier_4')
	local scope_tier_1 = chance_tier_1
	local scope_tier_2 = scope_tier_1 + chance_tier_2
	local scope_tier_3 = scope_tier_2 + chance_tier_3
	local scope_tier_4 = scope_tier_3 + chance_tier_4
	local random_int = RandomInt(1, 100)

	if random_int <= scope_tier_1 then
		self:RollItem(1)
	elseif random_int <= scope_tier_2 then
		self:RollItem(2)
	elseif random_int <= scope_tier_3 then
		self:RollItem(3)
	elseif random_int <= scope_tier_4 then
		self:RollItem(4)
	end

	self:SpendCharge()
end

function item_random_box:RollItem( item_tier )
	local caster = self:GetCaster()
	items = items_list[item_tier]
	item_name = items[RandomInt(1, #items)]

	caster:EmitSound("Item.RandomBox.Cast")
--	caster:AddItemByName(item_name)
	local spawnPoint = caster:GetAbsOrigin()	
	local newItem = CreateItem( item_name, nil, nil )
	local drop = CreateItemOnPositionForLaunch( spawnPoint, newItem )
	local dropRadius = RandomFloat( 50, 100 )
	newItem:LaunchLootInitialHeight( false, 0, 150, 0.5, spawnPoint + RandomVector( dropRadius ) )

	newItem:SetPurchaseTime(0)
end

item_random_box_1 = class(item_random_box)
item_random_box_2 = class(item_random_box)
item_random_box_3 = class(item_random_box)
item_random_box_4 = class(item_random_box)
item_random_box_5 = class(item_random_box)