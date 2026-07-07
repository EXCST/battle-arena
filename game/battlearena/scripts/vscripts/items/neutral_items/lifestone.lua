item_lifestone_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_lifestone_custom"
    end
})

function item_lifestone_custom:Precache(context)
    PrecacheResource("particle", "particles/custom/items/lifestone/effect.vpcf", context)
end

function item_lifestone_custom:OnToggle()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local mod = caster:FindModifierByName("modifier_item_lifestone_custom_buff")
    if(mod) then
        mod:Destroy()
        EmitSoundOn("Item.Lifestone.DeActivate", caster)
    else
        caster:AddNewModifier(caster, self, "modifier_item_lifestone_custom_buff", {duration = -1})
        EmitSoundOn("Item.Lifestone.Activate", caster)
    end
end

modifier_item_lifestone_custom = class({
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
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_lifestone_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_lifestone_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealth = self.ability:GetSpecialValueFor("bonus_health")
    self.bonusMana = self.ability:GetSpecialValueFor("bonus_mana")
end

function modifier_item_lifestone_custom:OnDestroy()
    if(not IsServer()) then
        return
    end
    self.parent:RemoveModifierByName("modifier_item_lifestone_custom_buff")
end

function modifier_item_lifestone_custom:GetModifierBonusHealth()
		return self.bonusHealth
end

function modifier_item_lifestone_custom:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return self.bonusMana
	end
	return 0
end

function modifier_item_lifestone_custom:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return 0
	end
    return self.bonusMana
end

modifier_item_lifestone_custom_buff = class({
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
    end
})

function modifier_item_lifestone_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    local particle = ParticleManager:CreateParticle(
        "particles/custom/items/lifestone/effect.vpcf",
        PATTACH_CUSTOMORIGIN,
        self.parent
    )
    ParticleManager:SetParticleControlEnt(particle, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    ParticleManager:SetParticleControlEnt(particle, 2, self.parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    self:AddParticle(particle, false, false, 1, false, false)
end

function modifier_item_lifestone_custom_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    local tickInterval = self.ability:GetSpecialValueFor("tick_interval")
    self.healthPerTick = self.ability:GetSpecialValueFor("hp_drain_per_sec") * tickInterval
    self.manaPerTick = self.ability:GetSpecialValueFor("mana_received_per_sec") * tickInterval
    if(not IsServer()) then
        return
    end
    self:StartIntervalThink(tickInterval)
end

function modifier_item_lifestone_custom_buff:OnIntervalThink()
    -- idk how they bug that, but they managed to do it...
    if(self.parent:HasModifier("modifier_item_lifestone_custom") == false) then
        self:Destroy()
        return
    end
    self.parent:ModifyHealth(
        self.parent:GetHealth() - self.healthPerTick, 
        self.ability, 
        true, 
        DOTA_DAMAGE_FLAG_BYPASSES_BLOCK + DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION 
        + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL
    )
    self.parent:GiveMana(self.manaPerTick)
end

LinkLuaModifier("modifier_item_lifestone_custom", "items/neutral_items/lifestone", LUA_MODIFIER_MOTION_NONE, modifier_item_lifestone_custom)
LinkLuaModifier("modifier_item_lifestone_custom_buff", "items/neutral_items/lifestone", LUA_MODIFIER_MOTION_NONE, modifier_item_lifestone_custom_buff)