require('items/generic_datadriven_item')

item_eclipse_amphora_dummy = item_eclipse_amphora_dummy or class({})

function item_eclipse_amphora_dummy:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end