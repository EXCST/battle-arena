require('items/generic_datadriven_item')

item_cursed_sange_dummy = item_cursed_sange_dummy or class({})

function item_cursed_sange_dummy:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end