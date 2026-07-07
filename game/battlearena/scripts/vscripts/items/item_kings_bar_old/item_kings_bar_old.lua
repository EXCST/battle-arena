require('items/generic_datadriven_item')

item_kings_bar_old = item_kings_bar_old or class({})

function item_kings_bar_old:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end