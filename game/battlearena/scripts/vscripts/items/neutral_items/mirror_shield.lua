item_mirror_shield_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_mirror_shield_custom"
    end
})

modifier_item_mirror_shield_custom = class({
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
            MODIFIER_PROPERTY_REFLECT_SPELL,
            MODIFIER_PROPERTY_ABSORB_SPELL,
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
        }
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.bonusAllStats
    end,
    GetModifierBonusStats_Agility = function(self)
        return self.bonusAllStats
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusAllStats
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_mirror_shield_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_mirror_shield_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAllStats = self.ability:GetSpecialValueFor("all_stats")
    self.reflectChanceCreep = self.ability:GetSpecialValueFor("reflect_chance_creep")
    self.reflectChanceBoss = self.ability:GetSpecialValueFor("reflect_chance_boss")
end

function modifier_item_mirror_shield_custom:OnDestroy()
    if(not IsServer()) then
        return
    end
    self:RemoveReflectedAbility()
end

function modifier_item_mirror_shield_custom:RemoveReflectedAbility()
    if(self.reflectedSpell ~= nil) then
        self.parent:RemoveAbilityByHandle(self.reflectedSpell)
    end
    self.reflectedSpell = nil
end

function modifier_item_mirror_shield_custom:SetReflectedAbility(ability)
    self:RemoveReflectedAbility()
    self.reflectedSpell = ability
end

function modifier_item_mirror_shield_custom:IsCanBeReflected()
    if(self.ability:IsCooldownReady() == true and self.ability:IsFullyCastable() == true) then
        return true
    end
    return false
end

function modifier_item_mirror_shield_custom:GetAbsorbSpell(kv)
    if(self:GetStackCount() == 1) then
        self.ability:UseResources(true, false, true, true)
        self:SetStackCount(0)
        return 1
    end
end

function modifier_item_mirror_shield_custom:GetReflectSpell(kv)
    if(self:IsCanBeReflected() == false) then
        return 0
    end
    local source = kv.ability:GetCaster()
    local chance = self.reflectChanceCreep
    if(source:IsBoss() == true) then
        chance = self.reflectChanceBoss
    end
    if(RollPercentage(chance) == false) then
        return
    end
    self:PlayEffects()
    local reflectedAbility = self.parent:AddAbility(kv.ability:GetAbilityName())
    reflectedAbility:SetLevel(kv.ability:GetLevel())
    reflectedAbility:SetStolen(true)
    reflectedAbility:SetHidden(true)
    self:SetReflectedAbility(reflectedAbility)
    self.parent:SetCursorCastTarget(source)
    reflectedAbility:CastAbility()
    reflectedAbility:SetActivated(false)
    self:SetStackCount(1)
    return 1
end

function modifier_item_mirror_shield_custom:PlayEffects()
	local particle = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_antimage/antimage_spellshield_reflect.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW,
        self.parent
    )
	ParticleManager:SetParticleControlEnt(
		particle,
		0,
		self.parent,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0, 0, 0),
		true
	)
	ParticleManager:ReleaseParticleIndex(particle, 2)
	EmitSoundOn("Item.MirrorShield.Cast", self.parent)
end

LinkLuaModifier("modifier_item_mirror_shield_custom", "items/neutral_items/mirror_shield", LUA_MODIFIER_MOTION_NONE, modifier_item_mirror_shield_custom)