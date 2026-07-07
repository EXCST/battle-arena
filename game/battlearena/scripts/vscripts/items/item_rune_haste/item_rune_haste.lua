require('items/generic_datadriven_item')

item_rune_haste = item_rune_haste or class({})

function item_rune_haste:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end