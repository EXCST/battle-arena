item_philosophers_stone_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_philosophers_stone_custom"
    end
})

modifier_item_philosophers_stone_custom = class({
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
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS
        }
    end,
    GetModifierPreAttack_BonusDamage = function(self)
        return self.bonusAttackDamage
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_philosophers_stone_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self.parentPlayerID = self.parent:GetPlayerOwnerID()
    self:OnRefresh()
end

function modifier_item_philosophers_stone_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusGoldPerSec = self.ability:GetSpecialValueFor("bonus_gpm") / 60
    self.bonusAttackDamage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonusMana = self.ability:GetSpecialValueFor("bonus_mana")
    if(not IsServer()) then
        return
    end
    self:StartIntervalThink(1)
end

function modifier_item_philosophers_stone_custom:OnIntervalThink()
    self.parent:ModifyGoldFiltered(self.bonusGoldPerSec, true, DOTA_ModifyGold_GameTick)
end

function modifier_item_philosophers_stone_custom:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return self.bonusMana
	end
	return 0
end

function modifier_item_philosophers_stone_custom:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return 0
	end
    return self.bonusMana
end

LinkLuaModifier("modifier_item_philosophers_stone_custom", "items/neutral_items/philosophers_stone", LUA_MODIFIER_MOTION_NONE, modifier_item_philosophers_stone_custom)
