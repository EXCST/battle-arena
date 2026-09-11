require('items/generic_datadriven_item')

item_blessed_essence = item_blessed_essence or class({})

function item_blessed_essence:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end