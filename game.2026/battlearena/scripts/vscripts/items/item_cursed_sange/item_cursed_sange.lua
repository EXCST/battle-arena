require('items/generic_datadriven_item')

item_cursed_sange = item_cursed_sange or class({})

function item_cursed_sange:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end