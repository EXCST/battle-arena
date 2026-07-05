require('items/generic_datadriven_item')

item_awful_mask = item_awful_mask or class({})

function item_awful_mask:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end