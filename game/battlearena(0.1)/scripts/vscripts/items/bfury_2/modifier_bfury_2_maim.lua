modifier_bfury_2_maim = modifier_bfury_2_maim or class({})
local mod = modifier_bfury_2_maim

function mod:IsHidden() 		return false end
function mod:IsPurgable() 		return false end
function mod:DestroyOnExpire() 	return true end
function mod:IsPurgeException() return true end

function mod:OnCreated()
	local ability = self:GetAbility()

	if not ability then return end

	self.slowAs = -ability:GetSpecialValueFor("maim_decrease_as")
	self.slowMs = -ability:GetSpecialValueFor("maim_decrease_ms")
end

mod.OnRefresh = mod.OnCreated

function mod:DeclareFunctions() return 
{
	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
}
end

function mod:GetModifierMoveSpeedBonus_Percentage( params )
	return -20
end

function mod:GetModifierAttackSpeedBonus_Constant( params )
	return -20
end


function mod:GetEffectName()
	return "particles/items2_fx/sange_maim.vpcf"
end

function mod:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function mod:GetTexture()
    return "../items/custom/bfury_2"
end