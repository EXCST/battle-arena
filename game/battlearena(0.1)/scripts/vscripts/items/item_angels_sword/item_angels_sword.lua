require('items/generic_datadriven_item')

item_angels_sword = item_angels_sword or class({})

function item_angels_sword:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end