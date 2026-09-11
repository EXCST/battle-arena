require('items/generic_datadriven_item')

item_golem_heart = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_golem_heart"
    end
})

function item_golem_heart:Precache(context)
    PrecacheResource("particle", "particles/custom/items/golem_heart/buff/buff.vpcf", context)
end

function item_golem_heart:OnSpellStart()
    local caster = self:GetCaster()
    local buff_duration = self:GetSpecialValueFor("buff_duration")
    caster:AddNewModifier(caster, self, "modifier_item_golem_heart_buff", {duration = buff_duration})
    EmitSoundOn("GolemHeart.Activate", caster)
end

item_golem_heart_1 = class(item_golem_heart)
item_golem_heart_2 = class(item_golem_heart)
item_golem_heart_3 = class(item_golem_heart)

modifier_item_golem_heart = class({
    IsHidden = function() 
        return true 
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
	GetAttributes = function() 
        return MODIFIER_ATTRIBUTE_MULTIPLE 
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_golem_heart:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_golem_heart:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_armor = self.ability:GetSpecialValueFor("bonus_armor")
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
end

function modifier_item_golem_heart:GetModifierPhysicalArmorBonus()
    return self.bonus_armor
end

function modifier_item_golem_heart:GetModifierBonusHealth()
	return self.bonus_health
end

modifier_item_golem_heart_buff = class({
    IsHidden = function() 
        return false 
    end,
    IsPurgable = function()
        return false
    end,
    IsDebuff = function()
        return false    
    end,
    DeclareFunctions  = function() 
        return 
        {
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_golem_heart_buff:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
    if(IsClient()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    else
        self.parent = self:GetParent()
        local particle = ParticleManager:CreateParticle("particles/custom/items/golem_heart/buff/buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControlEnt(particle, 0, self.parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
        ParticleManager:SetParticleControlEnt(particle, 1, self.parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
        ParticleManager:SetParticleControl(particle, 3, Vector(50, 0, 0))
        ParticleManager:SetParticleControl(particle, 5, Vector(0, 0, 0))
        ParticleManager:SetParticleControl(particle, 8, Vector(50, 0, 0))
        self:AddParticle(particle, false, false, 1, false, false)
    end
end

function modifier_item_golem_heart_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.buff_armor = self.ability:GetSpecialValueFor("buff_armor")
end

function modifier_item_golem_heart_buff:GetModifierPhysicalArmorBonus()
    return self.buff_armor
end

LinkLuaModifier("modifier_item_golem_heart", "items/item_golem_heart", LUA_MODIFIER_MOTION_NONE, modifier_item_golem_heart)
LinkLuaModifier("modifier_item_golem_heart_buff", "items/item_golem_heart", LUA_MODIFIER_MOTION_NONE, modifier_item_golem_heart_buff)