require('items/generic_datadriven_item')

item_snake_boots = item_snake_boots or class({})

function item_snake_boots:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end