modifier_shadowsong_absorption_talent = class({})
mod = modifier_shadowsong_absorption_talent

local talentName = "shadowsong_special_bonus_absorbtion_kill_bonus"

function mod:IsHidden() 		return false end
function mod:IsPurgable() 		return false end
function mod:DestroyOnExpire() 	return false end
function mod:IsPurgeException() return false end
function mod:GetAttributes()  	return MODIFIER_ATTRIBUTE_PERMANENT end

function mod:DeclareFunctions() return 
{
	MODIFIER_PROPERTY_HEALTH_BONUS,
}
end

function mod:OnCreated( kv )
	local caster = self:GetCaster()
	local tAbility = caster and caster:FindAbilityByName(talentName)
	self.hp = (tAbility and tAbility:GetLevel() > 0) and 50 or 0
end

mod.OnRefresh = mod.OnCreated

function mod:GetModifierHealthBonus() 
	return self.hp * self:GetStackCount()
end