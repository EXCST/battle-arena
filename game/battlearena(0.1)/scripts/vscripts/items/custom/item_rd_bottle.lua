require('items/generic_datadriven_item')

require("items/custom/item_base_with_optional_unit_target")


item_rd_bottle = class(item_base_with_optional_unit_target)

function item_rd_bottle:GetIntrinsicModifierName()
	return "modifier_item_rd_bottle"
end

function item_rd_bottle:GetAbilityTextureName()
	return
		self:GetCurrentCharges() == 5 and "custom/bottle" or
		self:GetCurrentCharges() == 4 and "custom/bottle" or
		self:GetCurrentCharges() == 3 and "custom/bottle" or
		self:GetCurrentCharges() == 2 and "custom/bottle_medium" or
		self:GetCurrentCharges() == 1 and "custom/bottle_small" or
		self:GetCurrentCharges() == 0 and "custom/bottle_empty"
end

function item_rd_bottle:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget() or caster
	target:AddNewModifier(caster, self, "modifier_item_rd_bottle_buff", {duration = self:GetSpecialValueFor("duration")})
	if self:GetName() == "item_rd_bottle_upgraded" then
		target:AddNewModifier(caster, self, "modifier_item_rd_bottle_damage_buff", {duration = self:GetSpecialValueFor("bonus_damage_duration")})
	end
	EmitSoundOn("Bottle.Drink", target)
	self:SpendCharge()
end

modifier_item_rd_bottle = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	IsPermanent = function() return true end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_EVENT_ON_DEATH
	} end
})

function modifier_item_rd_bottle:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("strength")
end

function modifier_item_rd_bottle:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("agility")
end

function modifier_item_rd_bottle:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("intellect")
end

function modifier_item_rd_bottle:OnCreated()
	self.max_charges = self:GetAbility():GetSpecialValueFor("max_charges")
	self.kill_radius = self:GetAbility():GetSpecialValueFor("kill_radius") or 0
	self.kills_for_charge = self:GetAbility():GetSpecialValueFor("kills_for_charge") or 0
	self.current_kills = 0
	if(IsServer()) then
		self:StartIntervalThink(0.2)
	end
end

function modifier_item_rd_bottle:OnIntervalThink()
	if self:GetCaster():HasModifier("modifier_fountain_regen_aura") then
		if self:GetAbility():GetCurrentCharges() < self.max_charges then
			self:GetAbility():SetCurrentCharges(self:GetAbility():GetCurrentCharges() + 1)
		end
	end
end

function modifier_item_rd_bottle:OnDeath(keys)
	if self:GetAbility():GetName() == "item_rd_bottle_upgraded" then
		if CalculateDistance(self:GetParent(), keys.unit) <= self.kill_radius and keys.unit:GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
			self.current_kills = self.current_kills + 1
			if self.current_kills == self.kills_for_charge then
				if self:GetAbility():GetCurrentCharges() < self.max_charges then
					self:GetAbility():SetCurrentCharges(self:GetAbility():GetCurrentCharges() + 1)
				end
				self.current_kills = 0
			end
		end
	end
end

modifier_item_rd_bottle_buff = class({
	IsPurgable = function() return true end,
	GetEffectName = function() return "particles/items_fx/bottle.vpcf" end,
	GetEffectAttachType = function() return PATTACH_ABSORIGIN_FOLLOW end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
	} end,
	GetModifierConstantManaRegen = function(self) return self.mana_regen end,
	GetModifierConstantHealthRegen = function(self) return self.hp_regen end,
	GetTexture = function(self)
		return self.buffIcon
	end
})

function modifier_item_rd_bottle_buff:OnCreated()
	self.hp_regen = self:GetAbility():GetSpecialValueFor("hp_regen")
	self.mana_regen = self:GetAbility():GetSpecialValueFor("mana_regen")
	if(not IsServer()) then
		self.buffIcon = self:GetAbility():GetAbilityTextureName()
	end
end

modifier_item_rd_bottle_damage_buff = class({
	IsHidden = function() return false end,
	IsPurgable = function() return true end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_TOOLTIP
		}
	end,
	GetModifierTotalDamageOutgoing_Percentage = function(self) return self.damage_bonus_pct end,
	GetTexture = function(self)
		return self.buffIcon
	end
})

function modifier_item_rd_bottle_damage_buff:OnCreated()
	self.damage_bonus_pct = self:GetAbility():GetSpecialValueFor("damage_bonus_pct")
	if(IsClient()) then
		self.buffIcon = self:GetAbility():GetAbilityTextureName()
	end
end

function modifier_item_rd_bottle_damage_buff:OnTooltip()
	return self.damage_bonus_pct
end

item_rd_bottle_upgraded = class(item_rd_bottle)

function item_rd_bottle_upgraded:GetAbilityTextureName()
	return self:GetCurrentCharges() > 0 and "support/goblet_full" or "support/goblet_empty"
end


LinkLuaModifier("modifier_item_rd_bottle", "items/custom/item_rd_bottle", LUA_MODIFIER_MOTION_NONE, modifier_item_rd_bottle)
LinkLuaModifier("modifier_item_rd_bottle_buff", "items/custom/item_rd_bottle", LUA_MODIFIER_MOTION_NONE, modifier_item_rd_bottle_buff)
LinkLuaModifier("modifier_item_rd_bottle_damage_buff", "items/custom/item_rd_bottle", LUA_MODIFIER_MOTION_NONE, modifier_item_rd_bottle_damage_buff)
