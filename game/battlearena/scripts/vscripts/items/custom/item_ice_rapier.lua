require('items/generic_datadriven_item')


-----------------------------------------------------------------------------------------------------------
--	Skadi definition
-----------------------------------------------------------------------------------------------------------
require('items/custom/item_base_rapier')

item_ice_rapier = class(item_base_rapier)

-- Passive modifier
function item_ice_rapier:GetIntrinsicModifierName()
	return "modifier_item_imba_skadi"
end


-- Dynamic cast range
function item_ice_rapier:GetCastRange(vLocation, hTarget)
	local caster = self:GetCaster()
	if (caster and caster:HasModifier("modifier_item_imba_skadi")) then
		return caster:GetModifierStackCount("modifier_item_imba_skadi", caster)
	end
	return self.BaseClass.GetCastRange(vLocation, hTarget)
end

-- Root active
function item_ice_rapier:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()

		-- Parameters
		local caster_loc = caster:GetAbsOrigin()
		local radius = self:GetSpecialValueFor("base_radius")
		local duration = self:GetSpecialValueFor("base_duration")
		local damage = self:GetSpecialValueFor("base_damage")
		local radiusCap = self:GetSpecialValueFor("radius_max")
		local durationCap = self:GetSpecialValueFor("duration_max")
		-- Calculate cast parameters
		if caster:IsRealHero() then
			radius = radius + caster:GetStrength() * self:GetSpecialValueFor("radius_per_str")
			if radius > radiusCap then radius = radiusCap end
			duration = duration + caster:GetAgility() * self:GetSpecialValueFor("duration_per_agi")
			if duration > durationCap then duration = durationCap end
			damage = damage + caster:GetPrimaryStatValue() * self:GetSpecialValueFor("damage_per_int")
		end

		-- Play sound
		if USE_MEME_SOUNDS and RollPercentage(5) then
			caster:EmitSound("Imba.SkadiDeadWinter")
		else
			caster:EmitSound("Imba.SkadiCast")
		end

		-- Play particle
		local blast_pfx = ParticleManager:CreateParticle("particles/custom/item/skadi/skadi_ground.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleAlwaysSimulate(blast_pfx)
		ParticleManager:SetParticleControl(blast_pfx, 0, caster_loc)
		ParticleManager:SetParticleControl(blast_pfx, 2, Vector(radius * 1.15, 1, 1))
		ParticleManager:ReleaseParticleIndex(blast_pfx)

		-- Grant flying vision in the target area
		self:CreateVisibilityNode(caster_loc, radius, duration + self:GetSpecialValueFor("vision_extra_duration"))

		-- Find targets in range
		local nearby_enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster_loc, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

		-- Play target sound if at least one enemy was hit
		if #nearby_enemies > 0 then caster:EmitSound("Imba.SkadiHit") end

		-- Damage and freeze enemies
		for _,enemy in pairs(nearby_enemies) do

			-- Apply damage
			ApplyDamage({attacker = caster, victim = enemy, ability = self, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})

			-- Apply freeze modifier
			enemy:AddNewModifier(caster, self, "modifier_item_imba_skadi_freeze", {duration = duration})

			-- Apply ministun
			enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.01})
		end
	end
end

-----------------------------------------------------------------------------------------------------------
--	Skadi owner bonus attributes (stackable)
-----------------------------------------------------------------------------------------------------------

modifier_item_imba_skadi = class(modifier_item_base_rapier)

function modifier_item_imba_skadi:OnRapierAddedToInventory()
	local caster = self:GetCaster()
	local item = self:GetAbility()
	local vLocation = caster:GetAbsOrigin()

	-- Ability properties
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()

	-- Ability specials
	self.radius = self:GetAbility():GetSpecialValueFor("base_radius")

	if not self.parent:HasModifier("modifier_item_imba_skadi_unique") then
		self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_imba_skadi_unique", {})
	end

	-- Set stack count
	self:UpdateCastRange()

	Timers:CreateTimer(0, function()
		if(self and not self:IsNull()) then
			self:UpdateCastRange()
			return 0.5
		end
	end, self)
end

function modifier_item_imba_skadi:OnDestroy(keys)
	if(not IsServer()) then
		return
	end
	if not self.parent:HasModifier("modifier_item_imba_skadi") then
		self.parent:RemoveModifierByName("modifier_item_imba_skadi_unique")
	end	
end 


function modifier_item_imba_skadi:UpdateCastRange()
	if IsServer() then
		-- 7.31 cause crash if something is null
		if(self.parent and self.parent:IsNull() == false) then
			local iradius = self.radius
			if self.parent.GetStrength then
				iradius = self.parent:GetStrength() * self.ability:GetSpecialValueFor("radius_per_str")
			end
			if iradius > 2000 then iradius = 2000 end
			self:SetStackCount(( iradius))
		end
	end
end

-- Declare modifier events/properties
function modifier_item_imba_skadi:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_EVENT_ON_DEATH
	}
	return funcs
end
	
function modifier_item_imba_skadi:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("rapier_str") end

function modifier_item_imba_skadi:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("rapier_agi") end

function modifier_item_imba_skadi:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("rapier_int") end
	
function modifier_item_imba_skadi:GetModifierSpellAmplify_Percentage()
	local ability = self:GetAbility()
	local spellAmplificationPerInt = ability:GetSpecialValueFor("spell_amplification_per_stack") / ability:GetSpecialValueFor("int_for_spell_amplification_stack")
	return self:GetAbility():GetCaster():GetPrimaryStatValue() * spellAmplificationPerInt
