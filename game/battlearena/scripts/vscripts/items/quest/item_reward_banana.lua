
item_reward_banana = class({})

function item_reward_banana:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_item_reward_banana", nil)
	EmitSoundOn("DOTA_Item.Cheese.Activate", caster)
	caster:RemoveItem(self)
end


modifier_item_reward_banana = class({
	IsHidden 				= function(self) return true end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return false end,
	DeclareFunctions		= function(self) return 
		{	MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		} end,
})

function modifier_item_reward_banana:OnCreated()
	self.bonus_value = self:GetAbility():GetSpecialValueFor("bonus_value")
end

function modifier_item_reward_banana:GetModifierBonusStats_Intellect()
	return self.bonus_value
end


LinkLuaModifier("modifier_item_reward_banana", "items/quest/item_reward_banana", LUA_MODIFIER_MOTION_NONE, modifier_item_reward_banana)
