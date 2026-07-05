item_ancient_perseverance_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_ancient_perseverance_custom"
    end
})

modifier_item_ancient_perseverance_custom = class({
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
            MODIFIER_EVENT_ON_TAKEDAMAGE,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_ancient_perseverance_custom:OnCreated()
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

function modifier_item_ancient_perseverance_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonusHealth = self.ability:GetSpecialValueFor("bonus_health")
    self.bonusMana = self.ability:GetSpecialValueFor("bonus_mana")
    self.damageToManaPct = self.ability:GetSpecialValueFor("received_dmg_to_mana_pct") / 100
end

function modifier_item_ancient_perseverance_custom:OnTakeDamage(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    if(UnitFilter(kv.attacker, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    self.parent:GiveMana(kv.damage * self.damageToManaPct)
end

function modifier_item_ancient_perseverance_custom:GetModifierBonusHealth()
	return self.bonusHealth
end

function modifier_item_ancient_perseverance_custom:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return self.bonusMana
	end
	return 0
end

function modifier_item_ancient_perseverance_custom:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return 0
	end
    return self.bonusMana
end

LinkLuaModifier("modifier_item_ancient_perseverance_custom", "items/neutral_items/ancient_perseverance", LUA_MODIFIER_MOTION_NONE, modifier_item_ancient_perseverance_custom)