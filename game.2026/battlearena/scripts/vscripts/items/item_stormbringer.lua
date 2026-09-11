require('items/generic_datadriven_item')

item_stormbringer_armor = class({})

function item_stormbringer_armor:GetIntrinsicModifierName()
	return "modifier_stormbringer_passive"
end

item_thor_armor = class({})

function item_thor_armor:GetIntrinsicModifierName()
	return "modifier_stormbringer_passive"
end

function item_thor_armor:OnSpellStart()
	local caster = self:GetCaster()
	local point = caster:GetAbsOrigin()
	local bolt_radius = self:GetSpecialValueFor("bolt_radius")
	local bolt_damage = self:GetSpecialValueFor("bolt_damage")


	local nearby_enemies = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, bolt_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for i=1, #nearby_enemies do
		local enemy = nearby_enemies[i]
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			damage = bolt_damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			damage_flags = 0,
			ability = self
		})

		EmitSoundOn("Hero_Zuus.GodsWrath.Target", enemy)
		local effect = "particles/econ/items/zeus/arcana_chariot/zeus_arcana_blink_start.vpcf"
		local pfx = ParticleManager:CreateParticle(effect, PATTACH_ABSORIGIN_FOLLOW, enemy)
		ParticleManager:SetParticleControl(pfx, 0, enemy:GetAbsOrigin()) -- Origin
		ParticleManager:ReleaseParticleIndex(pfx)

	end

end

modifier_stormbringer_passive = class({
	IsHidden 				= function(self) return true end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	GetAttributes 			= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions		= function(self) return
		{
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_EVENT_ON_ATTACK_LANDED
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } end
})
function modifier_stormbringer_passive:OnCreated()
	local ability = self:GetAbility()
	self.parent = self:GetParent()
	self.armor_bonus = ability:GetSpecialValueFor("armor_bonus")
	self.health_bonus = ability:GetSpecialValueFor("health_bonus")
	self.dmg_bonus = ability:GetSpecialValueFor("dmg_bonus")
end

function modifier_stormbringer_passive:GetModifierPhysicalArmorBonus()
	return self.armor_bonus
end

function modifier_stormbringer_passive:GetModifierBonusHealth()
	return self.health_bonus
end

function modifier_stormbringer_passive:GetModifierPreAttack_BonusDamage()
	return self.dmg_bonus
end

function modifier_stormbringer_passive:OnAttackLanded( keys )
	if IsServer() then
		local shield_owner = self:GetParent()
		-- If this damage event is irrelevant, do nothing
		if shield_owner ~= keys.target then
			return end

		-- If the attacker is invalid, do nothing either
		if keys.attacker:GetTeam() == shield_owner:GetTeam() then
			return end

		-- All conditions met, stack the proc counter up
		local ability = self:GetAbility()
		-- If enough stacks accumulated, reset them and zap nearby enemies
		local static_proc_chance = ability:GetSpecialValueFor("static_proc_chance")
		local static_damage = ability:GetSpecialValueFor("static_damage")
		local static_radius = ability:GetSpecialValueFor("static_radius")
		local unit_count = 	ability:GetSpecialValueFor("unit_count")
		if RollPercentage(static_proc_chance) then

			-- Iterate through nearby enemies
			local static_origin = shield_owner:GetAbsOrigin() + Vector(0, 0, 100)
			local nearby_enemies = FindUnitsInRadius(shield_owner:GetTeamNumber(), shield_owner:GetAbsOrigin(), nil, static_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_ANY_ORDER, false)

			for _, enemy in pairs(nearby_enemies) do

				-- Play particle
				local static_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning_.vpcf", PATTACH_ABSORIGIN_FOLLOW, shield_owner)
--				local static_pfx = ParticleManager:CreateParticle("particles/items2_fx/mjollnir_shield_sparkpoints_child.vpcf", PATTACH_ABSORIGIN_FOLLOW, shield_owner)
				ParticleManager:SetParticleControlEnt(static_pfx, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
				ParticleManager:SetParticleControl(static_pfx, 1, static_origin)
				ParticleManager:ReleaseParticleIndex(static_pfx)

				-- Apply damage
				ApplyDamage({attacker = shield_owner, victim = enemy, ability = ability, damage = static_damage, damage_type = DAMAGE_TYPE_MAGICAL})

			end

			-- Play hit sound if at least one enemy was hit
			if #nearby_enemies > 0 then
				shield_owner:EmitSound("Item.Maelstrom.Chain_Lightning.Jump")
			end
		end
	end
end

LinkLuaModifier("modifier_stormbringer_passive", "items/item_stormbringer", LUA_MODIFIER_MOTION_NONE, modifier_stormbringer_passive)
