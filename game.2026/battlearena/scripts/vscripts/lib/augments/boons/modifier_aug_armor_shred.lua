require("lib/augments/boons/modifier_augment_base")
modifier_aug_armor_shred = class(modifier_augment_base)


LinkLuaModifier("modifier_augment_armor_shred_marker", "lib/augments/boons/modifier_aug_armor_shred", LUA_MODIFIER_MOTION_NONE)


function modifier_aug_armor_shred:RefreshStats()
	self.armor_shred = self:ComputeStat("armor_shred")
	self.armor_shred_per_level = self:ComputeStat("armor_shred_per_level")

	self.duration = self:GetStatFor("flat_duration")
end


function modifier_aug_armor_shred:OnCreated()
	self:RefreshStats()
end


function modifier_aug_armor_shred:OnRefresh(old_stack_count)
	self:RefreshStats()
end


function modifier_aug_armor_shred:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK, -- GetModifierProcAttack_Feedback
	}
end


function modifier_aug_armor_shred:GetModifierProcAttack_Feedback(params)
	local target = params.target
	if not IsValidEntity(target) then return end

	local parent = self:GetParent()
	if not IsValidEntity(parent) then return end

	local modifier_owner = parent

	if parent:IsIllusion() or parent:IsMonkeyKingSoldier() or parent:IsClone() then
		modifier_owner = PlayerResource:GetSelectedHeroEntity(parent:GetPlayerOwnerID())
	end

	if not IsValidEntity(modifier_owner) then return end

	-- this allows to have multiple armor shreds from different heroes, one instance per hero
	local existing_modifier = target:FindModifierByNameAndCaster("modifier_augment_armor_shred_marker", modifier_owner)

	if not existing_modifier or existing_modifier:IsNull() then
		existing_modifier = target:AddNewModifier(modifier_owner, nil, "modifier_augment_armor_shred_marker", {duration = self.duration})
	end

	-- double checking because modifier application may fail - due to target being invulnerable, dead or w/e
	if not existing_modifier or existing_modifier:IsNull() then return end
	local new_armor_reduction = self.armor_shred + self.armor_shred_per_level * modifier_owner:GetLevel()
	if existing_modifier.armor_reduction == 0 or existing_modifier.armor_reduction < new_armor_reduction then
		existing_modifier.armor_reduction = new_armor_reduction
		existing_modifier:SetStackCount(-new_armor_reduction)
	end
end


-- purgable and visible
modifier_augment_armor_shred_marker = modifier_augment_armor_shred_marker or class({})

function modifier_augment_armor_shred_marker:GetTexture() return "../items/desolator" end
function modifier_augment_armor_shred_marker:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end


function modifier_augment_armor_shred_marker:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- GetModifierPhysicalArmorBonus
	}
end


function modifier_augment_armor_shred_marker:GetModifierPhysicalArmorBonus()
	return -self:GetStackCount()
end


-- play sound when disarmor is applied (doesn't play again if instance is refreshed, but does play for any other instance from other heroes)
function modifier_augment_armor_shred_marker:OnCreated()
	local parent = self:GetParent()

	if not IsValidEntity(parent) then return end

	if not IsServer() then return end
	EmitSoundOnEntityForPlayer("Item_Desolator.Target", parent, self:GetCaster():GetPlayerOwnerID())
end


