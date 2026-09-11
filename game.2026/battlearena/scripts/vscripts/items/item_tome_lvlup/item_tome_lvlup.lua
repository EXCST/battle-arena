require('items/generic_datadriven_item')

item_tome_lvlup = item_tome_lvlup or class({})

function item_tome_lvlup:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end