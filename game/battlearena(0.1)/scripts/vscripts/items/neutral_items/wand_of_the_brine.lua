item_wand_of_the_brine_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_wand_of_the_brine_custom"
    end
})

function item_wand_of_the_brine_custom:Precache(context)
    PrecacheResource("particle", "particles/custom/items/wand_of_brine/buff.vpcf", context)
end

function item_wand_of_the_brine_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    target:AddNewModifier(caster, self, "modifier_item_wand_of_the_brine_custom_buff", {duration = self:GetSpecialValueFor("bubble_duration")})
    EmitSoundOn("Item.WandOfBrine.Cast", target)
end

modifier_item_wand_of_the_brine_custom = class({
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
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
        }
    end,
    GetModifierConstantManaRegen = function(self)
        return self.bonusManaRegeneration
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusInt
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_wand_of_the_brine_custom:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_wand_of_the_brine_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusManaRegeneration = self.ability:GetSpecialValueFor("bonus_mana_regeneration")
    self.bonusInt = self.ability:GetSpecialValueFor("bonus_int")
end

modifier_item_wand_of_the_brine_custom_buff = class({
    IsHidden = function() 
        return false 
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MAX
        }
    end,
    CheckState = function()
        return {
            [MODIFIER_STATE_DISARMED] = true,
            [MODIFIER_STATE_SILENCED] = true,
            [MODIFIER_STATE_INVULNERABLE] = true
        }
    end,
    GetModifierHPRegenAmplify_Percentage = function(self)
        return self.bonusHpRegenAmplify
    end,
    GetModifierMPRegenAmplify_Percentage = function(self)
        return self.bonusMpRegenAmplify
    end,
    GetModifierMoveSpeed_AbsoluteMax = function(self)
        return self.movespeedCap
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_wand_of_the_brine_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
        return
    end
    local particle = ParticleManager:CreateParticle(
        "particles/custom/items/wand_of_brine/buff.vpcf", 
        PATTACH_CUSTOMORIGIN, 
        nil
    )
    ParticleManager:SetParticleControlEnt(particle, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    ParticleManager:SetParticleControl(particle, 1, Vector(0.81, 0.81, 0.81))
    ParticleManager:SetParticleControlEnt(particle, 3, self.parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    self:AddParticle(particle, false, false, 1, false, false)
end

function modifier_item_wand_of_the_brine_custom_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHpRegenAmplify = self.ability:GetSpecialValueFor("bouble_hp_regen_amp_pct")
    self.bonusMpRegenAmplify = self.ability:GetSpecialValueFor("bouble_mp_regen_amp_pct")
    self.movespeedCap = self.ability:GetSpecialValueFor("bouble_movement_speed")
end

LinkLuaModifier("modifier_item_wand_of_the_brine_custom", "items/neutral_items/wand_of_the_brine", LUA_MODIFIER_MOTION_NONE, modifier_item_wand_of_the_brine_custom)
LinkLuaModifier("modifier_item_wand_of_the_brine_custom_buff", "items/neutral_items/wand_of_the_brine", LUA_MODIFIER_MOTION_NONE, modifier_item_wand_of_the_brine_custom_buff)
