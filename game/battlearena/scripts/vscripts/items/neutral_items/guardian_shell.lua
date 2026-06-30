item_guardian_shell_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_guardian_shell_custom"
    end
})

function item_guardian_shell_custom:Precache(context)
    PrecacheResource("particle", "particles/custom/items/guardian_shell/effect.vpcf", context)
    PrecacheResource("particle", "particles/custom/items/guardian_shell/passive/passive.vpcf", context)
end

modifier_item_guardian_shell_custom = class({
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
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_INCOMING_DAMAGE_RESISTANCE_PERCENTAGE,
            MODIFIER_PROPERTY_TOOLTIP
        }
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.bonusStr
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusInt
    end,
    OnTooltip = function(self)
        return self:GetModifierIncomingDamageResistance_Percentage()
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_guardian_shell_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.lastDamageTime = GameRules:GetGameTime()
end

function modifier_item_guardian_shell_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusStr = self.ability:GetSpecialValueFor("bonus_strenght")
    self.bonusInt = self.ability:GetSpecialValueFor("bonus_intellect")
    self.maxStacks = self.ability:GetSpecialValueFor("shield_max_stacks")
    self.damageReductionPerStack = self.ability:GetSpecialValueFor("damage_reduction_per_stack")
    self.shieldDestructionDelay = self.ability:GetSpecialValueFor("shield_destruction_delay")
    if(not IsServer()) then
        return
    end
    self:StartIntervalThink(self.ability:GetSpecialValueFor("shield_restoration_time"))
end

function modifier_item_guardian_shell_custom:OnIntervalThink()
    self:SetStackCount(math.min(self.maxStacks, self:GetStackCount() + 1))
end

function modifier_item_guardian_shell_custom:OnDestroy()
    if(not IsServer()) then
        return
    end
    self:ShowParticle(false)
end

function modifier_item_guardian_shell_custom:_DestroyParticle()
    if(self._particle) then
        ParticleManager:ReleaseParticleIndex(self._particle)
    end
    self._particle = nil
end

function modifier_item_guardian_shell_custom:ShowParticle(visible)
    self:_DestroyParticle()
    if(visible == true) then
        self._particle = ParticleManager:CreateParticle(
            "particles/custom/items/guardian_shell/passive/passive.vpcf", 
            PATTACH_CUSTOMORIGIN,
            nil
        )
        ParticleManager:SetParticleControlEnt(self._particle, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    end
end

function modifier_item_guardian_shell_custom:OnStackCountChanged()
    if(not IsServer()) then
        return
    end
    self:ShowParticle(self:GetStackCount() > 0)
end

function modifier_item_guardian_shell_custom:GetModifierIncomingDamageResistance_Percentage(kv)
    return self:GetStackCount() * self.damageReductionPerStack
end

function modifier_item_guardian_shell_custom:GetModifierIncomingDamage_Percentage(kv)
    local gameTime = GameRules:GetGameTime()
    if(gameTime - self.lastDamageTime > self.shieldDestructionDelay) then
        local newStacks = self:GetStackCount() - 1
        self:SetStackCount(math.max(0, newStacks))
        self.lastDamageTime = gameTime
        if(newStacks >= 0) then
            local particle = ParticleManager:CreateParticle(
                "particles/custom/items/guardian_shell/effect.vpcf", 
                PATTACH_CUSTOMORIGIN,
                nil
            )
            ParticleManager:SetParticleControlEnt(particle, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
            ParticleManager:ReleaseParticleIndex(particle, 2)
            EmitSoundOn("Item.GuardianShell.Proc", self.parent)
            return -99999
        end
    end
    return 0
end

LinkLuaModifier("modifier_item_guardian_shell_custom", "items/neutral_items/guardian_shell", LUA_MODIFIER_MOTION_NONE, modifier_item_guardian_shell_custom)