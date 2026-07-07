require('items/generic_datadriven_item')

item_angels_blood = item_angels_blood or class({})

function item_angels_blood:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end