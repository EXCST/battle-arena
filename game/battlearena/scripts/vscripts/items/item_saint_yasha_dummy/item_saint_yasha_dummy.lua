require('items/generic_datadriven_item')

item_saint_yasha_dummy = item_saint_yasha_dummy or class({})

function item_saint_yasha_dummy:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end