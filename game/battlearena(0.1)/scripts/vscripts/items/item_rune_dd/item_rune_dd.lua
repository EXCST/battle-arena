require('items/generic_datadriven_item')

item_rune_dd = item_rune_dd or class({})

function item_rune_dd:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end