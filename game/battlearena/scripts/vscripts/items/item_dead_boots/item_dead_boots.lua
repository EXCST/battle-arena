require('items/generic_datadriven_item')

item_dead_boots = item_dead_boots or class({})

function item_dead_boots:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end