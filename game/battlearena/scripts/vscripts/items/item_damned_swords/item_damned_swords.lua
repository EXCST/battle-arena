require('items/generic_datadriven_item')

item_damned_swords = item_damned_swords or class({})

function item_damned_swords:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end