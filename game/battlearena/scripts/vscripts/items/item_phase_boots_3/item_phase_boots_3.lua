require('items/generic_datadriven_item')

item_phase_boots_3 = item_phase_boots_3 or class({})

function item_phase_boots_3:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end