require('items/generic_datadriven_item')

item_dummy = item_dummy or class({})

function item_dummy:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end