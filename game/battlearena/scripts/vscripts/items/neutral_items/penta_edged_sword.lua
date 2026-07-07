item_penta_edged_sword_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_penta_edged_sword_custom"
    end
})

function item_penta_edged_sword_custom:Precache(context)
    PrecacheResource("particle", "particles/items2_fx/sange_maim.vpcf", context)
end

modifier_item_penta_edged_sword_custom = class({
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
            MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
            MODIFIER_EVENT_ON_ATTACK_LANDED
        
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_PERCENTAGE,
        }
    end,
    GetModifierPreAttack_BonusDamage = function(self)
        return self.bonusAttackDamage
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_penta_edged_sword_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
    self:StartIntervalThink(0.2)
end

function modifier_item_penta_edged_sword_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAttackRangeMelee = self.ability:GetSpecialValueFor("melee_attack_range")
    self.bonusAttackDamage = self.ability:GetSpecialValueFor("damage")
    self.bonusMaimChance = self.ability:GetSpecialValueFor("maim_chance")
    self.bonusMaimDuration = self.ability:GetSpecialValueFor("maim_duration")
    self.bonusMaimRadius = self.ability:GetSpecialValueFor("maim_radius")
end

function modifier_item_penta_edged_sword_custom:OnIntervalThink()
    local attackCapability = self.parent:GetAttackCapability()
    if(self.parent:GetAttackCapability() == DOTA_UNIT_CAP_MELEE_ATTACK) then
        self:SetStackCount(self.bonusAttackRangeMelee)
    else
        self:SetStackCount(0)
    end
end

function modifier_item_penta_edged_sword_custom:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(RollPercentage(self.bonusMaimChance) == false) then
        return
    end
    local teamNumber = self.parent:GetTeamNumber()
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, teamNumber) ~= UF_SUCCESS) then
        return
    end
    local enemies = FindUnitsInRadius(
        teamNumber,
        kv.target:GetAbsOrigin(),
        nil,
        self.bonusMaimRadius,
        self.targetTeam,
        self.targetType,
        self.targetFlags,
        FIND_ANY_ORDER,
        false
    )
    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(self.parent, self.ability, "modifier_item_penta_edged_sword_custom_debuff", {duration = self.bonusMaimDuration})
    end
    EmitSoundOn("Item.PentaEdgedSword.Proc", kv.target)
end

function modifier_item_penta_edged_sword_custom:GetModifierAttackRangeBonus()
    return self:GetStackCount()
end

modifier_item_penta_edged_sword_custom_debuff = class({
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
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_ATTACK_SPEED_PERCENTAGE,
            MODIFIER_PROPERTY_TOOLTIP
        
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_PERCENTAGE,
        }
    end,
    GetModifierMoveSpeedBonus_Percentage = function(self)
        return self.bonusMovespeedPct
    end,
    GetModifierAttackSpeed_Percentage = function(self)
        return self.bonusAttackSpeedPct
    end,
    OnTooltip = function(self)
        return self:GetModifierAttackSpeed_Percentage()
    end,
    GetTexture = function(self)
        return self.buffIcon
    end,
    GetEffectName = function()
        return "particles/items2_fx/sange_maim.vpcf"
    end
})

function modifier_item_penta_edged_sword_custom_debuff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    end
end

function modifier_item_penta_edged_sword_custom_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusMovespeedPct = self.ability:GetSpecialValueFor("maim_slow_movement") * -1
    self.bonusAttackSpeedPct = self.ability:GetSpecialValueFor("maim_slow_attack") * -1
end

LinkLuaModifier("modifier_item_penta_edged_sword_custom", "items/neutral_items/penta_edged_sword", LUA_MODIFIER_MOTION_NONE, modifier_item_penta_edged_sword_custom)
LinkLuaModifier("modifier_item_penta_edged_sword_custom_debuff", "items/neutral_items/penta_edged_sword", LUA_MODIFIER_MOTION_NONE, modifier_item_penta_edged_sword_custom_debuff)