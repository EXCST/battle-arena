require('items/generic_datadriven_item')

item_pet_mage = item_pet_mage or class({})

function item_pet_mage:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end