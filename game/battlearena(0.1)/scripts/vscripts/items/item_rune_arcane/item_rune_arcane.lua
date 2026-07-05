require('items/generic_datadriven_item')

item_rune_arcane = item_rune_arcane or class({})

function item_rune_arcane:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end