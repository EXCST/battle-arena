require('items/generic_datadriven_item')

item_pet_hulk = item_pet_hulk or class({})

function item_pet_hulk:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end