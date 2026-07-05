require('items/generic_datadriven_item')

item_rune_bounty = item_rune_bounty or class({})

function item_rune_bounty:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end