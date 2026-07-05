require('items/generic_datadriven_item')

item_burning_butterfly = item_burning_butterfly or class({})

function item_burning_butterfly:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end