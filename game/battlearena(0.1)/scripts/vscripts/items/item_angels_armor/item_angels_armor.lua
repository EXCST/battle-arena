require('items/generic_datadriven_item')

item_angels_armor = item_angels_armor or class({})

function item_angels_armor:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end