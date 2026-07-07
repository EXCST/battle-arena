require('items/generic_datadriven_item')

item_rune_invis = item_rune_invis or class({})

function item_rune_invis:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end