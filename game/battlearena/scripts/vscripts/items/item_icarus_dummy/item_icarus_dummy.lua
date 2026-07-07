require('items/generic_datadriven_item')

item_icarus_dummy = item_icarus_dummy or class({})

function item_icarus_dummy:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end