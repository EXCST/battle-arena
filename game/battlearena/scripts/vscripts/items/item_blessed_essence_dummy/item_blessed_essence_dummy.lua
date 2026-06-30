require('items/generic_datadriven_item')

item_blessed_essence_dummy = item_blessed_essence_dummy or class({})

function item_blessed_essence_dummy:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end