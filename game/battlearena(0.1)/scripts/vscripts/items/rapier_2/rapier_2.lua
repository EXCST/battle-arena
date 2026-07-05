if item_rapier_2 == nil then item_rapier_2 = class({}) end

LinkLuaModifier("modifier_item_rapier_2", "items/rapier_2/rapier_2", LUA_MODIFIER_MOTION_NONE)

function item_rapier_2:OnOwnerDied()
    if IsServer() then
        local itemName = tostring(self:GetAbilityName())
        if self:GetCaster():IsHero() or self:GetCaster():HasInventory() then
          if not self:GetCaster():IsReincarnating() then 
              local newItem = CreateItem(itemName, nil, nil)
              CreateItemOnPositionSync(self:GetCaster():GetOrigin(), newItem)
              self:GetCaster():RemoveItem(self)
          end
      end
    end
end

function item_rapier_2:GetIntrinsicModifierName()
   return "modifier_item_rapier_2"
end

if modifier_item_rapier_2 == nil then modifier_item_rapier_2 = class({}) end

function modifier_item_rapier_2:DeclareFunctions()
	local funcs = {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    }
	return funcs
end

function modifier_item_rapier_2:IsHidden()
	return true
end

function modifier_item_rapier_2:IsPurgable()
	return false
end

function modifier_item_rapier_2:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_rapier_2:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage") 
end

function modifier_item_rapier_2:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_spell_amp") 
end

function item_rapier_2:GetAbilityTextureName()
        return "../items/rapier_2"
end