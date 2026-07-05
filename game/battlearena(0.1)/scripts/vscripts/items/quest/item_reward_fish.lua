
item_reward_fish = class({})

function item_reward_fish:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_item_reward_fish", nil)
	EmitSoundOn("DOTA_Item.Cheese.Activate", caster)
	caster:RemoveItem(self)
end


modifier_item_reward_fish = class({
	IsHidden 				= function(self) return true end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return false end,
	DeclareFunctions		= function(self) return 
		{	MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		} end,
})

function modifier_item_reward_fish:OnCreated()
	self.bonus_value = self:GetAbility():GetSpecialValueFor("bonus_value")
end

function modifier_item_reward_fish:GetModifierBonusStats_Agility()
	return self.bonus_value
end



LinkLuaModifier("modifier_item_reward_fish", "items/quest/item_reward_fish", LUA_MODIFIER_MOTION_NONE, modifier_item_reward_fish)
