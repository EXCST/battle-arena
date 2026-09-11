require('items/generic_datadriven_item')

item_angels_armor_dummy = item_angels_armor_dummy or class({})

function item_angels_armor_dummy:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end