item_chipped_vest_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_chipped_vest_custom"
    end
})

modifier_item_chipped_vest_custom = class({
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
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
        }
    end,
    GetModifierConstantHealthRegen = function(self)
        return self.bonusHealthRegeneration
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_chipped_vest_custom:OnCreated()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
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
		damage = 0,
		damage_type = nil,
		ability = self.ability,
		damage_flags = DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
	}
end

function modifier_item_chipped_vest_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealthRegeneration = self.ability:GetSpecialValueFor("hp_regen")
    self.damageReturnBoss = self.ability:GetSpecialValueFor("damage_return_boss")
    self.damageReturnCreep = self.ability:GetSpecialValueFor("damage_return_creep")
end

function modifier_item_chipped_vest_custom:OnAttackLanded(kv)
    if(kv.target ~= self.parent) then
        return
    end
    if(UnitFilter(kv.attacker, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    self.damageTable.victim = kv.attacker
    if(kv.attacker:IsBoss() == true) then
        self.damageTable.damage = self.damageReturnBoss
    else
        self.damageTable.damage = self.damageReturnCreep
    end
    self.damageTable.damage_type = kv.damage_type
    ApplyDamage(self.damageTable)
end

LinkLuaModifier("modifier_item_chipped_vest_custom", "items/neutral_items/chipped_vest", LUA_MODIFIER_MOTION_NONE, modifier_item_chipped_vest_custom)