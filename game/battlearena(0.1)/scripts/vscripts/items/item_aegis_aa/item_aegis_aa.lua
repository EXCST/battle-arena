require('items/generic_datadriven_item')

item_aegis_aa = item_aegis_aa or class({})

function item_aegis_aa:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end