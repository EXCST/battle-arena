require('items/generic_datadriven_item')

item_double_crit = item_double_crit or class({})

function item_double_crit:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end