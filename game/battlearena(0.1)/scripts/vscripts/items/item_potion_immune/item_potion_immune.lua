require('items/generic_datadriven_item')

item_potion_immune = item_potion_immune or class({})

function item_potion_immune:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end