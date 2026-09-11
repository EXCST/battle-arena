modifier_possessed_annihilation = modifier_possessed_annihilation or class({})
local mod = modifier_possessed_annihilation


function mod:IsHidden() return false end
function mod:IsPurgable() return false end


function mod:GetEffectName()
	return "particles/items_fx/blademail.vpcf"
end


function mod:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