end

function modifier_item_imba_skadi:GetEffectName()
	return "particles/econ/courier/courier_roshan_frost/courier_roshan_frost_ambient.vpcf"
end

function modifier_item_imba_skadi:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end

function modifier_item_imba_skadi:OnOwnerHaveMoreThanOneRapierType(owner, item)
	GameRules:SendCustomMessage("#Game_notification_ice_rapier_request_message1",0,0)
	self:DropRapier(owner, item)
end

function modifier_item_imba_skadi:OnOwnerHaveInsufficientStats(owner, item, insufficientStats)
	GameRules:SendCustomMessage("#Game_notification_ice_rapier_request_message",0,0)	
	GameRules:SendCustomMessage("<font color='#FFD700'>MISSING ATTRIBUTES: </font><font color='#00FFFF'>".. insufficientStats .."</font>",0,0)	
	self:DropRapier(owner, item)
end

-----------------------------------------------------------------------------------------------------------
--	Skadi slow applier
-----------------------------------------------------------------------------------------------------------

modifier_item_imba_skadi_unique = class({
    IsHidden = function(self)
        return true
    end,
    IsPurgable = function()
        return false
    end,
	IsDebuff = function()
		return false
	end,
	IsPermanent = function()
		return true
	end,
	IsAuraActiveOnDeath = function()
        return false
    end,
    GetAuraRadius = function(self)
        return self.radius
    end,
    GetAuraSearchFlags = function(self)
        return DOTA_UNIT_TARGET_FLAG_NONE
    end,
    GetAuraSearchTeam = function(self)
        return DOTA_UNIT_TARGET_TEAM_ENEMY
    end,
    IsAura = function()
        return true
    end,
    GetAuraSearchType = function(self)
        return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    end,
    GetModifierAura = function()
        return "modifier_item_imba_skadi_slow"
    end,
    GetAuraDuration = function()
        return 0
    end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_PROJECTILE_NAME
		}
	end
})

-- Changes the caster's attack projectile, if applicable
function modifier_item_imba_skadi_unique:OnCreated(keys)
	if IsServer() then
		self.radius = self:GetAbility():GetSpecialValueFor("slow_radius")
	end
end

function modifier_item_imba_skadi_unique:GetModifierProjectileName()
	return "particles/items2_fx/skadi_projectile.vpcf"
end

-----------------------------------------------------------------------------------------------------------
--	Skadi slow
-----------------------------------------------------------------------------------------------------------

if modifier_item_imba_skadi_slow == nil then modifier_item_imba_skadi_slow = class({}) end
function modifier_item_imba_skadi_slow:IsHidden() return false end
function modifier_item_imba_skadi_slow:IsDebuff() return true end
function modifier_item_imba_skadi_slow:IsPurgable() return true end

-- Modifier status effect
function modifier_item_imba_skadi_slow:GetStatusEffectName()
	return "particles/status_fx/status_effect_frost_lich.vpcf" end

function modifier_item_imba_skadi_slow:StatusEffectPriority()
	return 10 end

-- Ability KV storage
function modifier_item_imba_skadi_slow:OnCreated(keys)
	self.slow_as = self:GetAbility():GetSpecialValueFor("slow_as")
	self.slow_ms = self:GetAbility():GetSpecialValueFor("slow_ms")
end

-- Declare modifier events/properties
function modifier_item_imba_skadi_slow:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
	return funcs
end

function modifier_item_imba_skadi_slow:GetModifierAttackSpeedBonus_Constant()
	return self.slow_as end

function modifier_item_imba_skadi_slow:GetModifierMoveSpeedBonus_Percentage()
	return self.slow_ms end

-----------------------------------------------------------------------------------------------------------
--	Skadi freeze
-----------------------------------------------------------------------------------------------------------

if modifier_item_imba_skadi_freeze == nil then modifier_item_imba_skadi_freeze = class({}) end
function modifier_item_imba_skadi_freeze:IsHidden() return true end
function modifier_item_imba_skadi_freeze:IsDebuff() return true end
function modifier_item_imba_skadi_freeze:IsPurgable() return true end

-- Modifier particle
function modifier_item_imba_skadi_freeze:GetEffectName()
	return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf"
end

function modifier_item_imba_skadi_freeze:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

-- Modifier status effect
function modifier_item_imba_skadi_freeze:GetStatusEffectName()
	return "particles/status_fx/status_effect_frost.vpcf" end

function modifier_item_imba_skadi_freeze:StatusEffectPriority()
	return 11 end

-- Declare modifier states
function modifier_item_imba_skadi_freeze:CheckState()
	local states = {
		[MODIFIER_STATE_ROOTED] = true,
	}
	return states
end


item_ice_rapier_1 = class(item_ice_rapier)
item_ice_rapier_2 = class(item_ice_rapier)
item_ice_rapier_3 = class(item_ice_rapier)
item_ice_rapier_4 = class(item_ice_rapier)

LinkLuaModifier("modifier_item_imba_skadi_unique", "items/custom/item_ice_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_imba_skadi_unique)
LinkLuaModifier("modifier_item_imba_skadi_slow", "items/custom/item_ice_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_imba_skadi_slow)
LinkLuaModifier("modifier_item_imba_skadi_freeze", "items/custom/item_ice_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_imba_skadi_freeze)
LinkLuaModifier("modifier_item_imba_skadi", "items/custom/item_ice_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_imba_skadi)
