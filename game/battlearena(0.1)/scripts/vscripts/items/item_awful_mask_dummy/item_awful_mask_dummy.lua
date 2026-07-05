require('items/generic_datadriven_item')

item_awful_mask_dummy = item_awful_mask_dummy or class({})

function item_awful_mask_dummy:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end