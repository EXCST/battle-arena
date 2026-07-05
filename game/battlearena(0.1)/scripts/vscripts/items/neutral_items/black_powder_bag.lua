item_black_powder_bag_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_black_powder_bag_custom"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("radius")
    end
})

function item_black_powder_bag_custom:Precache(context)
    PrecacheResource("particle", "particles/items3_fx/black_powder_bag.vpcf", context)
end

modifier_item_black_powder_bag_custom = class({
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
            MODIFIER_EVENT_ON_ATTACK_LANDED,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
        }
    end,
    GetModifierConstantHealthRegen = function(self)
        return self.bonusHealthRegeneration
    end,
    GetModifierConstantManaRegen = function(self)
        return self.bonusManaRegen
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_black_powder_bag_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
end

function modifier_item_black_powder_bag_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealthRegeneration = self.ability:GetSpecialValueFor("bonus_hp_regen")
    self.bonusManaRegen = self.ability:GetSpecialValueFor("bonus_mp_regen")
    self.radiusSqr = self.ability:GetCastRange() ^ 2
    self.duration = self.ability:GetSpecialValueFor("blind_duration")
    self.knockbackHeight = self.ability:GetSpecialValueFor("knockback_height")
    self.knockbackDuration = self.ability:GetSpecialValueFor("knockback_duration")
    self.primaryAttributeToDamagePct = self.ability:GetSpecialValueFor("primary_attribute_to_damage_pct") / 100
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
end

function modifier_item_black_powder_bag_custom:OnAttackLanded(kv)
    if(kv.target ~= self.parent) then
        return
    end
    if(UnitFilter(kv.attacker, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    if(CalculateDistanceSqr(self.parent, kv.attacker) > self.radiusSqr) then
        return
    end
    if(self.ability:IsCooldownReady() == false) then
        return
    end
    local position = self.parent:GetAbsOrigin()
    local radius = self.ability:GetCastRange()
    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(),
        position,
		nil,
		radius,
		self.targetTeam,
		self.targetType,
		self.targetFlags,
		FIND_ANY_ORDER,
		false
    )
    if(self.parent.GetPrimaryStatValue) then
        self.damageTable.damage = self.parent:GetPrimaryStatValue() * self.primaryAttributeToDamagePct
    else
        self.damageTable.damage = 0
    end
    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(self.parent, self.ability, "modifier_item_black_powder_bag_custom_debuff", {duration = self.duration})
        local direction = (enemy:GetAbsOrigin() - position):Normalized()
		enemy:ApplyKnockback(self.parent, self.ability, direction, radius, self.knockbackDuration, self.knockbackHeight, false)
        self.damageTable.victim = enemy
        ApplyDamage(self.damageTable)
    end
    local particle = ParticleManager:CreateParticle(
        "particles/items3_fx/black_powder_bag.vpcf", 
        PATTACH_ABSORIGIN, 
        self.parent
    )
    ParticleManager:ReleaseParticleIndex(particle, 2)
    EmitSoundOn("Item.BlastRig.Cast", self.parent)
    self.ability:UseResources(true, false, true, true)
end

modifier_item_black_powder_bag_custom_debuff = class({
    IsHidden = function() 
        return false 
    end,
    IsDebuff = function()
        return true
    end,
    IsPurgable = function()
        return true
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_ROSHDEF_MISS_PERCENTAGE,
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_TOOLTIP
        }
    end,
    GetModifierMiss_Percentage = function(self)
        return self.bonusBlindChance
    end,
    OnTooltip = function(self)
        return self:GetModifierMiss_Percentage()
    end,
    GetModifierMoveSpeedBonus_Percentage = function(self)
        return self.bonusMovementSpeed
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_black_powder_bag_custom_debuff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    end
end

function modifier_item_black_powder_bag_custom_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusBlindChance = self.ability:GetSpecialValueFor("blind_pct")
    self.bonusMovementSpeed = self.ability:GetSpecialValueFor("movement_slow_pct") * -1
end

LinkLuaModifier("modifier_item_black_powder_bag_custom", "items/neutral_items/black_powder_bag", LUA_MODIFIER_MOTION_NONE, modifier_item_black_powder_bag_custom)
LinkLuaModifier("modifier_item_black_powder_bag_custom_debuff", "items/neutral_items/black_powder_bag", LUA_MODIFIER_MOTION_NONE, modifier_item_black_powder_bag_custom_debuff)