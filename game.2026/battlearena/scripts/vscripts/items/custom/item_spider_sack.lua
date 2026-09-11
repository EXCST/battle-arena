require('items/generic_datadriven_item')


item_spider_sack = class({})

function item_spider_sack:GetIntrinsicModifierName()
	return "modifier_item_spider_sack"
end
modifier_item_spider_sack = class({
	IsHidden 				= function(self) return true end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return true end,
})

function modifier_item_spider_sack:OnCreated()
	if(not IsServer()) then
		return
	end
	self:StartIntervalThink(0.25)
end

function modifier_item_spider_sack:OnIntervalThink()
	local caster = self:GetCaster()
	local item = self:GetAbility()
	local current_charges = item:GetCurrentCharges()
	local required_charges = item:GetSpecialValueFor("sack_required")
	if current_charges >= required_charges then
		caster:RemoveItem(item)
		caster:AddItemByName("item_spider_cocoon")
	end
end




LinkLuaModifier("modifier_item_spider_sack", "items/custom/item_spider_sack", LUA_MODIFIER_MOTION_NONE, modifier_item_spider_sack)
