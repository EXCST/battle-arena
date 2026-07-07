require('items/generic_datadriven_item')

item_possessed_sword = item_possessed_sword or class({})

function item_possessed_sword:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end