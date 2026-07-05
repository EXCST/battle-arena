require('items/generic_datadriven_item')

item_power_amulet = item_power_amulet or class({})

function item_power_amulet:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end