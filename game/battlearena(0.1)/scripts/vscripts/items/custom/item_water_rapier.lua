require('items/generic_datadriven_item')

require('items/custom/item_base_rapier')


item_water_rapier = class(item_base_rapier)

function item_water_rapier:GetIntrinsicModifierName()
	return "modifier_item_water_rapier"
end

function item_water_rapier:IsRefreshable()
	return false
end

function item_water_rapier:GetCooldown(iLevel)
	local caster = self:GetCaster()
	local baseCooldown = self.BaseClass.GetCooldown(self, iLevel)
	return baseCooldown / caster:GetCooldownReduction()
end

function item_water_rapier:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local caster = self:GetCaster()
	local buffDuration = self:GetSpecialValueFor("active_bonus_spell_resistance_duration")
	local maxHpToHealingPct = self:GetSpecialValueFor("active_max_hp_to_healing_pct") / 100
	local radius = self:GetCastRange(nil, nil)
    local allies = FindUnitsInRadius(
        caster:GetTeamNumber(), 
        caster:GetAbsOrigin(), 
        nil, 
        radius, 
        self:GetAbilityTargetTeam(), 
    	self:GetAbilityTargetType(), 
        self:GetAbilityTargetFlags(), 
        FIND_ANY_ORDER, 
        false
    )
    for _, ally in pairs(allies) do
		ally:AddNewModifier(caster, self, "modifier_item_water_rapier_buff", {duration = buffDuration})
		EmitSoundOn("WaterRapier.Target", ally)
		local healing = ally:GetMaxHealth() * maxHpToHealingPct
		healing = ally:Heal(healing, self, DOTA_HEAL_TYPE_HEALING)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, healing, nil)
	end
	local particle = ParticleManager:CreateParticle(
		"particles/custom/items/water_rapier/monkey_king_spring_arcana_water.vpcf", 
		PATTACH_ABSORIGIN, 
		caster
	)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(1, 0, 0))
	ParticleManager:ReleaseParticleIndex(particle)
	EmitSoundOn("WaterRapier.Activate", caster)
end

function item_water_rapier:ApplyItemContainerEffects(itemContainer)
	itemContainer:SetRenderColor(30, 144, 255)
end

function item_water_rapier:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("active_radius")
end

modifier_item_water_rapier = class(modifier_item_base_rapier)

function modifier_item_water_rapier:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_EVENT_ON_DEATH
	}
end

function modifier_item_water_rapier:GetEffectName()
	return "particles/custom/items/water_rapier/effect_lvl3.vpcf"
end

function modifier_item_water_rapier:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_water_rapier:OnOwnerHaveMoreThanOneRapierType(owner, item)
	GameRules:SendCustomMessage("#Game_notification_water_rapier_request_message1",0,0)		
	self:DropRapier(owner, item)
end

function modifier_item_water_rapier:OnOwnerHaveInsufficientStats(owner, item, insufficientStats)
	GameRules:SendCustomMessage("#Game_notification_water_rapier_request_message",0,0)	
	GameRules:SendCustomMessage("<font color='#FFD700'>MISSING ATTRIBUTES: </font><font color='#1e90ff'>".. insufficientStats .."</font>",0,0)	
	self:DropRapier(owner, item)
end

function modifier_item_water_rapier:OnRapierAddedToInventory()
	self.waterRapierAbility = self:GetAbility()
	self.waterRapierAuraRadius = self.waterRapierAbility:GetSpecialValueFor("passive_aura_radius")
	self.waterRapierBuffsDurationAmplification = self.waterRapierAbility:GetSpecialValueFor("bonus_buffs_duration_pct")
	self.waterRapierHealingAmp = self.waterRapierAbility:GetSpecialValueFor("rapier_healing_amp_pct")
	self:SetHasCustomTransmitterData(true)
end

function modifier_item_water_rapier:GetModifierBuffsDurationAmplificationPercent() 
	return self.waterRapierBuffsDurationAmplification 
end

