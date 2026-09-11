require('items/generic_datadriven_item')

item_mystic_amulet = item_mystic_amulet or class({})

function item_mystic_amulet:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end