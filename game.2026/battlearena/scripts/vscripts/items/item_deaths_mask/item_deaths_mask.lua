require('items/generic_datadriven_item')

item_deaths_mask = item_deaths_mask or class({})

function item_deaths_mask:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end