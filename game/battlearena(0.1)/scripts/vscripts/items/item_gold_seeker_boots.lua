require('items/generic_datadriven_item')


item_gold_seeker_boots = class({
	GetIntrinsicModifierName = function() return "modifier_item_gold_seeker_boots" end
})
modifier_item_gold_seeker_boots = class({
	IsHidden = function() return true end,
	IsItem = function() return true end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT_UNIQUE
	} end,
	GetModifierMoveSpeedBonus_Constant_Unique = function(self) return self.ms_bonus end
})

function modifier_item_gold_seeker_boots:OnCreated()
	self.ms_bonus = self:GetAbility():GetSpecialValueFor("ms_bonus")

	self.distance_for_gold =self:GetAbility():GetSpecialValueFor("distance_for_gold")
	self.gold_bonus = self:GetAbility():GetSpecialValueFor("gold_bonus")

	self.particle_duration = self:GetAbility():GetSpecialValueFor("particle_duration")

	self.walked_distance = 0
	if(not IsServer()) then
		return
	end
	self.position = self:GetParent():GetAbsOrigin()
	self:StartIntervalThink(0.05)
	self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_item_boots_of_travel_2", nil)
end

function modifier_item_gold_seeker_boots:OnDestroy()
	self:GetCaster():RemoveModifierByName("modifier_item_boots_of_travel_2")
end

function modifier_item_gold_seeker_boots:OnIntervalThink()
	local position = self:GetParent():GetAbsOrigin()
	local distanceMoved = CalculateDistance(self.position, position)
	self.walked_distance = self.walked_distance + distanceMoved
	local complete = self.walked_distance / self.distance_for_gold
	if complete > 1 then
		self:GetCaster():ModifyGoldFiltered(self.gold_bonus, false, DOTA_ModifyGold_AbilityGold)
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_alchemist/alchemist_lasthit_coins.vpcf", PATTACH_ABSORIGIN, self:GetCaster())
		ParticleManager:SetParticleControl(pfx, 0, self:GetCaster():GetAbsOrigin())
		ParticleManager:SetParticleControl(pfx, 1, self:GetCaster():GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(pfx)
		self.walked_distance = 0
	end
	self.position = position
end


LinkLuaModifier("modifier_item_gold_seeker_boots", "items/item_gold_seeker_boots", 0, modifier_item_gold_seeker_boots)
