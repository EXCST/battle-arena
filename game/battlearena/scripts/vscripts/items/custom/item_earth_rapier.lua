require('items/generic_datadriven_item')

require('items/custom/item_base_rapier')

item_earth_rapier = class(item_base_rapier)


function item_earth_rapier:GetIntrinsicModifierName()
	return "modifier_item_earth_rapier"
end

function item_earth_rapier:ApplyItemContainerEffects(itemContainer)
	itemContainer:SetRenderColor(139, 69, 13)
end

function item_earth_rapier:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("damage_radius")
end

modifier_item_earth_rapier = class(modifier_item_base_rapier)

function modifier_item_earth_rapier:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end
	
function modifier_item_earth_rapier:GetEffectName()
	return "particles/custom/items/earth_rapier/effect_caster.vpcf"
end

function modifier_item_earth_rapier:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_earth_rapier:OnOwnerHaveMoreThanOneRapierType(owner, item)
	GameRules:SendCustomMessage("#Game_notification_earth_rapier_request_message1",0,0)		
	self:DropRapier(owner, item)
end

function modifier_item_earth_rapier:OnOwnerHaveInsufficientStats(owner, item, insufficientStats)
	GameRules:SendCustomMessage("#Game_notification_earth_rapier_request_message",0,0)	
	GameRules:SendCustomMessage("<font color='#FFD700'>MISSING ATTRIBUTES: </font><font color='#8B4513'>".. insufficientStats .."</font>",0,0)
	self:DropRapier(owner, item)
end


function modifier_item_earth_rapier:OnRapierAddedToInventory()
	local parent = self:GetParent()
	self.earthRapierPassiveModifier = parent:AddNewModifier(
		parent, 
		self:GetAbility(), 
		"modifier_item_earth_rapier_passive_handler", 
		{
			duration = -1
		}
	)
end

function modifier_item_earth_rapier:OnRapierRemoved()
	if(self.earthRapierPassiveModifier and self.earthRapierPassiveModifier:IsNull() == false) then
		self.earthRapierPassiveModifier:Destroy()
	end
end

modifier_item_earth_rapier_passive_handler = class({
    IsHidden = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    IsDebuff = function()
        return false
    end,
    RemoveOnDeath = function()
        return false
    end,
    GetAttributes = function()
        return MODIFIER_ATTRIBUTE_PERMANENT
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_MODEL_SCALE,
			MODIFIER_EVENT_ON_TAKEDAMAGE
        }
    end,
	GetModifierModelScale = function(self)
		return self.modelIncreasePct
	end,
	CheckState = function()
		return {
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true
		}
	end
})

function modifier_item_earth_rapier_passive_handler:OnCreated()
	self.parent = self:GetParent()
	self.item = self:GetAbility()
	self.damageRadius = self.item:GetSpecialValueFor("damage_radius")
	self.strPctToTickDamage = self.item:GetSpecialValueFor("str_pct_to_tick_damage") / 100
	self.tick = self.item:GetSpecialValueFor("tick")
	self.modelIncreasePct = self.item:GetSpecialValueFor("model_increase_pct") / 100
	self.spellLifestealCreepPct = self.item:GetSpecialValueFor("spell_lifesteal_creep_pct")
	self.spellLifestealBossPct = self.item:GetSpecialValueFor("spell_lifesteal_boss_pct")
	if(not IsServer()) then
		return
	end
	if(self.parent:IsIllusion() == true) then
		return
	end
	self.parentTeam = self.parent:GetTeamNumber()
	self.targetTeam = self.item:GetAbilityTargetTeam()
	self.targetType = self.item:GetAbilityTargetType()
	self.targetFlags = self.item:GetAbilityTargetFlags()
	self.damageTable = {
		victim = nil,
		attacker = self.parent,
		damage = 0,
		damage_type = self.item:GetAbilityDamageType(),
		ability = self.item
	}
	self:StartIntervalThink(self.tick)
end

function modifier_item_earth_rapier_passive_handler:OnIntervalThink()
	if(self.parent:IsAlive() == false) then
		return
	end
	local enemies = FindUnitsInRadius(
        self.parentTeam, 
        self.parent:GetAbsOrigin(), 
        nil, 
        self.damageRadius, 
        self.targetTeam, 
        self.targetType, 
        self.targetFlags, 
        FIND_ANY_ORDER, 
        false
    )
	local damage = self.parent:GetStrength() * self.strPctToTickDamage
	for _, enemy in pairs(enemies) do
		self.damageTable.damage = damage
		self.damageTable.victim = enemy
		ApplyDamage(self.damageTable)
	end
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_epicenter.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(particle, 1, Vector(self.damageRadius, self.damageRadius, self.damageRadius))
	ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_item_earth_rapier_passive_handler:GetModifierSpellLifestealPercantage(keys)
	if(keys.unit:IsBoss() == true) then
		return self.spellLifestealBossPct
	else
		return self.spellLifestealCreepPct
	end
end

item_earth_rapier_1 = class(item_earth_rapier)
item_earth_rapier_2 = class(item_earth_rapier)
item_earth_rapier_3 = class(item_earth_rapier)
item_earth_rapier_4 = class(item_earth_rapier)

LinkLuaModifier("modifier_item_earth_rapier", "items/custom/item_earth_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_earth_rapier)
LinkLuaModifier("modifier_item_earth_rapier_passive_handler", "items/custom/item_earth_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_earth_rapier_passive_handler)
