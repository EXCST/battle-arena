require('items/generic_datadriven_item')

item_angels_sword_dummy = item_angels_sword_dummy or class({})

function item_angels_sword_dummy:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end