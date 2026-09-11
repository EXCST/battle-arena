require('lib/ability_kv')

saber_avalon = class({
	GetIntrinsicModifierName = function() return "modifier_saber_avalon" end,
})

if IsServer() then
	function saber_avalon:OnSpellStart()
		local caster = self:GetCaster()
		local d = AbilityKV:Get(self, "duration")
		if not d or d <= 0 then d = 5 end
		caster:AddNewModifier(caster, self, "modifier_saber_avalon_invulnerability", {duration = d})
	end
	function saber_avalon:OnChannelFinish()
		self:GetCaster():RemoveModifierByName("modifier_saber_avalon_invulnerability")
	end
end


modifier_saber_avalon = class({
	IsPurgable       = function() return false end,
	DeclareFunctions = function() return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT} end,
})

function modifier_saber_avalon:GetModifierConstantHealthRegen()
	return self:GetStackCount()
end

if IsServer() then
	function modifier_saber_avalon:OnCreated()
		self:StartIntervalThink(0.1)
	end
	function modifier_saber_avalon:OnIntervalThink()
		local ability = self:GetAbility()
		local min = AbilityKV:Get(ability, "bonus_health_regen_min")
		local max = AbilityKV:Get(ability, "bonus_health_regen_max")
		local pct = self:GetParent():GetManaPercent()
		self:SetStackCount(math.round(min + (max - min) * pct * 0.01))
	end
end


modifier_saber_avalon_invulnerability = class({
	GetAbsoluteNoDamageMagical  = function() return 1 end,
	GetAbsoluteNoDamagePhysical = function() return 1 end,
	GetAbsoluteNoDamagePure     = function() return 1 end,
	GetMinHealth                = function() return 1 end,
})
function modifier_saber_avalon_invulnerability:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
	}
end

function modifier_saber_avalon_invulnerability:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_MIN_HEALTH,
		--MODIFIER_PROPERTY_OVERRIDE_ANIMATION
	}
end
