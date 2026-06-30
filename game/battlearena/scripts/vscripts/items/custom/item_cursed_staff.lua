require('items/generic_datadriven_item')

require('items/custom/item_base_that_require_stats')

item_cursed_staff = class(item_base_that_require_stats)


function item_cursed_staff:Precache(context)
	PrecacheResource("particle", "particles/custom/items/cursed_staff/cast/effect/effect.vpcf", context)
	PrecacheResource("particle", "particles/custom/items/cursed_staff/ambient/ambient.vpcf", context)
	PrecacheResource("particle", "particles/custom/items/cursed_staff/passive/effect.vpcf", context)
end

function item_cursed_staff:GetIntrinsicModifierName()
	return "modifier_item_cursed_staff"
end

function item_cursed_staff:GetStatsFromThisItem()
	return self:GetSpecialValueFor("bonus_strenght") + self:GetSpecialValueFor("bonus_agility") + self:GetSpecialValueFor("bonus_intellect")
end

function item_cursed_staff:GetRequiredStats()
	return self:GetSpecialValueFor("stats_required")
end

function item_cursed_staff:OnSpellStart()
	local caster = self:GetCaster()
	local modifier = caster:FindModifierByName("modifier_item_cursed_staff_buff")
	if(modifier) then
		if(modifier:IsCanBeRemoved() == true) then
			modifier:Destroy()
			self:RefundResources()
		else
			modifier:StopStacks()
		end
	else
		self:StartStacks(caster)
		EmitSoundOn("CursedStaff.Cast", caster)
	end
end

function item_cursed_staff:StartStacks(caster)
	caster:AddNewModifier(caster, self, "modifier_item_cursed_staff_buff", {duration = self:GetSpecialValueFor("active_interval")})
	self:RefundResources()
end

function item_cursed_staff:RefundResources()
	self:EndCooldown()
	self:RefundManaCost()
end

modifier_item_cursed_staff = class(modifier_item_base_that_require_stats)

function modifier_item_cursed_staff:DeclareFunctions()
	return 
	{
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED
	}
end

function modifier_item_cursed_staff:OnItemAdded(owner, item)
	self.parent = owner
	self.item = item
end

function modifier_item_cursed_staff:OnItemRefreshed(owner, item)
    self.bonusStr = item:GetSpecialValueFor("bonus_strenght")
	self.bonusAgi = item:GetSpecialValueFor("bonus_agility")
	self.bonusInt = item:GetSpecialValueFor("bonus_intellect")
	self.buffDuration = item:GetSpecialValueFor("passive_stack_dutation")
	self.bonusCastTimeReductionPct = item:GetSpecialValueFor("passive_cast_time_reduction_pct")
end

function modifier_item_cursed_staff:OnItemRemoved(owner, item)
	owner:RemoveModifierByName("modifier_item_cursed_staff_buff")
end

function modifier_item_cursed_staff:OnItemOwnerStatsNotEnough(owner, item, missingStats)
	owner:Kill(nil,nil)
	GameRules:SendCustomMessage("#Game_notification_cursed_staff_request_message",0,0)
	GameRules:SendCustomMessage("<font color='#FFD700'>MISSING ATTRIBUTES: </font><font color='#00FF00'>".. missingStats .."</font>",0,0)
end

function modifier_item_cursed_staff:GetModifierBonusStats_Strength()
	return self.bonusStr
end

function modifier_item_cursed_staff:GetModifierBonusStats_Agility()
	return self.bonusAgi
end

function modifier_item_cursed_staff:GetModifierBonusStats_Intellect()
	return self.bonusInt
end

function modifier_item_cursed_staff:GetModifierPercentageCasttime()
	return self.bonusCastTimeReductionPct
end

function modifier_item_cursed_staff:OnAbilityExecuted(kv)
	if(kv.unit ~= self.parent) then
		return
	end
	if(kv.ability:GetCooldown(-1) > 0 and kv.ability:IsToggle() == false and kv.ability:IsItem() == false) then
		self:AddStackingBuff()
	end
end

function modifier_item_cursed_staff:GetEffectName()
	return "particles/custom/items/cursed_staff/ambient/ambient.vpcf"
end

