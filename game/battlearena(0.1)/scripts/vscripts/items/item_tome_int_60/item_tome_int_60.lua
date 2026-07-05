require('items/generic_datadriven_item')

item_tome_int_60 = item_tome_int_60 or class({})

function item_tome_int_60:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end