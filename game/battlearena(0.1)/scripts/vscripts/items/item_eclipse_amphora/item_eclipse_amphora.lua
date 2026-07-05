require('items/generic_datadriven_item')

item_eclipse_amphora = item_eclipse_amphora or class({})

function item_eclipse_amphora:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end