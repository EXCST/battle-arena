require('items/generic_datadriven_item')

item_test_item = item_test_item or class({})

function item_test_item:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end