function modifier_item_water_rapier:GetModifierHealCaused_Percentage() 
	return self.waterRapierHealingAmp 
end

function modifier_item_water_rapier:GetModifierHPRegenAmplify_Percentage() 
	return self.waterRapierHealingAmp 
end

function modifier_item_water_rapier:AddCustomTransmitterData()
	return
	{
		waterRapierHealingAmp = self.waterRapierHealingAmp
	}
end
  
function modifier_item_water_rapier:HandleCustomTransmitterData(data)
	self.waterRapierHealingAmp = data.waterRapierHealingAmp
end

function modifier_item_water_rapier:IsAura() return true end
function modifier_item_water_rapier:GetAuraRadius() return self.waterRapierAuraRadius end
function modifier_item_water_rapier:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_item_water_rapier:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_item_water_rapier:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_item_water_rapier:GetModifierAura() return "modifier_item_water_rapier_debuff" end

modifier_item_water_rapier_buff = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return true
    end,
    IsDebuff = function()
        return false
    end,
	CheckState = function()
		return {
			[MODIFIER_STATE_MAGIC_IMMUNE] = true
		}
	end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
		}
	end,
	GetModifierMagicalResistanceBonus = function(self)
		return self.bonusSpellResistance
	end,
	GetTexture = function(self)
		return self.icon
	end
})

function modifier_item_water_rapier_buff:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	if(not IsServer()) then
		self.icon = self.ability:GetAbilityTextureName()
	else
		local particle = ParticleManager:CreateParticle(
			"particles/custom/items/water_rapier/effect_bkb.vpcf", 
			PATTACH_CUSTOMORIGIN, 
			nil
		)
		ParticleManager:SetParticleControlEnt(particle, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
		self:AddParticle(particle, false, false, 1, false, false)
	end
	self:OnRefresh()
end

function modifier_item_water_rapier_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability) then
        return
    end
	self.bonusSpellResistance = self.ability:GetSpecialValueFor("active_bonus_spell_resistance")
	if(not IsServer()) then
		return
	end
	self.maxHpToHealingPerSecondPct = self.ability:GetSpecialValueFor("max_hp_to_healing_per_second_pct") / 100
	local lastTickRate = self.tickInterval or 99999
	self.tickInterval = self.ability:GetSpecialValueFor("healing_tick")
	self.maxHpToHealingPerSecondPct = self.maxHpToHealingPerSecondPct * self.tickInterval
	if(self.tickInterval < lastTickRate) then
		self:StartIntervalThink(self.tickInterval)
	end
end

function modifier_item_water_rapier_buff:OnIntervalThink()
    local healing = self.parent:Heal(self.parent:GetMaxHealth() * self.maxHpToHealingPerSecondPct, self.ability, DOTA_HEAL_TYPE_HEALING)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self.parent, healing, nil)
end

modifier_item_water_rapier_debuff = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
	IsPurgeException = function()
        return false
    end,
    IsDebuff = function()
        return true
    end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
		}
	end,
	GetModifierStatusResistanceStacking = function(self)
		return self.spellResistanceReduction
	end
})

function modifier_item_water_rapier_debuff:OnCreated()
	self.ability = self:GetAbility()
	if(not self.ability) then
		self:Destroy()
		return
	end
	self.spellResistanceReduction = self.ability:GetSpecialValueFor("passive_aura_status_resistance_reduction_pct") * -1
end


item_water_rapier_1 = class(item_water_rapier)
item_water_rapier_2 = class(item_water_rapier)
item_water_rapier_3 = class(item_water_rapier)
item_water_rapier_4 = class(item_water_rapier)

LinkLuaModifier("modifier_item_water_rapier", "items/custom/item_water_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_water_rapier)
LinkLuaModifier("modifier_item_water_rapier_buff", "items/custom/item_water_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_water_rapier_buff)
LinkLuaModifier("modifier_item_water_rapier_debuff", "items/custom/item_water_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_water_rapier_debuff)
