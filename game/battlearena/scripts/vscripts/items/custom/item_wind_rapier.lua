require('items/generic_datadriven_item')

require('items/custom/item_base_rapier')

item_wind_rapier = class(item_base_rapier)

function item_wind_rapier:GetIntrinsicModifierName()
	return "modifier_item_wind_rapier"
end

function item_wind_rapier:ApplyItemContainerEffects(itemContainer)
	itemContainer:SetRenderColor(192, 192, 192)
end

function item_wind_rapier:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_item_wind_rapier_buff" , {duration = self:GetSpecialValueFor("buff_duration") })
end

modifier_item_wind_rapier = class(modifier_item_base_rapier)

function modifier_item_wind_rapier:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end
	
function modifier_item_wind_rapier:GetModifierMoveSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("rapier_ms")
end

function modifier_item_wind_rapier:GetEffectName()
	return "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf"
end

function modifier_item_wind_rapier:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_wind_rapier:OnOwnerHaveMoreThanOneRapierType(owner, item)
	GameRules:SendCustomMessage("#Game_notification_wind_rapier_request_message1",0,0)
	self:DropRapier(owner, item)
end

function modifier_item_wind_rapier:OnOwnerHaveInsufficientStats(owner, item, insufficientStats)
	GameRules:SendCustomMessage("#Game_notification_wind_rapier_request_message",0,0)	
	GameRules:SendCustomMessage("<font color='#FFD700'>MISSING ATTRIBUTES: </font><font color='#C0C0C0'>".. insufficientStats .."</font>",0,0)
	self:DropRapier(owner, item)
end

function modifier_item_wind_rapier:OnRapierAddedToInventory()
	self.parent = self:GetParent()
	self.item = self:GetAbility()
	self.maxStacks = self.item:GetSpecialValueFor("stack_max")
	self.procChance = self.item:GetSpecialValueFor("proc_chance")
	self.buffDuration = self.item:GetSpecialValueFor("stack_duration")
end

function modifier_item_wind_rapier:OnAttackLanded(kv)
	if(kv.attacker ~= self.parent) then
		return
	end
	if(RollPseudoRandom(self.procChance, self.item) == false) then
		return
	end
	local windModifier = self.parent:AddNewModifier(self.parent, self.item, "modifier_item_wind_rapier_stacks" , {duration = self.buffDuration })
	if(windModifier) then
		local stacks = windModifier:GetStackCount() + 1
		windModifier:SetStackCount(math.min(stacks, self.maxStacks))
		windModifier:ForceRefresh()
	end
end

modifier_item_wind_rapier_buff = class({
	IsHidden = function()
		return false
	end,
	IsPurgable = function()
		return true
	end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_ROSHDEF_EVASION_CONSTANT
		}
	end,
	GetModifierMoveSpeedBonus_Percentage = function(self)
		return self:GetAbility():GetSpecialValueFor("buff_ms")
	end,
	GetModifierEvasion_Constant = function(self)
		return self:GetAbility():GetSpecialValueFor("buff_evasion")
	end,
	GetEffectName = function()
		return "particles/econ/courier/courier_greevil_yellow/courier_greevil_yellow_ambient_3.vpcf"
	end,
	GetEffectAttachType = function()
		return PATTACH_ABSORIGIN_FOLLOW
	end
})

modifier_item_wind_rapier_stacks = class({
	IsHidden = function()
		return false
	end,
	IsPurgable = function()
		return true
	end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_TOOLTIP 
		}
	end,
	OnTooltip = function(self)
		return self:GetModifierBonusStats_Agility_Percentage()
	end
})

function modifier_item_wind_rapier_stacks:OnCreated()
	local parent = self:GetParent()
	self.bonusAgilityPctPerStack = self:GetAbility():GetSpecialValueFor("proc_bonus")
end

function modifier_item_wind_rapier_stacks:GetModifierBonusStats_Agility_Percentage()
	return self:GetStackCount() * self.bonusAgilityPctPerStack
end

item_wind_rapier_1 = class(item_wind_rapier)
item_wind_rapier_2 = class(item_wind_rapier)
item_wind_rapier_3 = class(item_wind_rapier)
item_wind_rapier_4 = class(item_wind_rapier)

LinkLuaModifier("modifier_item_wind_rapier", "items/custom/item_wind_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_wind_rapier)
LinkLuaModifier("modifier_item_wind_rapier_stacks", "items/custom/item_wind_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_wind_rapier_stacks)
LinkLuaModifier("modifier_item_wind_rapier_buff", "items/custom/item_wind_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_wind_rapier_buff)
