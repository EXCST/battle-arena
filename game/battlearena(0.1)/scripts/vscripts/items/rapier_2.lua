item_rapier_2 = item_rapier_2 or class({})

LinkLuaModifier( "item_rapier_2_passive_modifier", "items/rapier_2", LUA_MODIFIER_MOTION_NONE )

function item_rapier_2:GetIntrinsicModifierName()
    return "item_rapier_2_passive_modifier"
end

mitem_rapier_2_passive_modifier = class({})

function item_rapier_2_passive_modifier:DeclareFunctions() --we want to use these functions in this item
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }

    return funcs
end

function item_rapier_2_passive_modifier:GetModifierPreAttack_BonusDamage()
    local hAbility = self:GetAbility() --we get the ability where this modifier is from
    return hAbility:GetSpecialValueFor( "bonus_damage" )
end