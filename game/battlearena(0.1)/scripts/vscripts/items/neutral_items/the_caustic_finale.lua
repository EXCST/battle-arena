item_the_caustic_finale_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_the_caustic_finale_custom"
    end
})

modifier_item_the_caustic_finale_custom = class({
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
            MODIFIER_PROPERTY_ROSHDEF_STATS_STRENGTH_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_STATS_AGILITY_BONUS_PERCENTAGE,
            MODIFIER_EVENT_ON_ATTACK_LANDED
        }
    end,
    GetModifierBonusStats_Strength_Percentage = function(self)
        return self.bonusStrPct
    end,
    GetModifierBonusStats_Agility_Percentage = function(self)
        return self.bonusAgiPct
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_the_caustic_finale_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
    self.damageTable = {
        victim = nil,
        attacker = self.parent,
        ability = self.ability,
        damage = 0,
        damage_type = self.ability:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
    }
end

function modifier_item_the_caustic_finale_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusStrPct = self.ability:GetSpecialValueFor("bonus_strength_pct")
    self.bonusAgiPct = self.ability:GetSpecialValueFor("bonus_agility_pct")
    self.bonusEnemyMaxHpToDamage = self.ability:GetSpecialValueFor("enemy_hp_to_dmg_pct") / 100
end

function modifier_item_the_caustic_finale_custom:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return 0
    end
    self.damageTable.victim = kv.target
    self.damageTable.damage = kv.target:GetMaxHealth() * self.bonusEnemyMaxHpToDamage
    ApplyDamage(self.damageTable)
end

LinkLuaModifier("modifier_item_the_caustic_finale_custom", "items/neutral_items/the_caustic_finale", LUA_MODIFIER_MOTION_NONE, modifier_item_the_caustic_finale_custom)