require('items/generic_datadriven_item')


item_imba_rapier = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_imba_rapier"
	end
})

modifier_item_imba_rapier = class({
	IsHidden = function()
		return true
	end,
	IsPurgable = function()
		return false
	end,
	IsPermanent = function()
		return true
	end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		}
	end,
	GetModifierPreAttack_BonusDamage = function(self)
		return self.bonusDmg
	end,
	GetAttributes = function()
		return MODIFIER_ATTRIBUTE_MULTIPLE
	end
})

function modifier_item_imba_rapier:OnCreated()
	self.item = self:GetAbility()
	self.bonusDmg = self.item:GetSpecialValueFor("rapier_dmg")
end


LinkLuaModifier("modifier_item_imba_rapier", "items/custom/item_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_imba_rapier)
