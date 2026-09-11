require('items/generic_datadriven_item')


item_medusa_head = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_medusa_head_handler"
	end,
	GetDebuffModifierName = function()
		return "modifier_item_medusa_head_debuff"
	end,
	GetStunModifierName = function()
		return "modifier_item_medusa_head_petrification"
	end
})

function item_medusa_head:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_medusa_stone_gaze.vpcf", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_medusa.vsndevts", context)
end

function item_medusa_head:OnSpellStart()
	if (not IsServer()) then
		return
	end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local debuffDuration = self:GetSpecialValueFor("stone_duration")
	target:AddNewModifier(caster, self, self:GetDebuffModifierName(), {duration = debuffDuration})
	target:AddNewModifier(caster, self, self:GetStunModifierName(), {duration = debuffDuration})
end

item_watchers_gaze = class(item_medusa_head)

function item_watchers_gaze:GetDebuffModifierName()
	return "modifier_item_watchers_gaze_debuff"
end

function item_watchers_gaze:GetStunModifierName()
	return "modifier_item_watchers_gaze_petrification"
end

modifier_item_medusa_head_handler = class({
	IsHidden = function()
		return true
	end,
	IsPurgable = function()
		return false
	end,
	IsPermanent = function()
		return true
	end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
		}
	end,
	GetModifierPhysicalArmorBonus = function(self)
		return self.bonus_armor
	end,
	GetModifierBonusStats_Strength = function(self)
		return self.bonus_stats
	end,
	GetModifierBonusStats_Agility = function(self)
		return self.bonus_stats
	end,
	GetModifierBonusStats_Intellect = function(self)
		return self.bonus_stats
	end
})

function modifier_item_medusa_head_handler:OnCreated(kv)
	self.ability = self:GetAbility()
	self.bonus_armor = self.ability:GetSpecialValueFor("bonus_armor")
	self.bonus_stats = self.ability:GetSpecialValueFor("bonus_stats")
end


modifier_item_medusa_head_debuff = class({
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
	RemoveOnDeath = function() 
		return true 
	end,
	GetTexture = function(self)
		return self.icon
	end,
	GetModifierIncomingPhysicalDamage_Percentage = function(self)
		return self.bonus_physical_damage
	end
})

function modifier_item_medusa_head_debuff:OnCreated(data)
	self.ability = self:GetAbility()
	if(IsClient()) then
		self.icon = self.ability:GetAbilityTextureName()
	else
		local parent = self:GetParent()
		parent:EmitSound("Hero_Medusa.StoneGaze.Target")
		parent:EmitSound("Hero_Medusa.StoneGaze.Stun")
	end
	self.bonus_physical_damage = self.ability:GetSpecialValueFor("bonus_physical_damage")
end

modifier_item_watchers_gaze_debuff = class(modifier_item_medusa_head_debuff)

modifier_item_medusa_head_petrification = class({
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
	RemoveOnDeath = function() 
		return true 
	end,
	CheckState = function()
		return {
			[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_FROZEN] = true,
		}
	end,
	GetTexture = function(self)
		return self.icon
	end
})

function modifier_item_medusa_head_petrification:GetEffectName()
	return "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf"
end

function modifier_item_medusa_head_petrification:GetStatusEffectName()
	return "particles/status_fx/status_effect_medusa_stone_gaze.vpcf"
end

function modifier_item_medusa_head_petrification:StatusEffectPriority()
	return MODIFIER_PRIORITY_ULTRA
end

function modifier_item_medusa_head_petrification:OnCreated(data)
	self.ability = self:GetAbility()
	if(IsClient()) then
		self.icon = self.ability:GetAbilityTextureName()
	end
end

modifier_item_watchers_gaze_petrification = class(modifier_item_medusa_head_petrification)


LinkLuaModifier("modifier_item_medusa_head_handler", "items/custom/item_medusa_head", LUA_MODIFIER_MOTION_NONE, modifier_item_medusa_head_handler)
LinkLuaModifier("modifier_item_medusa_head_petrification", "items/custom/item_medusa_head", LUA_MODIFIER_MOTION_NONE, modifier_item_medusa_head_petrification)
LinkLuaModifier("modifier_item_medusa_head_debuff", "items/custom/item_medusa_head", LUA_MODIFIER_MOTION_NONE, modifier_item_medusa_head_debuff)
LinkLuaModifier("modifier_item_watchers_gaze_debuff", "items/custom/item_medusa_head", LUA_MODIFIER_MOTION_NONE, modifier_item_watchers_gaze_debuff)
LinkLuaModifier("modifier_item_watchers_gaze_petrification", "items/custom/item_medusa_head", LUA_MODIFIER_MOTION_NONE, modifier_item_watchers_gaze_petrification)
