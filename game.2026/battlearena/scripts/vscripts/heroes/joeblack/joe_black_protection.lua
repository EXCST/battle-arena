joe_black_protection = joe_black_protection or class({})
LinkLuaModifier("modifier_joe_black_protection", "heroes/joeblack/joe_black_protection", LUA_MODIFIER_MOTION_NONE)


function joe_black_protection:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local duration = self:GetSpecialValueFor("duration")

	target:Purge(false, true, false, true, true)

	target:AddNewModifier(caster, self, "modifier_joe_black_protection", {
		duration = duration
	})

	target:EmitSound("Hero_VengefulSpirit.WaveOfTerror")
end



modifier_joe_black_protection = modifier_joe_black_protection or class({})


function modifier_joe_black_protection:IsPurgable() return false end
function modifier_joe_black_protection:GetEffectName() return "particles/units/heroes/hero_spirit_breaker/spirit_breaker_haste_owner_status.vpcf" end
function modifier_joe_black_protection:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end


function modifier_joe_black_protection:OnCreated()
	local ability = self:GetAbility()

	self.reduction = -ability:GetSpecialValueFor("damage_reduction")

	local grants_spell_immunity = ability:GetSpecialValueFor("grants_spell_immunity") == 1

	self.state = {}

	if grants_spell_immunity then
		self.state[MODIFIER_STATE_DEBUFF_IMMUNE] = true
	end
end


function modifier_joe_black_protection:OnRefresh()
	self:OnCreated()
end


function modifier_joe_black_protection:CheckState()
	return self.state
end


function modifier_joe_black_protection:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end


function modifier_joe_black_protection:GetModifierIncomingDamage_Percentage() return self.reduction end