function modifier_item_cursed_staff:AddStackingBuff()
	local particle = ParticleManager:CreateParticle(
		"particles/custom/items/cursed_staff/passive/effect.vpcf", 
		PATTACH_CUSTOMORIGIN, 
		self.parent
	)
	ParticleManager:SetParticleControlEnt(particle, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
	ParticleManager:SetParticleControl(particle, 1, Vector(self.parent:GetModelRadius(), 0, 0))
	ParticleManager:ReleaseParticleIndex(particle, 2)
	local modifier = self.parent:AddNewModifier(self.parent, self.item, "modifier_item_cursed_staff_stacks", {duration = self.buffDuration})
	if(modifier) then
		Timers:CreateTimer(modifier:GetDuration(), function()
			if(modifier and not modifier:IsNull()) then
				modifier:DecrementStackCount()
			end
		end)
		modifier:IncrementStackCount()
	end
end

modifier_item_cursed_staff_stacks = class({
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
		return false 
	end,
	GetTexture = function(self)
		return self.buffIcon
	end,
	DeclareFunctions = function() 
		return 
		{
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
		} 
	end
})

function modifier_item_cursed_staff_stacks:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self:OnRefresh()
	if(not IsServer()) then
		self.buffIcon = self.ability:GetAbilityTextureName()
	end
end

function modifier_item_cursed_staff_stacks:OnRefresh()
	self.ability = self:GetAbility() or self.ability
	if(not self.ability) then
		return
	end
	self.bonusMagicDamagePerStack = self.ability:GetSpecialValueFor("passive_outgoing_magic_dmg_per_stack")
end

function modifier_item_cursed_staff_stacks:GetModifierSpellAmplify_Percentage()
	return self.bonusMagicDamagePerStack * self:GetStackCount()
end

modifier_item_cursed_staff_buff = class({
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
		return false 
	end,
	DeclareFunctions = function() 
		return 
		{
			MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
			MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING,
			MODIFIER_PROPERTY_TOOLTIP
		} 
	end,
	GetEffectName = function()
		return "particles/custom/items/cursed_staff/cast/effect/effect.vpcf"
	end,
	DestroyOnExpire = function()
		return false
	end
})

function modifier_item_cursed_staff_buff:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self:OnRefresh()
	if(not IsServer()) then
		return
	end
	self:StartIntervalThink(self:GetDuration())
end

function modifier_item_cursed_staff_buff:OnRefresh()
	self.ability = self:GetAbility() or self.ability
	if(not self.ability) then
		return
	end
	self.maxStacks = self.ability:GetSpecialValueFor("active_stacks_limit")
	self.bonusManacostPctPerStack = self.ability:GetSpecialValueFor("active_manacost_increase_per_stack_pct") * -1
	self.bonusSpellAmpPctPerStack = self.ability:GetSpecialValueFor("active_spell_amp_increase_per_stack_pct")
	self.stacksPerTick = self.ability:GetSpecialValueFor("active_stacks_per_interval")
end

function modifier_item_cursed_staff_buff:OnIntervalThink()
	local newStacks = self:GetStackCount() + self.stacksPerTick
	if(newStacks > self.maxStacks) then
		self:StopStacks()
		return
	end
	self:SetStackCount(newStacks)
	self:ForceRefresh()
end

function modifier_item_cursed_staff_buff:GetModifierPercentageManacostStacking()
	return self:GetStackCount() * self.bonusManacostPctPerStack
end

function modifier_item_cursed_staff_buff:GetModifierTotalDamageOutgoing_Percentage(kv)
	if(kv.attacker ~= self.parent) then
		return
	end
	if(kv.damage_type == DAMAGE_TYPE_MAGICAL) then
		return self:GetBonusDamagePercentage()
	end
end

function modifier_item_cursed_staff_buff:GetBonusDamagePercentage()
	return self.bonusSpellAmpPctPerStack * self:GetStackCount()
end

function modifier_item_cursed_staff_buff:OnTooltip()
	return self:GetBonusDamagePercentage()
end

function modifier_item_cursed_staff_buff:StopStacks()
	self:SetDuration(-1, true)
	self:StartIntervalThink(-1)
	self:SetIsCanBeRemoved(true)
end

function modifier_item_cursed_staff_buff:IsCanBeRemoved()
	if(self._isCanBeRemoved ~= nil) then
		return self._isCanBeRemoved
	end
	return false
end

function modifier_item_cursed_staff_buff:SetIsCanBeRemoved(value)
	self._isCanBeRemoved = value
end

LinkLuaModifier("modifier_item_cursed_staff", "items/custom/item_cursed_staff", LUA_MODIFIER_MOTION_NONE, modifier_item_cursed_staff)
LinkLuaModifier("modifier_item_cursed_staff_buff", "items/custom/item_cursed_staff", LUA_MODIFIER_MOTION_NONE, modifier_item_cursed_staff_buff)
LinkLuaModifier("modifier_item_cursed_staff_stacks", "items/custom/item_cursed_staff", LUA_MODIFIER_MOTION_NONE, modifier_item_cursed_staff_stacks)