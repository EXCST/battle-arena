item_cursed_gaze_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_cursed_gaze_custom"
    end
})

function item_cursed_gaze_custom:Precache(context)
    PrecacheResource("particle", "particles/custom/items/cursed_gaze/debuff.vpcf", context)
end

function item_cursed_gaze_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local effectDuration = self:GetSpecialValueFor("duration")
    target:AddNewModifier(caster, self, "modifier_item_cursed_gaze_custom_debuff_target", {duration = effectDuration})
    caster:AddNewModifier(caster, self, "modifier_item_cursed_gaze_custom_debuff", {duration = effectDuration})
    EmitSoundOn("Item.CursedGaze.Activate", target)
end

modifier_item_cursed_gaze_custom = class({
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
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_STATS_STRENGTH_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_STATS_AGILITY_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_STATS_INTELLECT_BONUS_PERCENTAGE
        }
    end,
    GetModifierMoveSpeedBonus_Percentage = function(self)
        return self.bonusMovespeedPct
    end,
    GetModifierBonusStats_Strength_Percentage = function(self)
        return self.bonusStrPct
    end,
    GetModifierBonusStats_Agility_Percentage = function(self)
        return self.bonusAgiPct
    end,
    GetModifierBonusStats_Intellect_Percentage = function(self)
        return self.bonusIntPct
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_cursed_gaze_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self:StartIntervalThink(0.2)
end

function modifier_item_cursed_gaze_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusMovespeedPct = self.ability:GetSpecialValueFor("bonus_move_speed_pct")
    self.bonusPrimaryPct = self.ability:GetSpecialValueFor("bonus_primary_attribute_pct")
end

function modifier_item_cursed_gaze_custom:OnIntervalThink()
    if(not self.parent.GetPrimaryAttribute) then
        return
    end
    local primary = self.parent:GetPrimaryAttribute()
    self.bonusStrPct = 0
    self.bonusAgiPct = 0
    self.bonusIntPct = 0
    if(primary == DOTA_ATTRIBUTE_STRENGTH) then
        self.bonusStrPct = self.bonusPrimaryPct
        self.bonusAgiPct = 0
        self.bonusIntPct = 0
    end
    if(primary == DOTA_ATTRIBUTE_AGILITY) then
        self.bonusStrPct = 0
        self.bonusAgiPct = self.bonusPrimaryPct
        self.bonusIntPct = 0
    end
    if(primary == DOTA_ATTRIBUTE_INTELLECT) then
        self.bonusStrPct = 0
        self.bonusAgiPct = 0
        self.bonusIntPct = self.bonusPrimaryPct
    end
    self.parent:CalculateStatBonus(true)
end

modifier_item_cursed_gaze_custom_debuff_target = class({
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
    IsIgnoreStatusResistance = function()
        return true
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_PREATTACK_TARGET_CRITICALSTRIKE,
            MODIFIER_EVENT_ON_TAKEDAMAGE,
            MODIFIER_PROPERTY_ROSHDEF_SPELL_CRITICAL_STRIKE_COLOR,
            MODIFIER_PROPERTY_ROSHDEF_CRITICAL_STRIKE_COLOR,
            MODIFIER_PROPERTY_ROSHDEF_PRESPELL_TARGET_CRITICALSTRIKE
        }
    end,
    GetEffectName = function()
        return "particles/custom/items/cursed_gaze/debuff.vpcf"
    end,
    GetEffectAttachType = function()
        return PATTACH_OVERHEAD_FOLLOW
    end,
    GetModifierCriticalStrikeColor = function(self)
        return Vector(110, 22, 177)
    end,
    GetModifierSpellCriticalStrikeColor = function(self)
        return self:GetModifierCriticalStrikeColor()
    end
})

function modifier_item_cursed_gaze_custom_debuff_target:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    self.currentCritDamageBonus = 0
end

function modifier_item_cursed_gaze_custom_debuff_target:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.critDamagePerAttack = self.ability:GetSpecialValueFor("crit_dmg_increase_per_attack")
    self.critDamagePerSkill = self.ability:GetSpecialValueFor("crit_dmg_increase_per_skill")
    self.baseCritDamage = self.ability:GetSpecialValueFor("base_crit_dmg")
end

function modifier_item_cursed_gaze_custom_debuff_target:OnTakeDamage(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    if(kv.inflictor) then
        self.currentCritDamageBonus = self.currentCritDamageBonus + self.critDamagePerSkill
    else
        self.currentCritDamageBonus = self.currentCritDamageBonus + self.critDamagePerAttack
    end
end

function modifier_item_cursed_gaze_custom_debuff_target:GetModifierPreAttack_Target_CriticalStrike()
    return self.baseCritDamage + self.currentCritDamageBonus
end

function modifier_item_cursed_gaze_custom_debuff_target:GetCritDamage()
	return (self.baseCritDamage + self.currentCritDamageBonus) / 100
end

function modifier_item_cursed_gaze_custom_debuff_target:GetModifierPreSpell_Target_CriticalStrike()
    return self:GetModifierPreAttack_Target_CriticalStrike()
end

function modifier_item_cursed_gaze_custom_debuff_target:GetSpellCritDamage()
	return self:GetCritDamage()
end


modifier_item_cursed_gaze_custom_debuff = class({
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
    CheckState = function()
        return {
            [MODIFIER_STATE_DISARMED] = true,
            [MODIFIER_STATE_SILENCED] = true
        }
    end
})

LinkLuaModifier("modifier_item_cursed_gaze_custom", "items/neutral_items/cursed_gaze", LUA_MODIFIER_MOTION_NONE, modifier_item_cursed_gaze_custom)
LinkLuaModifier("modifier_item_cursed_gaze_custom_debuff_target", "items/neutral_items/cursed_gaze", LUA_MODIFIER_MOTION_NONE, modifier_item_cursed_gaze_custom_debuff_target)
LinkLuaModifier("modifier_item_cursed_gaze_custom_debuff", "items/neutral_items/cursed_gaze", LUA_MODIFIER_MOTION_NONE, modifier_item_cursed_gaze_custom_debuff)