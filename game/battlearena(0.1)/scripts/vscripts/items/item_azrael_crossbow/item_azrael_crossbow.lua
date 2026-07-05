require('items/generic_datadriven_item')

item_azrael_crossbow = item_azrael_crossbow or class({})

function item_azrael_crossbow:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end