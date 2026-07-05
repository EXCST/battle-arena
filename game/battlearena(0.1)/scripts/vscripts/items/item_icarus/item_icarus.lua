require('items/generic_datadriven_item')

item_icarus = item_icarus or class({})

function item_icarus:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end