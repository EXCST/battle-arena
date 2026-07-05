require('items/generic_datadriven_item')

require('items/custom/item_base_that_require_stats')

item_cursed_rapier = class(item_base_that_require_stats)

function item_cursed_rapier:Precache(context)
	PrecacheResource("model", "models/items/terrorblade/dotapit_s3_fallen_light_metamorphosis/dotapit_s3_fallen_light_metamorphosis.vmdl", context)
	PrecacheResource("particle", "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf", context)
	PrecacheResource("particle", "particles/custom/items/cursed_rapier/effect.vpcf", context)
	PrecacheResource("particle", "particles/custom/items/cursed_rapier/cast/ground.vpcf", context)
	PrecacheResource("particle", "particles/custom/items/cursed_rapier/cast/ambient.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis.vpcf", context)
end

function item_cursed_rapier:GetIntrinsicModifierName()
	return "modifier_item_cursed_rapier"
end

function item_cursed_rapier:GetStatsFromThisItem()
	return 0
end

function item_cursed_rapier:GetRequiredStats()
	return self:GetSpecialValueFor("stats_required")
end

function item_cursed_rapier:OnToggle()
	if(not IsServer()) then
		return
	end
	local caster = self:GetCaster()
	if(self:GetToggleState() == true) then
		caster:AddNewModifier( caster, self, "modifier_item_cursed_rapier_buff" , { duration = -1} )
		self:EndCooldown()
	else
		local modifier = caster:FindModifierByName("modifier_item_cursed_rapier_buff")
		if(modifier) then
			modifier:Destroy()
		end
		self:UseResources(false, false, false, true)
	end
end

modifier_item_cursed_rapier = class(modifier_item_base_that_require_stats)

function modifier_item_cursed_rapier:GetEffectName()
	return "particles/custom/items/cursed_rapier/effect.vpcf"
end

function modifier_item_cursed_rapier:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_item_cursed_rapier:GetModifierBaseAttack_BonusDamage()
	return self.bonusBaseDamage
end

function modifier_item_cursed_rapier:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_cursed_rapier:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_cursed_rapier:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

function modifier_item_cursed_rapier:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

function modifier_item_cursed_rapier:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_item_cursed_rapier:OnItemRefreshed(owner, item)
	self.bonusBaseDamage = item:GetSpecialValueFor("bonus_base_damage")
    self.bonus_allstats = item:GetSpecialValueFor("bonus_allstats")
    self.bonus_attack_speed = item:GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_cursed_rapier:OnItemRemoved(owner, item)
	owner:RemoveModifierByName("modifier_item_cursed_rapier_buff")
end

function modifier_item_cursed_rapier:OnItemOwnerStatsNotEnough(owner, item, missingStats)
	owner:Kill(nil,nil)
	GameRules:SendCustomMessage("#Game_notification_cursed_rapier_request_message",0,0)
	GameRules:SendCustomMessage("<font color='#FFD700'>MISSING ATTRIBUTES: </font><font color='#00FF00'>".. missingStats .."</font>",0,0)
end

modifier_item_cursed_rapier_buff = class({
	IsHidden = function()
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
			MODIFIER_PROPERTY_MODEL_CHANGE,
			MODIFIER_PROPERTY_PROJECTILE_NAME,
			MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
			MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_EVENT_ON_ATTACK,
			MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
			MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
			MODIFIER_PROPERTY_TOOLTIP
		}
	end,
	GetModifierModelChange = function()
		return "models/items/terrorblade/dotapit_s3_fallen_light_metamorphosis/dotapit_s3_fallen_light_metamorphosis.vmdl"
	end,
	GetModifierProjectileName = function()
		return "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf"
	end,
	GetModifierAttackRangeBonus = function(self)
		return self.bonusAttackRange
	end,
	GetModifierAttackCapability = function()
		return DOTA_UNIT_CAP_RANGED_ATTACK
	end,
	GetAttackSound = function()
		return "CursedRapier.Attack"
	end
})

function modifier_item_cursed_rapier_buff:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()
	if(not IsServer()) then
		return
	end
	self:CreateEffects()
end

function modifier_item_cursed_rapier_buff:CreateEffects()
	local pidx = ParticleManager:CreateParticle("particles/custom/items/cursed_rapier/cast/ambient.vpcf", PATTACH_ABSORIGIN, self.parent)
	self:AddParticle(pidx, false, false, 1, true, false)
	pidx = ParticleManager:CreateParticle("particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	self:AddParticle(pidx, false, false, 1, true, false)
	pidx = ParticleManager:CreateParticle("particles/custom/items/cursed_rapier/cast/ground.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	self:AddParticle(pidx, false, false, 1, true, false)
	EmitSoundOn("CursedRapier.Cast", self.parent)
end

function modifier_item_cursed_rapier_buff:OnRefresh()
	self.ability = self.ability or self:GetAbility()
	if(not self.ability or self.ability:IsNull()) then
        return
    end
	self.bonusBaseDamage = self.ability:GetSpecialValueFor("bonus_base_damage")
	self.bonusAttackRange = self.ability:GetSpecialValueFor("bonus_attack_range")
	self.tickInterval = self.ability:GetSpecialValueFor("tick_interval")
	self.bonusAttackDamagePct = self.ability:GetSpecialValueFor("base_damage_pct")
	self.bonusAttackDamagePctPerStack = self.ability:GetSpecialValueFor("damage_increase_per_second_pct") * self.tickInterval
	self.maxHpCostPctPerSec = (self.ability:GetSpecialValueFor("base_hp_drain_per_second_pct") / 100) * self.tickInterval
	self.maxHpCostPctPerSecPerStack = (self.ability:GetSpecialValueFor("hp_drain_increase_per_second_pct") / 100) * self.tickInterval
	if(not IsServer()) then
		return
	end
	self._firstTick = true
	self:StartIntervalThink(self.tickInterval)
end

function modifier_item_cursed_rapier_buff:OnIntervalThink()
	if(not self._firstTick) then
		self.maxHpCostPctPerSec = self.maxHpCostPctPerSec + self.maxHpCostPctPerSecPerStack
		self.bonusAttackDamagePct = self.bonusAttackDamagePct + self.bonusAttackDamagePctPerStack
	else
		self._firstTick = nil	
	end
	self:SetStackCount(self.bonusAttackDamagePct)
	local hpToRemove = self.parent:GetMaxHealth() * self.maxHpCostPctPerSec
	self.parent:ModifyHealth(
		self.parent:GetHealth() - hpToRemove, 
		self.ability, 
		true, 
		DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
	) 
end

function modifier_item_cursed_rapier_buff:OnTooltip()
	return self:GetStackCount()
end

function modifier_item_cursed_rapier_buff:OnAttack(kv)
	if(not IsServer()) then
		return
	end
	if(kv.attacker ~= self.parent) then
		return
	end
	EmitSoundOn("CursedRapier.PreAttack", self.parent)
end

function modifier_item_cursed_rapier_buff:OnAttackLanded(kv)
	if(not IsServer()) then
		return
	end
	if(kv.attacker ~= self.parent) then
		return
	end
	EmitSoundOn("CursedRapier.ProjectileImpact", kv.target)
end

function modifier_item_cursed_rapier_buff:GetModifierBaseDamageOutgoing_Percentage()
    return self:GetStackCount()
end

LinkLuaModifier("modifier_item_cursed_rapier", "items/custom/item_cursed_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_cursed_rapier)
LinkLuaModifier("modifier_item_cursed_rapier_buff", "items/custom/item_cursed_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_cursed_rapier_buff)
