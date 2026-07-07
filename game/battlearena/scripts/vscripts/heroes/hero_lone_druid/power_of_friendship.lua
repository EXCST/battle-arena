
lone_druid_power_of_friendship = class({
	GetIntrinsicModifierName = function() return "modifier_lone_druid_power_of_friendship_aura" end
})

modifier_lone_druid_power_of_friendship_aura = class({
	IsAura = function() return true end,
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	GetAuraSearchTeam = function(self) return self:GetAbility():GetAbilityTargetTeam() end,
	GetAuraSearchType = function(self) return self:GetAbility():GetAbilityTargetType() end,
	GetAuraSearchFlags = function(self) return self:GetAbility():GetAbilityTargetFlags() end,
	GetAuraRadius = function(self) return self:GetAbility():GetSpecialValueFor("range") end,
	GetModifierAura = function() return "modifier_lone_druid_power_of_friendship_buff" end
})

function modifier_lone_druid_power_of_friendship_aura:GetAuraEntityReject(target)
	if (target == self:GetCaster()) or (target:GetOwner() == self:GetCaster()) then
		return false
	else
		return true
	end
end

modifier_lone_druid_power_of_friendship_buff = class({
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE
	} end
})
function modifier_lone_druid_power_of_friendship_buff:IsHidden()
	if(self.parent:PassivesDisabled()) then
		return true
	end
	return self:GetStackCount() ~= 0
end

function modifier_lone_druid_power_of_friendship_buff:OnCreated()
	self.parent = self:GetParent()
	self.range = self:GetAbility():GetSpecialValueFor("range")
	self.damage_bonus = self:GetAbility():GetSpecialValueFor("damage_bonus")
	if IsServer() then
		self:StartIntervalThink(FrameTime())
	end
end

function modifier_lone_druid_power_of_friendship_buff:OnIntervalThink()
	if self:GetCaster().bear then
		if CalculateDistance(self:GetCaster(), self:GetCaster().bear) <= self.range and self:GetCaster().bear and self.parent:PassivesDisabled() == false then
			self:SetStackCount(0)
		else
			self:SetStackCount(1)
		end
	else
		self:SetStackCount(1)
	end
end

function modifier_lone_druid_power_of_friendship_buff:GetModifierDamageOutgoing_Percentage()
	if(self.parent:PassivesDisabled()) then
		return 0
	end
	return self:GetStackCount() == 0 and self.damage_bonus or 0
end


LinkLuaModifier("modifier_lone_druid_power_of_friendship_aura", "abilities/heroes/hero_lone_druid/power_of_friendship", 0, modifier_lone_druid_power_of_friendship_aura)
LinkLuaModifier("modifier_lone_druid_power_of_friendship_buff", "abilities/heroes/hero_lone_druid/power_of_friendship", 0, modifier_lone_druid_power_of_friendship_buff)
