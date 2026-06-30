require('items/generic_datadriven_item')

require('items/custom/item_base_that_require_stats')

item_cursed_cuirass = class(item_base_that_require_stats)

function item_cursed_cuirass:Precache(context)
	PrecacheResource("particle", "particles/custom/items/cursed_cuirass/cast/aura.vpcf", context)
	PrecacheResource("particle", "particles/custom/items/cursed_cuirass/ambient/ambient.vpcf", context)
end

function item_cursed_cuirass:GetIntrinsicModifierName()
	return "modifier_item_cursed_cuirass"
end

function item_cursed_cuirass:GetCastRange()
	return self:GetSpecialValueFor("radius")
end

function item_cursed_cuirass:GetStatsFromThisItem()
	return self:GetSpecialValueFor("bonus_allstats") * 3
end

function item_cursed_cuirass:GetRequiredStats()
	return self:GetSpecialValueFor("stats_required")
end

function item_cursed_cuirass:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local caster = self:GetCaster()
	local auraModifier = caster:FindModifierByName("modifier_item_cursed_cuirass_aura")
	if(auraModifier) then
		auraModifier:Destroy()
	else
		caster:AddNewModifier(caster, self, "modifier_item_cursed_cuirass_aura", {duration = self:GetSpecialValueFor("duration")})
		EmitSoundOn("CursedCuirass.Cast", caster)
		self:EndCooldown()
		self:RefundManaCost()
	end
end

modifier_item_cursed_cuirass = class(modifier_item_base_that_require_stats)

function modifier_item_cursed_cuirass:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_ROSHDEF_KNOCKBACK_IMMUNITY
	}
end

function modifier_item_cursed_cuirass:GetEffectName()
	return "particles/custom/items/cursed_cuirass/ambient/ambient.vpcf"
end

function modifier_item_cursed_cuirass:GetModifierPhysicalArmorBonus()
	return self.bonusArmor
end

function modifier_item_cursed_cuirass:GetModifierBonusStats_Strength()
	return self.bonusStr
end

function modifier_item_cursed_cuirass:GetModifierBonusStats_Agility()
	return self.bonusAgi
end

function modifier_item_cursed_cuirass:GetModifierBonusStats_Intellect()
	return self.bonusInt
end

function modifier_item_cursed_cuirass:GetModifierBonusHealth()
	return self.bonusHealth
end

function modifier_item_cursed_cuirass:GetModifierKnockbackImmunity()
    if(self.parent:IsRealHero() == false or self.parent:GetPrimaryAttribute() ~= DOTA_ATTRIBUTE_STRENGTH) then
        return 0
    end
	return 1
end

function modifier_item_cursed_cuirass:GetModifierIncomingDamage_Percentage(kv)
    if(not IsServer()) then
        return 0
    end
    if(self.parent ~= kv.target) then
        return 0
    end
    if(self.parent:IsRealHero() == false or self.parent:GetPrimaryAttribute() ~= DOTA_ATTRIBUTE_STRENGTH) then
        return
    end
	if (RollPercentage(self.backtrackChance) == false) then
        return 0
    end
	return -999999
end

function modifier_item_cursed_cuirass:OnItemRefreshed(owner, item)
	self.bonusHealth = item:GetSpecialValueFor("bonus_health")
	self.bonusArmor = item:GetSpecialValueFor("bonus_armor")
	self.bonusStr = item:GetSpecialValueFor("bonus_allstats")
	self.bonusAgi = item:GetSpecialValueFor("bonus_allstats")
	self.bonusInt = item:GetSpecialValueFor("bonus_allstats")
    self.backtrackChance = item:GetSpecialValueFor("passive_block_chance_pct")
end

function modifier_item_cursed_cuirass:OnItemAdded(owner, item)
    self.parent = owner
end

function modifier_item_cursed_cuirass:OnItemRemoved(owner, item)
	owner:RemoveModifierByName("modifier_item_cursed_cuirass_aura")
end

