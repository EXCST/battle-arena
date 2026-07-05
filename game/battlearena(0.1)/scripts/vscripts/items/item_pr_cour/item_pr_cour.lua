require('items/generic_datadriven_item')

item_pr_cour = item_pr_cour or class({})

function item_pr_cour:GetIntrinsicModifierName()
    return "modifier_generic_datadriven_item"
end