require('items/generic_datadriven_item')

item_angels_blood_dummy = item_angels_blood_dummy or class({})

function item_angels_blood_dummy:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end