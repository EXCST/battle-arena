require('items/generic_datadriven_item')

item_lightning_flash = item_lightning_flash or class({})

function item_lightning_flash:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end