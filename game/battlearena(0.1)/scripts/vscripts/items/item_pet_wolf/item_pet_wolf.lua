require('items/generic_datadriven_item')

item_pet_wolf = item_pet_wolf or class({})

function item_pet_wolf:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end