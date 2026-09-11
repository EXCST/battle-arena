-- ============================================================================
-- Battle Arena: Augments — base class for damage shields
-- ============================================================================

require("lib/augments/boons/modifier_augment_base")
modifier_augment_shield_base = modifier_augment_shield_base or class(modifier_augment_base)


function modifier_augment_shield_base:IsHidden() return false end
function modifier_augment_shield_base:DestroyOnExpire() return false end


function modifier_augment_shield_base:OnCreated()
	self.parent = self:GetParent()

	self.shield_capacity = self:ComputeStat("shield_capacity") + self:ComputeStat("shield_capacity_per_level") * self.parent:GetLevel()

	self.combat_cd = self:GetStatFor("flat_combat_cd")
	self.tickrate = self:GetStatFor("flat_tickrate")
	self.illusion_multiplier = self:GetStatFor("flat_illusion_multiplier") / 100.0
	self.regeneration_rate = self:GetStatFor("flat_regeneration_rate") * self.tickrate / 100

	self.current_cd = 0
	self.damaged = false

	self.current_shield = self.shield_capacity

	if IsServer() then
		self:SetHasCustomTransmitterData(true)
		self:StartIntervalThink(self.tickrate)
		self:OnIntervalThink()
	end

	self:RefreshOnLevelGained()
end


function modifier_augment_shield_base:OnRefresh()
	local at_max_capacity = math.abs(self.current_shield - self.shield_capacity) < 1
	local new_capacity = self:ComputeStat("shield_capacity") + self:ComputeStat("shield_capacity_per_level") * self.parent:GetLevel()
	self.shield_capacity = new_capacity

	if not IsServer() then return end

	-- if the capacity was extended while (nearly) maxed, extend the current shield as well
	if at_max_capacity then
		self.current_shield = new_capacity
	end

	self:SendBuffRefreshToClients()
end


function modifier_augment_shield_base:OnIntervalThink()
	if not IsValidEntity(self.parent) then return end

	if self.current_cd <= 0 and self.current_shield < self.shield_capacity then
		local regenerated_shield = self.regeneration_rate * self.shield_capacity
		self.current_shield = math.min(self.current_shield + regenerated_shield, self.shield_capacity)
		self:SendBuffRefreshToClients()
	end

	self.current_cd = math.max(self.current_cd - self.tickrate, 0)

	if self.damaged then
		self.damaged = false
		self:SetDuration(self.current_cd, false)
		self:SendBuffRefreshToClients()
	end
end


function modifier_augment_shield_base:ResetShields()
	local capacity = self:ComputeStat("shield_capacity") + self:ComputeStat("shield_capacity_per_level") * self.parent:GetLevel()
	self.shield_capacity = capacity
	self.current_shield = capacity
	self.current_cd = 0
	self:SetDuration(0, false)
	self:SendBuffRefreshToClients()
end


function modifier_augment_shield_base:HandleShieldDamage(event)
	if not IsServer() then
		if event.report_max then return self.shield_capacity end
		return self.current_shield
	end

	if event.damage <= 0.5 then return 0 end
	if self.current_shield <= 0 then return 0 end
	if IsValidEntity(event.attacker) and event.attacker == self.parent then return 0 end

	local damage = event.damage
	if self.parent:IsIllusion() then damage = damage * self.illusion_multiplier end

	if self.current_shield >= damage then
		self.current_shield = self.current_shield - damage
		self.current_cd = self.combat_cd
		self.damaged = true
		return -damage
	else
		self.current_cd = self.combat_cd
		self.current_shield = 0
		self.damaged = true
		return -self.current_shield
	end
end


function modifier_augment_shield_base:AddCustomTransmitterData()
	return {
		current_shield = self.current_shield,
	}
end


function modifier_augment_shield_base:HandleCustomTransmitterData(data)
	self.current_shield = data.current_shield
end
