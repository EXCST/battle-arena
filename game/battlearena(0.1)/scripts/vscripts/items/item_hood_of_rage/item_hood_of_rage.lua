require('items/generic_datadriven_item')

item_hood_of_rage = item_hood_of_rage or class({})

function item_hood_of_rage:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end