item_ogre_seal_totem_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_ogre_seal_totem_custom"
    end
})

function item_ogre_seal_totem_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_item_ogre_seal_totem_custom_motion", {duration = -1})
    EmitSoundOn("IceCreep4.Flop.Cast", caster)
end

function item_ogre_seal_totem_custom:GetCastRange()
    if(IsClient()) then
        return self:GetSpecialValueFor("distance_per_jump")
    end
end

modifier_item_ogre_seal_totem_custom = class({
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
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
            MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK
        }
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end,
    GetModifierPhysical_ConstantBlock = function(self)
        return self.bonusDamageBlock
    end,
    GetOverrideAnimation = function()
        return ACT_DOTA_FLAIL
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_ogre_seal_totem_custom:OnCreated(kv)
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_ogre_seal_totem_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusDamageBlock = self.ability:GetSpecialValueFor("bonus_damage_block")
    self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
end

modifier_item_ogre_seal_totem_custom_motion = class({
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
            MODIFIER_PROPERTY_OVERRIDE_ANIMATION
        }
    end,
    CheckState = function()
        return {
            [MODIFIER_STATE_STUNNED] = true,
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
        }
    end,
    GetOverrideAnimation = function()
        return ACT_DOTA_FLAIL
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_ogre_seal_totem_custom_motion:OnCreated(kv)
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
    self.speed = self.ability:GetSpecialValueFor("jump_speed")
    self.parentPosition = self.parent:GetAbsOrigin()
    self.targetPosition = self.ability:GetCursorPosition()
    self.distance = self.ability:GetSpecialValueFor("distance_per_jump")
    self.currentJumps = 1
    self.maxHeight = self.ability:GetSpecialValueFor("max_jump_height")
    self.distanceTraveled = 0
    self.maxJumps = self.ability:GetSpecialValueFor("max_jumps")
    self.direction = CalculateDirection(self.targetPosition, self.parentPosition)
    if(self.direction:Length2D() == 0) then
        self.direction = self.parent:GetForwardVector()
    end
    self.parent:SetForwardVector(self.direction)
    local nFXIndex = ParticleManager:CreateParticle(
        "particles/custom/units/ice_location/ice_creep_4/flop/ogre_seal_warcry.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW,
        self.parent
    )
    ParticleManager:SetParticleControlEnt( nFXIndex, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    self:AddParticle(nFXIndex, false, false, -1, false, false)
    self:StartIntervalThink(self.ability:GetSpecialValueFor("delay"))
end

function modifier_item_ogre_seal_totem_custom_motion:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.stunDuration = self.ability:GetSpecialValueFor("stun_duration")
    self.radius = self.ability:GetSpecialValueFor("radius")
    if(not IsServer()) then
        return
    end
    self.damageTable = self.damageTable or {
        victim = nil,
        attacker = self.parent,
        ability = self.ability,
        damage = 0,
        damage_type = self.ability:GetAbilityDamageType()
    }
    self.damageTable.damage = self.ability:GetSpecialValueFor("damage")
end

function modifier_item_ogre_seal_totem_custom_motion:OnIntervalThink()
    if(self:ApplyMotionController() == false) then 
        self:Destroy()
        return
    end
    self:StartIntervalThink(-1)
end

function modifier_item_ogre_seal_totem_custom_motion:OnControlledMotion(parent, dt)
    if (self.distanceTraveled < (self.distance - self.speed * dt)) then
        local parentPos = self.parent:GetAbsOrigin()
        local newPos = GetGroundPosition(parentPos, self.parent) + self.direction * self.speed * dt
        local height = GetGroundHeight(parentPos, self.parent)
        newPos.z = height + self.maxHeight * math.sin((self.distanceTraveled/self.distance) * math.pi)
        self.parent:SetAbsOrigin(newPos)
        self.distanceTraveled = self.distanceTraveled + self.speed * dt
    else
        self:TryToDamage()
        if(self.currentJumps >= self.maxJumps) then
            self:Destroy()
        else
            self.currentJumps = self.currentJumps + 1
            self.distanceTraveled = 0
        end
    end
end

function modifier_item_ogre_seal_totem_custom_motion:OnControlledMotionInterrupted()
    if(not IsServer()) then
        return
    end
    self:Destroy()
end

function modifier_item_ogre_seal_totem_custom_motion:OnDestroy()
    if(not IsServer()) then
        return
    end
    self:RemoveMotionController() 
end

function modifier_item_ogre_seal_totem_custom_motion:TryToDamage()
    local position = self.parent:GetAbsOrigin()
    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(), 
        position, 
        nil, 
        self.radius, 
        self.targetTeam, 
        self.targetType, 
        self.targetFlags, 
        FIND_ANY_ORDER, 
        false
    )
    for _, enemy in pairs(enemies) do
        self.damageTable.victim = enemy
        ApplyDamage(self.damageTable)
        enemy:AddNewModifier(self.parent, self.ability, "modifier_stunned", {duration = self.stunDuration})
    end
    EmitSoundOnLocationWithCaster(position, "Generic.GroundSmash", self.parent)
    local nFXIndex = ParticleManager:CreateParticle("particles/custom/test_particle/ogre_melee_smash.vpcf", PATTACH_ABSORIGIN, self.parent)
    ParticleManager:SetParticleControl(nFXIndex, 1, Vector(self.radius, self.radius, self.radius))
    ParticleManager:ReleaseParticleIndex(nFXIndex, 2)
    GridNav:DestroyTreesAroundPoint(position, self.radius, false, self.parent)
end

LinkLuaModifier("modifier_item_ogre_seal_totem_custom", "items/neutral_items/ogre_seal_totem", LUA_MODIFIER_MOTION_NONE, modifier_item_ogre_seal_totem_custom)
LinkLuaModifier("modifier_item_ogre_seal_totem_custom_motion", "items/neutral_items/ogre_seal_totem", LUA_MODIFIER_MOTION_NONE, modifier_item_ogre_seal_totem_custom_motion)