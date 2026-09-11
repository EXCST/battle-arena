item_null_talisman = class({})

function item_null_talisman:GetIntrinsicModifierName()
	return "modifier_item_null_talisman_custom"
end

modifier_item_null_talisman_custom = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}end,
})

function modifier_item_null_talisman_custom:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	if(not self.ability) then
		self:Destroy()
		return
	end
	self.multiplier = 1
	self.upgrade_time = nil
	local clock_time = self.ability:GetSpecialValueFor("clock_time")
	if(clock_time and clock_time > 0) then
		self.upgrade_time = clock_time * 60
	end
	self:OnRefresh()
end

function modifier_item_null_talisman_custom:OnRefresh()
	self.ability = self:GetAbility() or self.ability
	if(not self.ability or self.ability:IsNull() == true) then
		return
	end
	self:RecomputeBonus()
	self:CheckUpgrade()
end

function modifier_item_null_talisman_custom:RecomputeBonus()
	self.bonus_str = self.ability:GetSpecialValueFor("bonus_strength") * self.multiplier
	self.bonus_agi = self.ability:GetSpecialValueFor("bonus_agility") * self.multiplier
	self.bonus_int = self.ability:GetSpecialValueFor("bonus_intellect") * self.multiplier
	self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mana_regen") * self.multiplier
end

function modifier_item_null_talisman_custom:CheckUpgrade()
	if(not self.upgrade_time) then
		self:StartIntervalThink(-1)
		return
	end
	local game_time = GameRules:GetDOTATime(false, false)
	if(game_time >= self.upgrade_time) then
		if(self.multiplier ~= 2) then
			self.multiplier = 2
			self:RecomputeBonus()
		end
		self:StartIntervalThink(-1)
	else
		self:StartIntervalThink(math.max(0.5, math.min(1.0, self.upgrade_time - game_time)))
	end
end

function modifier_item_null_talisman_custom:OnIntervalThink()
	self:CheckUpgrade()
end

function modifier_item_null_talisman_custom:GetModifierBonusStats_Strength()
	return self.bonus_str
end

function modifier_item_null_talisman_custom:GetModifierBonusStats_Agility()
	return self.bonus_agi
end

function modifier_item_null_talisman_custom:GetModifierBonusStats_Intellect()
	return self.bonus_int
end

function modifier_item_null_talisman_custom:GetModifierConstantManaRegen()
	return self.bonus_mp_regen
end

LinkLuaModifier("modifier_item_null_talisman_custom", "items/item_null_talisman_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_null_talisman_custom)
