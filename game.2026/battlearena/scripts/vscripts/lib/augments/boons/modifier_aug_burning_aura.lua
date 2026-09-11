require("lib/augments/boons/modifier_augment_base")
modifier_aug_burning_aura = modifier_aug_burning_aura or class(modifier_augment_base)


-- made visible to give other players a hint
function modifier_aug_burning_aura:IsHidden() return false end
function modifier_aug_burning_aura:GetTexture() return "../items/radiance" end


function modifier_aug_burning_aura:GetEffectName()
	return "particles/econ/events/fall_2022/radiance/radiance_owner_fall2022.vpcf"
end


function modifier_aug_burning_aura:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end


function modifier_aug_burning_aura:RefreshStats()
	self.burn_damage = self:ComputeStat("burn_damage")

	self.burn_interval = self:GetStatFor("flat_burn_interval")
	self.burn_radius = self:GetStatFor("flat_burn_radius")
	self.burn_stat_multiplier = self:ComputeStat("burn_stat_pct") / 100.0

	if IsServer() then
		self.damage_table = {
			victim = nil,
			attacker = self:GetParent(),
			ability = self.internal_item,
			damage = self.burn_damage,
			damage_type = DAMAGE_TYPE_MAGICAL
		}
	end
end


function modifier_aug_burning_aura:OnCreated()
	self:RefreshStats()

	if IsServer() then
		if not self.internal_item then
			self.internal_item = CreateItem("item_burning_aura_source", self:GetParent(), nil)
			self.damage_table.ability = self.internal_item
		end

		self:StartIntervalThink(self.burn_interval)
	end
end


function modifier_aug_burning_aura:OnDestroy()
	if not IsServer() then return end
	if IsValidEntity(self.internal_item) then
		self.internal_item:RemoveSelf()
		self.internal_item = nil
	end
end


function modifier_aug_burning_aura:OnRefresh(old_stack_count)
	self:RefreshStats()
end


function modifier_aug_burning_aura:OnIntervalThink()
	local parent = self:GetParent()
	if not IsValidEntity(parent) or not parent:IsAlive() then return end

	local enemies = FindUnitsInRadius(
		parent:GetTeamNumber(),
		parent:GetAbsOrigin(),
		nil,
		self.burn_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	local burn_from_stats = 0

	if parent.GetPrimaryStatValue and parent.GetPrimaryAttribute then
		local main_stat = parent:GetPrimaryStatValue()
		if parent:GetPrimaryAttribute() == DOTA_ATTRIBUTE_ALL then main_stat = main_stat / 3.0 end
		burn_from_stats = main_stat * self.burn_stat_multiplier
	end

	self.damage_table.damage = self.burn_damage + burn_from_stats

	for _, enemy in pairs(enemies or {}) do
		if IsValidEntity(enemy) then
			self.damage_table.victim = enemy
			ApplyDamage(self.damage_table)
		end
	end
end


function modifier_aug_burning_aura:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOOLTIP,
	}
end


function modifier_aug_burning_aura:OnTooltip()
	return self.burn_damage
end
