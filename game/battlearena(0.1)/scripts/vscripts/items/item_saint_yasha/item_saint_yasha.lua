require('items/generic_datadriven_item')

item_saint_yasha = item_saint_yasha or class({})

function item_saint_yasha:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end