item_illusionsts_cape_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_illusionsts_cape_custom"
    end
})

function item_illusionsts_cape_custom:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local caster = self:GetCaster()
	local illusions = CreateIllusions(
		caster, 
		caster, 
		{
			outgoing_damage 			= self:GetSpecialValueFor("outgoing_damage") - 100,
			incoming_damage				= self:GetSpecialValueFor("incoming_damage") - 100,
			bounty_base					= caster:GetLevel() * 2,
			bounty_growth				= nil,
			outgoing_damage_structure	= nil,
			outgoing_damage_roshan		= nil,
			duration					= self:GetSpecialValueFor("illusion_duration")
		},
		self:GetSpecialValueFor("illusions"),
		72, 
		false, 
		true
	)
	EmitSoundOn("Item.IllusionstsCape.Activate", caster)
end

modifier_item_illusionsts_cape_custom = class({
    IsHidden = function() 
        return true 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS
        }
    end,
    IsAuraActiveOnDeath = function()
        return false
    end,
    GetAuraRadius = function(self)
        return FIND_UNITS_EVERYWHERE
    end,
    GetAuraSearchFlags = function(self)
        return self.targetFlags
    end,
    GetAuraSearchTeam = function(self)
        return self.targetTeam
    end,
    IsAura = function()
        return true
    end,
    GetAuraSearchType = function(self)
        return self.targetType
    end,
    GetModifierAura = function()
        return "modifier_item_illusionsts_cape_custom_aura_buff"
    end,
    GetAuraDuration = function()
        return 0
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.bonusStr
    end,
    GetModifierBonusStats_Agility = function(self)
        return self.bonusAgi
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_illusionsts_cape_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
end

function modifier_item_illusionsts_cape_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusStr = self.ability:GetSpecialValueFor("bonus_str")
    self.bonusAgi = self.ability:GetSpecialValueFor("bonus_agi")
end

function modifier_item_illusionsts_cape_custom:GetAuraEntityReject(hEntity)
    return hEntity:GetOwnerEntity() ~= self.parent
end

modifier_item_illusionsts_cape_custom_aura_buff = class({
    IsHidden = function() 
        return false 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
            MODIFIER_PROPERTY_TOOLTIP
        }
    end,
    GetModifierTotalDamageOutgoing_Percentage = function(self)
        return self.bonusDamage
    end,
    OnTooltip = function(self)
        return self:GetModifierTotalDamageOutgoing_Percentage()
    end
})

function modifier_item_illusionsts_cape_custom_aura_buff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_illusionsts_cape_custom_aura_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusDamage = self.ability:GetSpecialValueFor("attack_damage_aura")
end

LinkLuaModifier("modifier_item_illusionsts_cape_custom", "items/neutral_items/illusionsts_cape", LUA_MODIFIER_MOTION_NONE, modifier_item_illusionsts_cape_custom)
LinkLuaModifier("modifier_item_illusionsts_cape_custom_aura_buff", "items/neutral_items/illusionsts_cape", LUA_MODIFIER_MOTION_NONE, modifier_item_illusionsts_cape_custom_aura_buff)