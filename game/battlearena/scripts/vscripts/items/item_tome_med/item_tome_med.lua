require('items/generic_datadriven_item')

item_tome_med = item_tome_med or class({})

function item_tome_med:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end