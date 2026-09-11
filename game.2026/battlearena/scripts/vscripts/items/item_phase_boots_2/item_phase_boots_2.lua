require('items/generic_datadriven_item')

item_phase_boots_2 = item_phase_boots_2 or class({})

function item_phase_boots_2:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end