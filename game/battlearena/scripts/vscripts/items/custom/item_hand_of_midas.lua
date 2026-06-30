require('items/generic_datadriven_item')


item_hand_of_midas_custom = {}

function item_hand_of_midas_custom:GetIntrinsicModifierName()
	return "modifier_item_hand_of_midas_custom"
end

function item_hand_of_midas_custom:GetAbilityTargetFlags()
	return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function item_hand_of_midas_custom:GetAbilityTargetTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function item_hand_of_midas_custom:GetAbilityTargetType()
	return DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_BASIC
end

function item_hand_of_midas_custom:CheckTarget( target )
	if IsClient() then
		return true
	end

	return (
		target:GetLevel() <= self:GetSpecialValueFor( "creep_level" ) and
		not target:IsLegendaryCreep() and
		not target:IsBoss() and
		not target:IsBuilding() and
		not target:IsHero() and
		target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber()
	)
end

function item_hand_of_midas_custom:CastFilterResultTarget( target )
	return self:CheckTarget( target ) and UF_SUCCESS or UF_FAIL_CUSTOM
end

function item_hand_of_midas_custom:GetAOERadius()
	return self:GetSpecialValueFor( "radius" )
end

function item_hand_of_midas_custom:OnSpellStart()
	if IsClient() then
		return
	end

	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target then
		return
	end

	local units = FindUnitsInRadius(
		caster:GetTeamNumber(),
		target:GetAbsOrigin(),
		nil,
		self:GetSpecialValueFor( "radius" ),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)

	for _, unit in pairs( units ) do
		if self:CheckTarget( unit ) then
			local baseBounty = unit:GetGoldBounty()
			local midasBounty = baseBounty * self:GetSpecialValueFor( "bonus_gold_pct" ) / 100

			unit:SetMinimumGoldBounty( midasBounty )
			unit:SetMaximumGoldBounty( midasBounty )
			unit:Kill( self, caster )
			
			local effect = "particles/items2_fx/hand_of_midas.vpcf"
			local particle_fx = ParticleManager:CreateParticle(effect, PATTACH_ABSORIGIN_FOLLOW, unit)
			ParticleManager:SetParticleControlEnt(particle_fx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(particle_fx)
			unit:EmitSound("DOTA_Item.Hand_Of_Midas")			
		end
	end
end

modifier_item_hand_of_midas_custom = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}end,
})

function modifier_item_hand_of_midas_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
end

function modifier_item_hand_of_midas_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
   self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
end

function modifier_item_hand_of_midas_custom:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_hand_of_midas_custom:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_hand_of_midas_custom:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

item_hand_of_midas_6 = item_hand_of_midas_custom
item_hand_of_midas_5 = item_hand_of_midas_custom
item_hand_of_midas_4 = item_hand_of_midas_custom
item_hand_of_midas_3 = item_hand_of_midas_custom
item_hand_of_midas_2 = item_hand_of_midas_custom
item_hand_of_midas_1 = item_hand_of_midas_custom


LinkLuaModifier("modifier_item_hand_of_midas_custom", "items/custom/item_hand_of_midas", LUA_MODIFIER_MOTION_NONE, modifier_item_hand_of_midas_custom)

