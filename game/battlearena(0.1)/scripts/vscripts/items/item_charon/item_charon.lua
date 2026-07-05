require('items/generic_datadriven_item')

item_charon = item_charon or class({})

function item_charon:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end