function modifier_item_cursed_cuirass:OnItemOwnerStatsNotEnough(owner, item, missingStats)
	owner:Kill(nil,nil)
	GameRules:SendCustomMessage("#Game_notification_cuirass_cursed_request_message",0,0)
	GameRules:SendCustomMessage("<font color='#FFD700'>MISSING ATTRIBUTES: </font><font color='#00FF00'>".. missingStats .."</font>",0,0)
end

modifier_item_cursed_cuirass_aura = class({
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
    IsAuraActiveOnDeath = function()
        return false
    end,
    GetAuraRadius = function(self)
        return self.radius
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
        return "modifier_item_cursed_cuirass_aura_buff"
    end,
    GetAuraDuration = function()
        return 0
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_EVENT_ON_DEATH
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_cursed_cuirass_aura:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
	local particle = ParticleManager:CreateParticle(
		"particles/custom/items/cursed_cuirass/cast/aura.vpcf", 
		PATTACH_ABSORIGIN_FOLLOW, 
		self.parent
	)
	ParticleManager:SetParticleControl(particle, 1, Vector(self.radius, self.radius, self.radius))
	ParticleManager:SetParticleControl(particle, 5, Vector(self.radius, 0, 0))
	self:AddParticle(particle, false, false, 1, false, false)
end

function modifier_item_cursed_cuirass_aura:OnRefresh()
	self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.radius = self.ability:GetCastRange()
end

function modifier_item_cursed_cuirass_aura:OnDeath(kv)
	if(kv.unit ~= self.parent) then
		return
	end
    self:Destroy()
end

function modifier_item_cursed_cuirass_aura:GetAuraEntityReject(npc)
	return npc == self.parent
end

modifier_item_cursed_cuirass_aura_buff = class({
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
            MODIFIER_EVENT_ON_DEATH,
			MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
            MODIFIER_PROPERTY_TOOLTIP
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    OnTooltip = function(self)
        return self.bonusDamageReductionPct
    end
})

function modifier_item_cursed_cuirass_aura_buff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self.parent = self:GetParent()
    self:OnRefresh()
	if(not IsServer()) then
		return
	end
	self.auraOwner = self:GetCaster()
	self.damageTable = {
        victim = self.auraOwner,
        attacker = self.parent,
        ability = self.ability,
        damage = 0,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS
    }
end

function modifier_item_cursed_cuirass_aura_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonusDamageReductionPct = self.ability:GetSpecialValueFor("damage_redirect_pct")
    self.bonusDamageRedirectRatio = self.bonusDamageReductionPct / 100
end

function modifier_item_cursed_cuirass_aura_buff:GetModifierTotal_ConstantBlock(kv)
	self.damageTable.damage = kv.damage * self.bonusDamageRedirectRatio
	self.damageTable.damage_type = kv.damage_type
	ApplyDamage(self.damageTable)
	return self.damageTable.damage
end

function modifier_item_cursed_cuirass_aura_buff:OnDeath(kv)
	if(kv.unit ~= self.parent) then
		return
	end
    if(self.parent:IsRealHero() == false or self.parent:IsIllusion() == true) then
        return false
    end
	self.auraOwner:Kill(self.ability, self.parent)
end

function modifier_item_cursed_cuirass_aura_buff:OnDestroy()
	if(not IsServer()) then
		return
	end
	self.ability:UseResources(true, false, true, true)
	EmitSoundOn("CursedCuirass.End", self.parent)
end

LinkLuaModifier("modifier_item_cursed_cuirass", "items/custom/item_cursed_cuirass", LUA_MODIFIER_MOTION_NONE, modifier_item_cursed_cuirass)
LinkLuaModifier("modifier_item_cursed_cuirass_aura", "items/custom/item_cursed_cuirass", LUA_MODIFIER_MOTION_NONE, modifier_item_cursed_cuirass_aura)
LinkLuaModifier("modifier_item_cursed_cuirass_aura_buff", "items/custom/item_cursed_cuirass", LUA_MODIFIER_MOTION_NONE, modifier_item_cursed_cuirass_aura_buff)