require('items/generic_datadriven_item')

item_burning_blades = item_burning_blades or class({})

function item_burning_blades:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end