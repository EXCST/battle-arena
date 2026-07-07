item_longclaws_amulet_custom = class({
    GetCastRange = function(self)
        return self:GetSpecialValueFor("radius")
    end,
    GetIntrinsicModifierName = function()
        return "modifier_item_longclaws_amulet_custom"
    end
})

function item_longclaws_amulet_custom:Precache(context)
    PrecacheResource("particle", "particles/custom/items/longsclaw_amulet/affected_unit.vpcf", context)
    PrecacheResource("particle", "particles/custom/items/longsclaw_amulet/effect.vpcf", context)
end

function item_longclaws_amulet_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local playerID = caster:GetPlayerOwnerID()
    local radius = self:GetCastRange()
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(), 
        caster:GetAbsOrigin(), 
        nil, 
        radius, 
        self:GetAbilityTargetTeam(), 
        self:GetAbilityTargetType(), 
        self:GetAbilityTargetFlags(), 
        FIND_ANY_ORDER, 
        false
    )
    local attackDamageStealPct = self:GetSpecialValueFor("damage_steal_pct") / 100
    local healthStealPct = self:GetSpecialValueFor("hp_steal_pct") / 100
    local bonusDamage = 0
    local bonusHealth = 0
    local maxEnemiesAffected = self:GetSpecialValueFor("max_stacks") - 1
    local currentEnemiesAffected = 0
    local buffDuration = self:GetSpecialValueFor("duration")
    for _, enemy in pairs(enemies) do
        if(currentEnemiesAffected > maxEnemiesAffected) then
            break
        else
            if(enemy:IsBoss() == false) then
                bonusHealth = bonusHealth + (enemy:GetMaxHealth() * healthStealPct)
                bonusDamage = bonusDamage + (enemy:GetAttackDamage() * attackDamageStealPct)
                enemy:AddNewModifier(caster, self, "modifier_item_longclaws_amulet_custom_debuff", {duration = buffDuration})
                local particle = ParticleManager:CreateParticle(
                    "particles/custom/items/longsclaw_amulet/affected_unit.vpcf", 
                    PATTACH_CUSTOMORIGIN, 
                    nil
                )
                ParticleManager:SetParticleControlEnt(particle, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
                ParticleManager:ReleaseParticleIndex(particle, 2)
            end
        end
        currentEnemiesAffected = currentEnemiesAffected + 1
    end
    local particle = ParticleManager:CreateParticle(
        "particles/custom/items/longsclaw_amulet/effect.vpcf", 
        PATTACH_ABSORIGIN, 
        caster
    )
    ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
    ParticleManager:ReleaseParticleIndex(particle, 2)
    EmitSoundOn("Item.LongClawsAmulet.Cast", caster)
    local mod = caster:AddNewModifier(caster, self, "modifier_item_longclaws_amulet_custom_buff", {duration = buffDuration})
    mod:SetBonusDamageFromActive(bonusDamage)
    mod:SetBonusHealthFromActive(bonusHealth)
    mod:SendBuffRefreshToClients()
    if(caster.CalculateStatBonus) then
        caster:CalculateStatBonus(true)
    else
        caster:CalculateGenericBonuses()
    end
end

modifier_item_longclaws_amulet_custom = class({
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
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_longclaws_amulet_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_longclaws_amulet_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealth = self.ability:GetSpecialValueFor("bonus_health")
    self.bonusDamage = self.ability:GetSpecialValueFor("bonus_damage")
end

function modifier_item_longclaws_amulet_custom:GetModifierBonusHealth()
    return self.bonusHealth
end

function modifier_item_longclaws_amulet_custom:GetModifierPreAttack_BonusDamage()
    return self.bonusDamage
end

modifier_item_longclaws_amulet_custom_buff = class({
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
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    RemoveOnDeath = function()
        return false
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_longclaws_amulet_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
        return
    end
    self:SetHasCustomTransmitterData(true)
end

function modifier_item_longclaws_amulet_custom_buff:GetModifierBonusHealth()
    return self:GetBonusHealthFromActive()
end

function modifier_item_longclaws_amulet_custom_buff:GetModifierPreAttack_BonusDamage()
    return self:GetBonusDamageFromActive()
end

function modifier_item_longclaws_amulet_custom_buff:GetBonusHealthFromActive()
    return self._bonusHealthFromActive or 0
end

function modifier_item_longclaws_amulet_custom_buff:SetBonusHealthFromActive(value)
    self._bonusHealthFromActive = value
end

function modifier_item_longclaws_amulet_custom_buff:GetBonusDamageFromActive()
    return self._bonusDamageFromActive or 0
end

function modifier_item_longclaws_amulet_custom_buff:SetBonusDamageFromActive(value)
    self._bonusDamageFromActive = value
end

function modifier_item_longclaws_amulet_custom_buff:AddCustomTransmitterData()
    return
    {
        _bonusHealthFromActive = self._bonusHealthFromActive,
        _bonusDamageFromActive = self._bonusDamageFromActive
    }
end

function modifier_item_longclaws_amulet_custom_buff:HandleCustomTransmitterData(data)
    self._bonusHealthFromActive = data._bonusHealthFromActive
    self._bonusDamageFromActive = data._bonusDamageFromActive
end

modifier_item_longclaws_amulet_custom_debuff = class({
    IsHidden = function() 
        return false 
    end,
    IsDebuff = function()
        return true
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
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH_PERCENTAGE
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    GetModifierBaseDamageOutgoing_Percentage = function(self)
        return self.bonusDamage
    end,
    GetModifierSpellAmplify_Percentage = function(self)
        return self.bonusDamage
    end,
    GetModifierBonusHealthPercentage = function(self)
        return self.bonusHealthPct
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_longclaws_amulet_custom_debuff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    end
end

function modifier_item_longclaws_amulet_custom_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusDamage = self.ability:GetSpecialValueFor("damage_steal_pct") * -1
    self.bonusHealthPct = self.ability:GetSpecialValueFor("hp_steal_pct") * -1
end

LinkLuaModifier("modifier_item_longclaws_amulet_custom", "items/neutral_items/longclaws_amulet", LUA_MODIFIER_MOTION_NONE, modifier_item_longclaws_amulet_custom)
LinkLuaModifier("modifier_item_longclaws_amulet_custom_buff", "items/neutral_items/longclaws_amulet", LUA_MODIFIER_MOTION_NONE, modifier_item_longclaws_amulet_custom_buff)
LinkLuaModifier("modifier_item_longclaws_amulet_custom_debuff", "items/neutral_items/longclaws_amulet", LUA_MODIFIER_MOTION_NONE, modifier_item_longclaws_amulet_custom_debuff)