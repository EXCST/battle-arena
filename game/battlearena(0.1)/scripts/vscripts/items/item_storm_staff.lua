require('items/generic_datadriven_item')

item_storm_staff = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_storm_staff"
    end
})

function item_storm_staff:Precache(context)
    PrecacheResource("particle", "particles/econ/items/zeus/zeus_ti8_immortal_arms/zeus_ti8_immortal_arc_head.vpcf", context)
end

function item_storm_staff:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local casterTeam = caster:GetTeamNumber()
    local delay = self:GetSpecialValueFor("delay_between_bounce")
    local bounces = self:GetSpecialValueFor("bounces")
    local searchRadius = self:GetSpecialValueFor("search_radius")
    local arc_damage = self:GetSpecialValueFor("damage") + caster:GetPrimaryStatValue()*self:GetSpecialValueFor("damage_int_pct")/100

    local damageTable = {
        victim = nil,
        attacker = caster,
        damage = arc_damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self
    }
    local currentBounce = 0
    local damagedUnits = {}
    local targetTeam = self:GetAbilityTargetTeam()
	local targetType = self:GetAbilityTargetType()
	local targetFlags = self:GetAbilityTargetFlags()
    local oldTarget = nil
    target:EmitSound("Maelstrom.Chain_Lightning")
    Timers:CreateTimer(0, function()
        if(currentBounce < bounces) then
            if(not oldTarget) then
                oldTarget = caster
            else
                oldTarget = target
                target = self:FindRandomEnemyAroundTarget(casterTeam, target, targetTeam, targetType, targetFlags, damagedUnits, searchRadius)
                if(not target) then
                    return
                end
            end
            self:CreateArcLightning(oldTarget, target, damagedUnits, damageTable)
            currentBounce = currentBounce + 1
            return delay
        end
    end, self)
end

function item_storm_staff:FindRandomEnemyAroundTarget(casterTeam, target, targetTeam, targetType, targetFlags, damagedUnits, searchRadius)
    local enemies = FindUnitsInRadius(
        casterTeam, 
        target:GetOrigin(), 
        nil, 
        searchRadius,
        targetTeam, 
        targetType, 
        targetFlags,
        FIND_ANY_ORDER, 
        false
    )
    for _, enemy in pairs(enemies) do
        if(enemy ~= target and table.contains(damagedUnits, enemy) == false) then
            return enemy
        end
    end
    return nil
end

function item_storm_staff:CreateArcLightning(source, target, damagedUnits, damageTable)
    local fx = ParticleManager:CreateParticle("particles/econ/items/zeus/zeus_ti8_immortal_arms/zeus_ti8_immortal_arc_head.vpcf", PATTACH_ABSORIGIN_FOLLOW, source)
    ParticleManager:SetParticleControlEnt(fx, 0, source, PATTACH_POINT_FOLLOW, "attach_attack1", source:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(fx, 1.5)
    target:EmitSound("Maelstrom.Chain_Lightning.Jump")
    damageTable.victim = target
    ApplyDamage(damageTable)
    table.insert(damagedUnits, target)
end

item_storm_staff_1 = class(item_storm_staff)
item_storm_staff_2 = class(item_storm_staff)
item_storm_staff_3 = class(item_storm_staff)
item_storm_staff_4 = class(item_storm_staff)
item_storm_staff_5 = class(item_storm_staff)
item_storm_staff_6 = class(item_storm_staff)

modifier_item_storm_staff = class({
    IsHidden = function() 
        return true 
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    GetAttributes = function() 
        return MODIFIER_ATTRIBUTE_MULTIPLE 
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
        }
    end
})

function modifier_item_storm_staff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_storm_staff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_mana = self.ability:GetSpecialValueFor("bonus_mana")
    self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
end

function modifier_item_storm_staff:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return self.bonus_mana
	end
	return 0
end

function modifier_item_storm_staff:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return 0
	end
	return self.bonus_mana
end

function modifier_item_storm_staff:GetModifierConstantManaRegen()
    return self.bonus_mp_regen
end

LinkLuaModifier("modifier_item_storm_staff", "items/item_storm_staff", LUA_MODIFIER_MOTION_NONE, modifier_item_storm_staff)