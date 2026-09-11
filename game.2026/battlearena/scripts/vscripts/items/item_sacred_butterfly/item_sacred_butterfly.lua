require('items/generic_datadriven_item')

item_sacred_butterfly = item_sacred_butterfly or class({})

function item_sacred_butterfly:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end