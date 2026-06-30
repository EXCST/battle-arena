require('items/generic_datadriven_item')


item_imba_rapier_magic = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_imba_rapier_magic"
	end
})

modifier_item_imba_rapier_magic = class({
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
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		}
	end,
	GetModifierSpellAmplify_Percentage = function(self)
		return self.bonusSpellAmp
	end
})

function modifier_item_imba_rapier_magic:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_imba_rapier_magic:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonusSpellAmp = self.ability:GetSpecialValueFor("spell_power")
end


LinkLuaModifier("modifier_item_imba_rapier_magic", "items/custom/item_arcane_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_imba_rapier_magic)
