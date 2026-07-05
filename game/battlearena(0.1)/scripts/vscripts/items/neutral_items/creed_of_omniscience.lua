item_creed_of_omniscience_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_creed_of_omniscience_custom"
    end
})

function item_creed_of_omniscience_custom:Precache(context)
    PrecacheUnitByNameSync("npc_creed_of_omniscience_ward", context)
    PrecacheResource("particle", "particles/custom/items/creed_of_omniscience/ward/ward.vpcf", context)
    PrecacheResource("particle", "particles/custom/items/creed_of_omniscience/ward/ward_projectile.vpcf", context)
    PrecacheResource("particle", "particles/custom/items/creed_of_omniscience/ward/ward_exp_collection.vpcf", context)
end

function item_creed_of_omniscience_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local playerID = caster:GetPlayerOwnerID()
    local wards = PlayerResource:GetCreedOfOmniscienceTotems(playerID)
    if(#wards >= self:GetSpecialValueFor("totem_limit")) then
        wards[1]:Kill(nil,nil)
    end
    local ward = CreateUnitByName(
        "npc_creed_of_omniscience_ward", 
        self:GetCursorPosition(), 
        false, 
        caster, 
        caster, 
        caster:GetTeamNumber()
    )
    ward:AddNewModifier(caster, self, "modifier_item_creed_of_omniscience_custom_totem", {duration = -1})
    ward:SetIsBuilding(true)
    ward:SetMaterialGroup("1")
    ward:SetForwardVector(Vector(0, -1, 0))
    PlayerResource:AddCreedOfOmniscienceTotem(playerID, ward)
    EmitSoundOn("Item.CreedOfOmniscience.Cast", ward)
end

modifier_item_creed_of_omniscience_custom = class({
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
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusInt
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_creed_of_omniscience_custom:OnCreated()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_creed_of_omniscience_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusInt = self.ability:GetSpecialValueFor("bonus_intellect")
    self.bonusHealth = self.ability:GetSpecialValueFor("bonus_health")
end

function modifier_item_creed_of_omniscience_custom:GetModifierBonusHealth()
	return self.bonusHealth
end

modifier_item_creed_of_omniscience_custom_totem = class({
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
            MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
            MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
            MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
            MODIFIER_EVENT_ROSHDEF_ON_EXP_RECEIVED,
            MODIFIER_PROPERTY_TOOLTIP
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    CheckState = function()
        return {
            [MODIFIER_STATE_INVULNERABLE] = true,
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
            [MODIFIER_STATE_STUNNED] = true,
        }
    end,
    GetAbsoluteNoDamageMagical = function()
        return 1
    end,
    GetAbsoluteNoDamagePhysical = function()
        return 1
    end,
    GetAbsoluteNoDamagePure = function()
        return 1
    end
})

function modifier_item_creed_of_omniscience_custom_totem:OnCreated()
    if(not IsServer()) then
        return
    end
    self.parent = self:GetParent()
    self.parentPlayerID = self.parent:GetPlayerOwnerID()
    self.ability = self:GetAbility()
    self.bonusExperienceCollectionPct = self.ability:GetSpecialValueFor("experience_collection_pct") / 100
    self.bonusExperienceCollectionRadius = self.ability:GetSpecialValueFor("experience_collection_radius")
    self.bonusExperienceCollectionRadiusSqr = self.bonusExperienceCollectionRadius ^ 2
    self.bonusExperienceCollectionLimit = self.ability:GetSpecialValueFor("experience_collection_limit")
    self.bonusHeroCollectionStoredExpRadiusSqr = self.ability:GetSpecialValueFor("hero_collection_stored_exp_radius") ^ 2
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
    self.projectileInfo = {
		EffectName = "particles/custom/items/creed_of_omniscience/ward/ward_projectile.vpcf",
		Ability = self.ability,
		iMoveSpeed = 600,
		Source = nil,
		Target = self.parent,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
	}
    self:SetExp(0, true)
    self:StartIntervalThink(0.25)
    self:SetHasCustomTransmitterData(true)
    local particle = ParticleManager:CreateParticle(
        "particles/custom/items/creed_of_omniscience/ward/ward.vpcf", 
        PATTACH_ABSORIGIN, 
        self.parent
    )
    ParticleManager:SetParticleControl(particle, 9, Vector(self.bonusExperienceCollectionRadius, 0, 0))
    self:AddParticle(particle, false, false, 1, false, false)
end

function modifier_item_creed_of_omniscience_custom_totem:SetExp(value, ignoreSend)
    self._currentExp = self._currentExp or 0
    value = math.max(value, 0)
    value = math.min(value, self.bonusExperienceCollectionLimit)
    self._currentExp = value
    if(ignoreSend == true) then
        return
    end
    self:SendBuffRefreshToClients()
end

function modifier_item_creed_of_omniscience_custom_totem:AddExp(value, ignoreSend)
    self:SetExp(self:GetExp() + value, ignoreSend)
end

function modifier_item_creed_of_omniscience_custom_totem:GetExp()
    return self._currentExp or 0
end

function modifier_item_creed_of_omniscience_custom_totem:OnExpReceived(kv)
    if(not IsServer()) then
        return
    end
    if(CalculateDistanceSqr(kv.source, self.parent) > self.bonusExperienceCollectionRadiusSqr) then
        return
    end
    if(UnitFilter(kv.source, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    local expToStore = kv.experience * self.bonusExperienceCollectionPct
    self:AddExp(expToStore)
    self.projectileInfo.Source = kv.source
	ProjectileManager:CreateTrackingProjectile(self.projectileInfo)
end

function modifier_item_creed_of_omniscience_custom_totem:OnIntervalThink()
    local playerHero = PlayerResource:GetSelectedHeroEntity(self.parentPlayerID)
    if(not playerHero) then
        return
    end
    if(CalculateDistanceSqr(playerHero, self.parent) > self.bonusHeroCollectionStoredExpRadiusSqr) then
        return
    end
    if(self:GetExp() < 1) then
        return
    end
    playerHero:AddExperience(self:GetExp(), DOTA_ModifyXP_Unspecified, false, true)
    self:SetExp(0)
    local particle = ParticleManager:CreateParticle(
        "particles/custom/items/creed_of_omniscience/ward/ward_exp_collection.vpcf", 
        PATTACH_ABSORIGIN, 
        playerHero
    )
    ParticleManager:SetParticleControlEnt(particle, 0, playerHero, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    ParticleManager:ReleaseParticleIndex(particle, 2)
    EmitSoundOn("Item.CreedOfOmniscience.Proc", self.parent)
end

function modifier_item_creed_of_omniscience_custom_totem:OnTooltip()
    return self:GetExp()
end

function modifier_item_creed_of_omniscience_custom_totem:AddCustomTransmitterData()
    return
    {
        _currentExp = self._currentExp
    }
end

function modifier_item_creed_of_omniscience_custom_totem:HandleCustomTransmitterData(data)
    self._currentExp = data._currentExp
end

LinkLuaModifier("modifier_item_creed_of_omniscience_custom", "items/neutral_items/creed_of_omniscience", LUA_MODIFIER_MOTION_NONE, modifier_item_creed_of_omniscience_custom)
LinkLuaModifier("modifier_item_creed_of_omniscience_custom_totem", "items/neutral_items/creed_of_omniscience", LUA_MODIFIER_MOTION_NONE, modifier_item_creed_of_omniscience_custom_totem)