require('items/generic_datadriven_item')

item_rune_regen = item_rune_regen or class({})

function item_rune_regen:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end