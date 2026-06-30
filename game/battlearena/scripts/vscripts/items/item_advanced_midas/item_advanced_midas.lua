require('items/generic_datadriven_item')

item_advanced_midas = item_advanced_midas or class({})

function item_advanced_midas:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end