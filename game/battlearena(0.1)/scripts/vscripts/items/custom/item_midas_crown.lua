require('items/generic_datadriven_item')


item_midas_crown = class({})

function item_midas_crown:Precache( context )
    PrecacheResource( "particle", "particles/custom/items_fx/midas_crown/leader_overhead.vpcf", context )
end

function item_midas_crown:GetIntrinsicModifierName()
	return "modifier_item_midas_crown"
end

function item_midas_crown:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")

	caster:AddNewModifier(caster, self, "modifier_item_midas_crown_buff", {duration = duration})
end

modifier_item_midas_crown = class({
    IsHidden = function() 
        return true 
    end,
    IsAura = function() 
        return true 
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    GetAuraRadius = function(self) 
        return self.aura_radius
    end,
    GetAuraSearchTeam = function(self) 
        return self.targetTeam
    end,
    GetAuraSearchType = function(self) 
        return self.targetType
    end,
    GetAuraSearchFlags = function(self)
        return self.targetFlags
    end,
    GetModifierAura = function() 
        return "modifier_item_midas_crown_aura" 
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        }
    end
})

function modifier_item_midas_crown:OnCreated()
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

function modifier_item_midas_crown:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")
    self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
end

function modifier_item_midas_crown:GetModifierConstantManaRegen()
    return self.bonus_mp_regen
end

function modifier_item_midas_crown:GetEffectName()
	return "particles/custom/items_fx/midas_crown/leader_overhead.vpcf"
end

function modifier_item_midas_crown:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

modifier_item_midas_crown_aura = class({
    IsHidden = function() 
        return false 
    end,
    IsPurgable = function()
        return false
    end,
    IsDebuff = function()
        return false    
    end,
    IsPurgeException = function()
        return false
    end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
    DeclareFunctions  = function() 
        return 
        {
            MODIFIER_EVENT_ON_DEATH
        }
    end
})

function modifier_item_midas_crown_aura:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_midas_crown_aura:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.reward_pct = self.ability:GetSpecialValueFor("reward_pct")
    self.reward_max = self.ability:GetSpecialValueFor("reward_max")
end

function modifier_item_midas_crown_aura:OnDeath(data)
    local caster = self:GetCaster()
	local parent = self:GetParent()
	local attacker = data.attacker
	local unit = data.unit
    local ability = self:GetAbility()
    local parent_owner = parent:GetOwner()
    local caster_owner = caster:GetOwner() 

    if parent == attacker and parent_owner ~= caster_owner then
		local gold = unit:GetGoldBounty()*self.reward_pct
		if not caster:HasModifier("modifier_item_midas_crown_buff") then
			if gold >= self.reward_max then
				gold = reward_max
			end
		end
		local player = PlayerResource:GetPlayer(caster:GetPlayerID())
		SendOverheadEventMessage( player, OVERHEAD_ALERT_GOLD, caster, gold, nil )
		caster:ModifyGoldFiltered(gold, false, DOTA_ModifyGold_CreepKill)
   end
end

modifier_item_midas_crown_buff = class({
	IsHidden 				= function(self) return false end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return true end,
})

item_midas_crown_1 = class(item_midas_crown)
item_midas_crown_2 = class(item_midas_crown)
item_midas_crown_3 = class(item_midas_crown)
item_midas_crown_4 = class(item_midas_crown)


LinkLuaModifier("modifier_item_midas_crown", "items/custom/item_midas_crown", LUA_MODIFIER_MOTION_NONE ,  modifier_item_midas_crown)
LinkLuaModifier("modifier_item_midas_crown_aura", "items/custom/item_midas_crown", LUA_MODIFIER_MOTION_NONE ,  modifier_item_midas_crown_aura)
LinkLuaModifier("modifier_item_midas_crown_buff", "items/custom/item_midas_crown", LUA_MODIFIER_MOTION_NONE ,  modifier_item_midas_crown_buff)
