require('items/generic_datadriven_item')


item_ultra_boots = class({})

function item_ultra_boots:OnSpellStart()
    BeginTeleport(self:GetCaster(), self)
end

function CreateTeleportParticles(caster, target)
    local casterPosition = caster:GetAbsOrigin()
    caster.wispTeleportationStartParticle = ParticleManager:CreateParticle("particles/items2_fx/teleport_start.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(caster.wispTeleportationStartParticle, 0, casterPosition)
    ParticleManager:SetParticleControl(caster.wispTeleportationStartParticle, 2, Vector(255, 255, 255))
    ParticleManager:SetParticleControl(caster.wispTeleportationStartParticle, 3, casterPosition)
    ParticleManager:SetParticleControl(caster.wispTeleportationStartParticle, 4, casterPosition)
    ParticleManager:SetParticleControl(caster.wispTeleportationStartParticle, 5, Vector(3, 0, 0))
    ParticleManager:SetParticleControl(caster.wispTeleportationStartParticle, 6, casterPosition)
    if (not target) then
        return
    end
    caster.wispTeleportationEndParticle = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_CUSTOMORIGIN, caster)
    if (target.GetAbsOrigin) then
        local targetPosition = target:GetAbsOrigin()
        ParticleManager:SetParticleControlEnt(caster.wispTeleportationEndParticle, 0, target, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", targetPosition, true)
        ParticleManager:SetParticleControlEnt(caster.wispTeleportationEndParticle, 1, target, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", targetPosition, true)
        ParticleManager:SetParticleControlEnt(caster.wispTeleportationEndParticle, 5, target, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", targetPosition, true)
    else
        ParticleManager:SetParticleControl(caster.wispTeleportationEndParticle, 0, target)
        ParticleManager:SetParticleControl(caster.wispTeleportationEndParticle, 1, target)
        ParticleManager:SetParticleControl(caster.wispTeleportationEndParticle, 5, target)
    end
    ParticleManager:SetParticleControl(caster.wispTeleportationEndParticle, 2, Vector(255, 255, 255))
    ParticleManager:SetParticleControlEnt(caster.wispTeleportationEndParticle, 3, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", casterPosition, true)
    ParticleManager:SetParticleControl(caster.wispTeleportationEndParticle, 4, Vector(1, 0, 0))
end

function BeginTeleport(caster, ability)
    local target = ability:GetCursorTarget()
    caster.wispTeleportationTeleportPoint = caster:GetAbsOrigin()
    if (target) then
        if (caster == target) then
            SetTeleportPoint(caster, FindGoodGuysRespawnPosition())
            target = caster.wispTeleportationTeleportPoint
        else
            SetTeleportPoint(caster, target)
        end
    else
        local cursorPosition = ability:GetCursorPosition()
        local allies = FindUnitsInRadius(
            caster:GetTeamNumber(),
            cursorPosition,
            nil,
            800, -- search radius from doto
            DOTA_UNIT_TARGET_TEAM_FRIENDLY,
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER,
            false
        )
        if(#allies > 0) then
            for _, ally in pairs(allies) do
                if(ally ~= caster) then
                    target = ally
                    break
                end
            end
        end
        if(target) then
            SetTeleportPoint(caster, target)
        else
            local maxDistance = ability:GetSpecialValueFor("maximum_distance")
            target = FindTeleportPointBasedOnClosestBuilding(caster, cursorPosition, maxDistance)
            SetTeleportPoint(caster, target)
        end
    end
    if(target.GetAbsOrigin) then
        -- moving target
        CreateModifierThinker(
            target,
            ability,
            "modifier_item_ultra_boots_tp_target_sound",
            {
                duration = ability:GetChannelTime(),
                moveWithCaster = true
            },
            target:GetAbsOrigin(),
            caster:GetTeamNumber(),
            false
        ) 
    else
        -- ground target
        CreateModifierThinker(
            caster,
            ability,
            "modifier_item_ultra_boots_tp_target_sound",
            {
                duration = ability:GetChannelTime()
            },
            target,
            caster:GetTeamNumber(),
            false
        ) 
    end
    EmitSoundOn("Portal.Loop_Disappear", caster)
    CreateTeleportParticles(caster, target)
end

function SetTeleportPoint(caster, point)
    caster.wispTeleportationTeleportPoint = point
end

function FindGoodGuysRespawnPosition()
    local location = nil
    local entities = Entities:FindAllByClassname("info_player_start_goodguys")
    if (entities and entities[1]) then
        location = entities[1]:GetAbsOrigin()
    end
    return location
end

function FindTeleportPointBasedOnClosestBuilding(caster, cursorPosition, maxDistance)
    local allowedBuildingsList = {
        ["npc_dota_goodguys_tower_upgradeable"] = true,
        ["npc_alliance_forpost"] = true
    }
    local location = Vector(0, 0, 0)
    local buildings = FindUnitsInRadius(
            caster:GetTeamNumber(),
            cursorPosition,
            nil,
            FIND_UNITS_EVERYWHERE,
            DOTA_UNIT_TARGET_TEAM_FRIENDLY,
            DOTA_UNIT_TARGET_BUILDING,
            DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
            FIND_ANY_ORDER,
            false
    )
    for i = #buildings, 1, -1 do
        if(not allowedBuildingsList[buildings[i]:GetUnitName()]) then
            table.remove(buildings, i)
        end
    end
    if (#buildings > 0) then
        local buildingDistanceToCursor = 9999999
        local closestBuilding = nil
        local currentDistance = 0
        for _, building in pairs(buildings) do
            currentDistance = CalculateDistance(building, cursorPosition)
            if (currentDistance < buildingDistanceToCursor) then
                buildingDistanceToCursor = currentDistance
                closestBuilding = building
            end
        end
        if (closestBuilding) then
            location = closestBuilding:GetAbsOrigin() + (CalculateDirection(cursorPosition, closestBuilding) * math.min(buildingDistanceToCursor, maxDistance))
        end
    else
        location = FindGoodGuysRespawnPosition()
    end
    return location
end

function EndTeleport(caster, IsInterrupt)
    local point = caster.wispTeleportationTeleportPoint
    if (point) then
        if (point.GetAbsOrigin) then
            StopSoundOn("Portal.Loop_Disappear", point)
            point = point:GetAbsOrigin()
        end
        if(IsInterrupt == false) then
            FindClearSpaceForUnit(caster, point, true)
            caster:Stop()
        end
        caster.wispTeleportationTeleportPoint = nil
    end
    caster:StopSound("Portal.Loop_Disappear")
    EmitSoundOn("Portal.Hero_Disappear", caster)
    EmitSoundOn("Portal.Hero_Appear", caster)
    Timers:CreateTimer(2, function()
		-- 7.31 cause crash if something is null
        if(caster and caster:IsNull() == false) then
            caster:StopSound("Portal.Hero_Disappear")
            caster:StopSound("Portal.Hero_Appear")
        end
    end)
    DestroyTeleportEffects(caster)
end

function DestroyTeleportEffects(caster)
    if (caster.wispTeleportationStartParticle) then
        ParticleManager:DestroyParticle(caster.wispTeleportationStartParticle, false)
        caster.wispTeleportationStartParticle = nil
    end
    if (caster.wispTeleportationEndParticle) then
        ParticleManager:DestroyParticle(caster.wispTeleportationEndParticle, false)
        caster.wispTeleportationEndParticle = nil
    end
end

function SuppaTeleport(caster, ability)
    FindClearSpaceForUnit(caster, ability:GetCursorPosition(), true)
end


item_suppa = class({
    GetIntrinsicModifierName = function() return "modifier_suppa" end
})

function item_suppa:OnSpellStart()
    SuppaTeleport(self:GetCaster(), self)
end

modifier_suppa = class({
    IsHidden = function() return true end,
    IsPurgable = function() return false end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
    } end,
    GetModifierPreAttack_BonusDamage = function(self) return self.bonus_dmg end,
    GetModifierMoveSpeedBonus_Special_Boots = function(self) return self.bonus_movement_speed end,
    GetModifierBonusStats_Strength = function(self) return self.bonus_all_stats end,
    GetModifierBonusStats_Agility = function(self) return self.bonus_all_stats end,
    GetModifierBonusStats_Intellect = function(self) return self.bonus_all_stats end
})

function modifier_suppa:OnCreated()
    self.bonus_movement_speed = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
    self.bonus_dmg = self:GetAbility():GetSpecialValueFor("bonus_dmg")
    self.bonus_all_stats = self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end


modifier_item_ultra_boots_tp_target_sound = class({
    IsHidden = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_EVENT_ON_ABILITY_END_CHANNEL
        }
    end
})

function modifier_item_ultra_boots_tp_target_sound:OnCreated(kv)
    if(not IsServer()) then
        return
    end
    self.parent = self:GetParent()
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    EmitSoundOn("Portal.Loop_Disappear", self.parent)
    if(kv.moveWithCaster) then
        self:StartIntervalThink(0.05)
    end
end

function modifier_item_ultra_boots_tp_target_sound:OnIntervalThink()
    if(not IsServer()) then
        return
    end
    self.parent:SetAbsOrigin(self.caster:GetAbsOrigin())
end

function modifier_item_ultra_boots_tp_target_sound:OnAbilityEndChannel(kv)
    if(not IsServer()) then
        return
    end
    if(kv.unit ~= self.caster) then
        return
    end
    if(kv.ability ~= self.ability) then
        return
    end
    self:Destroy()
end

function modifier_item_ultra_boots_tp_target_sound:OnDestroy()
    if(not IsServer()) then
        return
    end
    self.parent:StopSound("Portal.Loop_Disappear")
    UTIL_Remove(self.parent)
end


LinkLuaModifier("modifier_item_ultra_boots_tp_target_sound", "items/custom/item_ultra_boots", LUA_MODIFIER_MOTION_NONE, modifier_item_ultra_boots_tp_target_sound)
LinkLuaModifier("modifier_suppa", "items/custom/item_ultra_boots", 0, modifier_suppa)
