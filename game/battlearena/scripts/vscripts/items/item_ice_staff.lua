require('items/generic_datadriven_item')

item_ice_staff_custom = class({
	GetIntrinsicModifierName = function() return "modifier_item_ice_staff" end
})

function item_ice_staff_custom:Precache(context)
	PrecacheResource("particle", "particles/custom/items/ice_staff/effect.vpcf", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_frost_lich.vpcf", context)
end

function item_ice_staff_custom:GetAOERadius()
	return self:GetSpecialValueFor("impact_radius")
end

function item_ice_staff_custom:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		target:GetAbsOrigin(),
		nil,
		self:GetSpecialValueFor("impact_radius"),
		self:GetAbilityTargetTeam(),
		self:GetAbilityTargetType(),
		self:GetAbilityTargetFlags(),
		FIND_ANY_ORDER,
		false
	)
	local impact_damage = self:GetSpecialValueFor("impact_damage") + self:GetCaster():GetPrimaryStatValue()*self:GetSpecialValueFor("impact_damage_int_pct")/100
	for _, enemy in pairs(enemies) do
		enemy:AddNewModifier(caster, self, "modifier_item_ice_staff_debuff", {duration = self:GetSpecialValueFor("slow_duration")})
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			ability = self,
			damage = impact_damage,
			damage_type = self:GetAbilityDamageType()
		})
	end
	local nFXIndex = ParticleManager:CreateParticle("particles/custom/items/ice_staff/effect.vpcf", PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(nFXIndex, 1, Vector(self:GetSpecialValueFor("impact_radius"), self:GetSpecialValueFor("impact_radius"), 1))
    ParticleManager:ReleaseParticleIndex(nFXIndex, 2)

    EmitSoundOn("Item.IceStaff.Cast", target)
end

modifier_item_ice_staff = class({
	IsHidden = function() return true end,
	IsItem = function() return true end,
	IsPurgable = function() return false end,
	IsPurgeException = function()
		return false
	end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
	
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_PERCENTAGE,
        } end,
	GetModifierExtraManaBonus = function(self) return self.bonus_mana end,
	GetModifierConstantManaRegen = function(self) return self.bonus_mp_regen end,
	GetModifierBonusStats_Intellect = function(self) return self.bonus_int end,
	GetAttributes = function()
		return MODIFIER_ATTRIBUTE_MULTIPLE
	end
})

function modifier_item_ice_staff:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_item_ice_staff:OnRefresh()
	self.ability = self:GetAbility() or self.ability
	if(not self.ability or self.ability:IsNull()) then
		return
	end
	self.bonus_mana = self.ability:GetSpecialValueFor("bonus_mana")
	self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
	self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
end

modifier_item_ice_staff_debuff = class({
	IsPurgable = function() return true end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ROSHDEF_ATTACK_SPEED_PERCENTAGE,
		MODIFIER_PROPERTY_TOOLTIP
	
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_PERCENTAGE,
        } end,
	GetModifierMoveSpeedBonus_Percentage = function(self) return self.slow_ms_pct end,
	GetModifierAttackSpeed_Percentage = function(self) return self.slow_as_pct end,
	OnTooltip = function(self)
		return self:GetModifierAttackSpeed_Percentage()
	end,
	GetTexture = function(self)
		return self.buffIcon
	end,
	GetStatusEffectName = function()
		return "particles/status_fx/status_effect_frost_lich.vpcf"
	end,
	StatusEffectPriority = function()
		return MODIFIER_PRIORITY_NORMAL
	end
})

function modifier_item_ice_staff_debuff:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
	if (not IsServer()) then 
		self.buffIcon = self.ability:GetAbilityTextureName()
		return 
	end
end

function modifier_item_ice_staff_debuff:OnRefresh()
	self.ability = self:GetAbility() or self.ability
	if(not self.ability or self.ability:IsNull()) then
		return
	end
	self.slow_ms_pct = self.ability:GetSpecialValueFor("slow_ms_pct") * -1
	self.slow_as_pct = self.ability:GetSpecialValueFor("slow_as_pct") * -1
end

item_ice_staff_1 = class(item_ice_staff_custom)
item_ice_staff_2 = class(item_ice_staff_custom)
item_ice_staff_3 = class(item_ice_staff_custom)
item_ice_staff_4 = class(item_ice_staff_custom)
item_ice_staff_5 = class(item_ice_staff_custom)
item_ice_staff_6 = class(item_ice_staff_custom)

LinkLuaModifier("modifier_item_ice_staff", "items/item_ice_staff", LUA_MODIFIER_MOTION_NONE, modifier_item_ice_staff)
LinkLuaModifier("modifier_item_ice_staff_debuff", "items/item_ice_staff", LUA_MODIFIER_MOTION_NONE, modifier_item_ice_staff_debuff)