item_god_slayer = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_god_slayer"
    end
})

function item_god_slayer:Precache(context)
    PrecacheResource("particle", "particles/custom/items/god_slayer/effect.vpcf", context)
    PrecacheResource("particle", "particles/custom/items/god_slayer/effect_awaken.vpcf", context)
end

function item_god_slayer:IsRemoveSoulsOnDrop()
    return true
end

function item_god_slayer:GetParticle()
    return "particles/custom/items/god_slayer/effect.vpcf"
end

function item_god_slayer:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    caster:RemoveItem(self)
    caster:AddItemByName("item_awaken_god_slayer")
    EmitSoundOn("Item.GodSlayer.Cast", caster)
end

item_awaken_god_slayer = class(item_god_slayer)

function item_awaken_god_slayer:IsRemoveSoulsOnDrop()
    return false
end

function item_awaken_god_slayer:GetParticle()
    return "particles/custom/items/god_slayer/effect_awaken.vpcf"
end

function item_awaken_god_slayer:OnSpellStart()

end

modifier_item_god_slayer = class({
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
            MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
            MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
            MODIFIER_EVENT_ON_DEATH
        }
    end,
    GetModifierBaseDamageOutgoing_Percentage = function(self)
        return self.bonusAttackDamagePct
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_god_slayer:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    local particle = ParticleManager:CreateParticle(
        self.ability:GetParticle(), 
        PATTACH_ABSORIGIN_FOLLOW,
        self.parent
    )
    self:AddParticle(particle, false, false, 1, false, false)
    self.soulsModifier = self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_god_slayer_buff", {duration = -1})
end

function modifier_item_god_slayer:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAttackDamagePct = self.ability:GetSpecialValueFor("bonus_damage_pct")
    self.bonusIncomingDamagePctReduction = self.ability:GetSpecialValueFor("incoming_dmg_vs_gods_decrease_pct") * -1
    self.bonusOutgoingDamagePct = self.ability:GetSpecialValueFor("outgoing_dmg_vs_gods_increase_pct")
end

function modifier_item_god_slayer:GetModifierIncomingDamage_Percentage(kv)
    if(kv.target ~= self.parent) then
        return
    end
    if(kv.attacker:IsGod()) then
        return self.bonusIncomingDamagePctReduction
    end
    return 0
end

function modifier_item_god_slayer:GetModifierTotalDamageOutgoing_Percentage(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(kv.target:IsGod()) then
        return self.bonusOutgoingDamagePct
    end
    return 0
end

function modifier_item_god_slayer:OnDeath(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(kv.unit:IsGod() == false) then
        return
    end
    self.soulsModifier:IncrementStackCount()
end

function modifier_item_god_slayer:OnDestroy()
    if(not IsServer()) then
        return
    end
    if(self.ability:IsRemoveSoulsOnDrop() == false) then
        return
    end
    self.parent:RemoveModifierByName("modifier_item_god_slayer_buff")
end

modifier_item_god_slayer_buff = class({
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
            MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE
        }
    end,
    GetAttributes = function()
        return MODIFIER_ATTRIBUTE_PERMANENT
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_god_slayer_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_god_slayer_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusBaseDamagePerSoul = self.ability:GetSpecialValueFor("base_dmg_increase_per_soul")
end

function modifier_item_god_slayer_buff:GetModifierBaseAttack_BonusDamage(kv)
    return self:GetStackCount() * self.bonusBaseDamagePerSoul
end

LinkLuaModifier("modifier_item_god_slayer", "items/neutral_items/god_slayer", LUA_MODIFIER_MOTION_NONE, modifier_item_god_slayer)
LinkLuaModifier("modifier_item_god_slayer_buff", "items/neutral_items/god_slayer", LUA_MODIFIER_MOTION_NONE, modifier_item_god_slayer_buff)