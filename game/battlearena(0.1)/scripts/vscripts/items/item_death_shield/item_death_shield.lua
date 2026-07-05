require('items/generic_datadriven_item')

item_death_shield = item_death_shield or class({})

function item_death_shield:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end