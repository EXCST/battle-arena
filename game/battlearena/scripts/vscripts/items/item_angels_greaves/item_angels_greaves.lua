require('items/generic_datadriven_item')

item_angels_greaves = item_angels_greaves or class({})

function item_angels_greaves:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end