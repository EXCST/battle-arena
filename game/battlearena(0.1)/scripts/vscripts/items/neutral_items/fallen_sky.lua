item_fallen_sky_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_fallen_sky_custom"
    end,
    GetAOERadius = function(self)
        return self:GetSpecialValueFor("impact_radius")
    end
})

function item_fallen_sky_custom:Precache(context)
    PrecacheResource("particle", "particles/custom/items/fallen_sky/fallen_sky.vpcf", context)
    PrecacheResource("particle", "particles/items4_fx/meteor_hammer_spell_debuff.vpcf", context)
end

function item_fallen_sky_custom:CastFilterResultLocation(location)
    if(not IsServer()) then
        return UF_SUCCESS
    end
    local caster = self:GetCaster()
    if(GridNav:CanFindPathForUnitIncludingTeleports(caster, location) == false) then
		return UF_FAIL_CUSTOM
	end
    return UF_SUCCESS
end

function item_fallen_sky_custom:GetCustomCastErrorLocation(location)
    return "roshdef_hud_error_invalid_location"
end

function item_fallen_sky_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_item_fallen_sky_custom_flying", {duration = -1})
end

modifier_item_fallen_sky_custom = class({
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
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
        }
    end,
    GetModifierConstantHealthRegen = function(self)
        return self.bonusHealthRegeneration
    end,
    GetModifierConstantManaRegen = function(self)
        return self.bonusManaRegeneration
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.bonusStr
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusInt
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_fallen_sky_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_fallen_sky_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealthRegeneration = self.ability:GetSpecialValueFor("bonus_health_regen")
    self.bonusManaRegeneration = self.ability:GetSpecialValueFor("bonus_mana_regen")
    self.bonusStr = self.ability:GetSpecialValueFor("bonus_strength")
    self.bonusInt = self.ability:GetSpecialValueFor("bonus_intellect")
end

modifier_item_fallen_sky_custom_flying = class({
    IsHidden = function() 
        return true 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    CheckState = function()
        return {
            [MODIFIER_STATE_DISARMED] = true,
            [MODIFIER_STATE_SILENCED] = true,
            [MODIFIER_STATE_INVULNERABLE] = true,
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
            [MODIFIER_STATE_STUNNED] = true
        }
    end,
    IsPurgeException = function()
        return false
    end
})

function modifier_item_fallen_sky_custom_flying:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    if(not IsServer()) then
        return
    end
    self.debuffDuration = self.ability:GetSpecialValueFor("burn_duration")
    self.stunDuration = self.ability:GetSpecialValueFor("stun_duration")
    self.stunDurationBuildings = self.ability:GetSpecialValueFor("stun_duration_structures")
    self.landTime = self.ability:GetSpecialValueFor("land_time")
    self.impactRadius = self.ability:GetSpecialValueFor("impact_radius")
    self.targetPosition = GetGroundPosition(self.ability:GetCursorPosition(), nil)
    self.damageTable = {
        victim = nil,
        attacker = self.parent,
        ability = self.ability,
        damage = self.ability:GetSpecialValueFor("impact_damage"),
        damage_type = self.ability:GetAbilityDamageType()
    }
    local pidx = ParticleManager:CreateParticle("particles/custom/items/fallen_sky/fallen_sky.vpcf", PATTACH_WORLDORIGIN, self.parent)
    ParticleManager:SetParticleControl(pidx, 0, self.targetPosition + Vector(0, 0, 1000))
    ParticleManager:SetParticleControl(pidx, 1, self.targetPosition)
    ParticleManager:SetParticleControl(pidx, 2, Vector(self.landTime, 0, 0))
    ParticleManager:ReleaseParticleIndex(pidx, self.landTime)
    AddFOWViewer(self.parent:GetTeamNumber(), self.targetPosition, self.impactRadius, self.landTime, false)
    self.particle = pidx
    self.parent:AddNoDraw()
    EmitSoundOn("Item.FallenSky.Cast", self.parent)
    self:StartIntervalThink(self.landTime)
end

function modifier_item_fallen_sky_custom_flying:OnIntervalThink()
    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(), 
        self.targetPosition, 
        nil, 
        self.impactRadius, 
        self.ability:GetAbilityTargetTeam(), 
        self.ability:GetAbilityTargetType(), 
        self.ability:GetAbilityTargetFlags(), 
        FIND_ANY_ORDER, 
        false
    )
    for _, enemy in pairs(enemies) do
        self.damageTable.victim = enemy
        ApplyDamage(self.damageTable)
        enemy:AddNewModifier(self.parent, self.ability, "modifier_item_fallen_sky_custom_debuff", {duration = self.debuffDuration})
        local stunDuration = self.stunDuration
        if(enemy:IsBuilding() == true) then
            stunDuration = self.stunDurationBuildings
        end
        enemy:AddNewModifier(self.parent, self.ability, "modifier_stunned", {duration = stunDuration})
    end
    FindClearSpaceForUnit(self.parent, self.targetPosition, true)
    FindClosestValidLocationForUnit(self.parent)
    self:Destroy()
end

function modifier_item_fallen_sky_custom_flying:OnDestroy()
    if(not IsServer()) then
        return
    end
    StopSoundOn("Item.FallenSky.Cast", self.parent)
    EmitSoundOn("Item.FallenSky.Impact", self.parent)
    self.parent:RemoveNoDraw()
end

modifier_item_fallen_sky_custom_debuff = class({
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
    GetEffectName = function()
        return "particles/items4_fx/meteor_hammer_spell_debuff.vpcf"
    end
})

function modifier_item_fallen_sky_custom_debuff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    StartSoundEvent("Item.FallenSky.Damage", self.parent)
end

function modifier_item_fallen_sky_custom_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    if(not IsServer()) then
        return
    end
    self.burnDamagePerSecond = self.ability:GetSpecialValueFor("burn_dps")
    self.tickInterval = self.ability:GetSpecialValueFor("burn_interval")
    if(self.parent:IsBuilding() == true) then
        self.burnDamagePerSecond = self.burnDamagePerSecond * (self.ability:GetSpecialValueFor("structures_bonus_damage_pct") / 100)
    end
    self.burnDamagePerSecond = self.burnDamagePerSecond * self.tickInterval
    self.damageTable = self.damageTable or {
        victim = self.parent,
        attacker = self.ability:GetCaster(),
        ability = self.ability,
        damage = self.burnDamagePerSecond,
        damage_type = self.ability:GetAbilityDamageType()
    }
    self:StartIntervalThink(self.tickInterval)
end

function modifier_item_fallen_sky_custom_debuff:OnIntervalThink()
    local damageDone = ApplyDamage(self.damageTable)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, self.parent, damageDone, nil)
end

function modifier_item_fallen_sky_custom_debuff:OnDestroy()
    if(not IsServer()) then
        return
    end
    StopSoundEvent("Item.FallenSky.Damage", self.parent)
end

LinkLuaModifier("modifier_item_fallen_sky_custom", "items/neutral_items/fallen_sky", LUA_MODIFIER_MOTION_NONE, modifier_item_fallen_sky_custom)
LinkLuaModifier("modifier_item_fallen_sky_custom_flying", "items/neutral_items/fallen_sky", LUA_MODIFIER_MOTION_NONE, modifier_item_fallen_sky_custom_flying)
LinkLuaModifier("modifier_item_fallen_sky_custom_debuff", "items/neutral_items/fallen_sky", LUA_MODIFIER_MOTION_NONE, modifier_item_fallen_sky_custom_debuff)