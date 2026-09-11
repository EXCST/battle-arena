print("[BATTLEARENA] Loading modifier_doom_litany_cosmetics.lua")
modifier_doom_litany_cosmetics = class({})
function modifier_doom_litany_cosmetics:IsHidden() return true end
function modifier_doom_litany_cosmetics:RemoveOnDeath() return false end
function modifier_doom_litany_cosmetics:IsPurgable() return false end
function modifier_doom_litany_cosmetics:OnCreated()
	if IsClient() then return end
	if IsClient() then return end
	print("[BATTLEARENA] OnCreated called for " .. self:GetParent():GetUnitName())
	local parent = self:GetParent()

	local litanyModels = {
		"models/items/doom/bringer_of_troubles_weapon/bringer_of_troubles_weapon.vmdl",
		"models/items/doom/bringer_of_troubles_head/bringer_of_troubles_head.vmdl",
		"models/items/doom/bringer_of_troubles_shoulder/bringer_of_troubles_shoulder.vmdl",
		"models/items/doom/bringer_of_troubles_back/bringer_of_troubles_back.vmdl",
		"models/items/doom/bringer_of_troubles_belt/bringer_of_troubles_belt.vmdl",
		"models/items/doom/bringer_of_troubles_tail/bringer_of_troubles_tail.vmdl",
		"models/items/doom/bringer_of_troubles_arms/bringer_of_troubles_arms.vmdl",
	}

	for _, child in pairs(parent:GetChildren()) do
		if child:GetClassname() == "dota_item_wearable" then
			child:RemoveSelf()
		end
	end
	local litany = {}
	for _, modelPath in ipairs(litanyModels) do
		local prop = SpawnEntityFromTableSynchronous("prop_dynamic", { model = modelPath, targetname = "" })
		if prop and not prop:IsNull() then
			table.insert(litany, prop)
			prop:FollowEntity(parent, true)
		end
	end
	parent.litanyPieces = litany
end
