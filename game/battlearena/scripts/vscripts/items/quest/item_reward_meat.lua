
item_reward_meat = class({})

function item_reward_meat:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_item_reward_meat", nil)
	EmitSoundOn("DOTA_Item.Cheese.Activate", caster)
	caster:RemoveItem(self)
end


modifier_item_reward_meat = class({
	IsHidden 				= function(self) return true end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return false end,
	DeclareFunctions		= function(self) return 
		{	MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		} end,
})

function modifier_item_reward_meat:OnCreated()
	self.bonus_value = self:GetAbility():GetSpecialValueFor("bonus_value")
end

function modifier_item_reward_meat:GetModifierBonusStats_Strength()
	return self.bonus_value
end



LinkLuaModifier("modifier_item_reward_meat", "items/quest/item_reward_meat", LUA_MODIFIER_MOTION_NONE, modifier_item_reward_meat)
