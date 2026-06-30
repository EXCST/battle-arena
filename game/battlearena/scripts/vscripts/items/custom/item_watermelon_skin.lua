require('items/generic_datadriven_item')


item_watermelon_skin = class({
	GetIntrinsicModifierName = function(self) return "modifier_item_watermelon_skin_passive" end,
})

function item_watermelon_skin:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_treant/treant_overgrowth_vines.vpcf", context)
	PrecacheModel("models/event/arbus/arbuz.vmdl", context)
end

function item_watermelon_skin:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	if(caster:GetUnitName() == "npc_dota_hero_tidehunter") then
		caster:AddNewModifier(caster, self, "modifier_item_watermelon_skin_effect_tidehunter", {duration = -1, tidehunter = true})
		EmitSoundOn("tidehunter_tide_level_25", caster)
		self:Destroy()
		return
	end
	caster:AddNewModifier(caster, self, "modifier_item_watermelon_skin_effect", { duration = duration})
	EmitSoundOn("Hero_Treant.Overgrowth.Cast", caster)
end

modifier_item_watermelon_skin_passive = class({
	IsHidden = function()
		return true
	end,
	DeclareFunctions = function() 
		return 
		{
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
	end,
	RemoveOnDeath = function()
		return false
	end,
	GetModifierConstantHealthRegen = function(self)
		return self.bonusHealthRegeneration
	end,
	GetTexture = function(self) 
		return self.buffIcon 
	end
})

function modifier_item_watermelon_skin_passive:GetModifierBonusHealth()
	return self.bonusHealth
end

function modifier_item_watermelon_skin_passive:OnCreated(kv)
	self.parent = self:GetParent()
	self:OnRefresh()
	if(not IsServer()) then
		self.buffIcon = self:GetAbility():GetAbilityTextureName()
		return
	end
end

function modifier_item_watermelon_skin_passive:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability) then
        return
    end
    self.bonusHealth = self.ability:GetSpecialValueFor("bonus_health")
    self.bonusHealthRegeneration = self.ability:GetSpecialValueFor("bonus_regen")
end

modifier_item_watermelon_skin_effect = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	IsDebuff = function() return false end,
	IsBuff = function() return true end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MODEL_CHANGE,
	
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } end,
	GetModifierModelChange = function() return "models/event/arbus/arbuz.vmdl" end,
	GetEffectName = function() return "particles/units/heroes/hero_treant/treant_overgrowth_vines.vpcf" end,
	GetTexture = function(self) return self.buffIcon end
})

function modifier_item_watermelon_skin_effect:OnCreated()
	self:OnRefresh()
	if(not IsServer()) then
		self.buffIcon = self:GetAbility():GetAbilityTextureName()
		return
	end
end

function modifier_item_watermelon_skin_effect:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability) then
        return
    end
    self.bonusRegen = self.ability:GetSpecialValueFor("buff_regen")
end

function modifier_item_watermelon_skin_effect:GetModifierConstantHealthRegen()
	return self.bonusRegen
end

modifier_item_watermelon_skin_effect_tidehunter = class(modifier_item_watermelon_skin_passive)

function modifier_item_watermelon_skin_effect_tidehunter:IsHidden()
	return false
end


LinkLuaModifier("modifier_item_watermelon_skin_passive", "items/custom/item_watermelon_skin", LUA_MODIFIER_MOTION_NONE, modifier_item_watermelon_skin_passive)
LinkLuaModifier("modifier_item_watermelon_skin_effect", "items/custom/item_watermelon_skin", LUA_MODIFIER_MOTION_NONE, modifier_item_watermelon_skin_effect)
LinkLuaModifier("modifier_item_watermelon_skin_effect_tidehunter", "items/custom/item_watermelon_skin", LUA_MODIFIER_MOTION_NONE, modifier_item_watermelon_skin_effect_tidehunter)
