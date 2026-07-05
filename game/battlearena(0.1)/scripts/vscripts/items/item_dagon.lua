require('items/generic_datadriven_item')

item_dagon_custom = class({
	GetIntrinsicModifierName = function() 
		return "modifier_item_dagon_custom" 
	end
})

function item_dagon_custom:Precache(context)
	PrecacheResource("particle", "particles/custom/items/dagon/dagon.vpcf", context)
end

function item_dagon_custom:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local ability = self
	local particle_hit = "particles/custom/items/dagon/dagon.vpcf"
	
	-- If the target possesses a ready Linken's Sphere, do nothing
	if target:GetTeam() ~= caster:GetTeam() then
		if target:TriggerSpellAbsorb(ability) then
			return nil
		end
	end

	-- If the target is magic immune (Lotus Orb/Anti Mage), do nothing
	if target:IsMagicImmune() then
		return nil
	end

	EmitSoundOn("Item.Dagon.Cast", caster)
	EmitSoundOn("Item.Dagon.Target", target)
	-- Parameters
	local damage_int = ability:GetSpecialValueFor("damage_int")/100 * caster:GetPrimaryStatValue()
	local damage = ability:GetSpecialValueFor("damage") + damage_int
	local bounce_damage = damage
	local bounce_range = ability:GetSpecialValueFor("bounce_range")
	local targets_hit = {
		target
	}
	local search_sources = {
		target
	}

	-- Determine dagon color
	local dagon_colors = {}
	dagon_colors["item_dagon_custom_1"] = Vector(0.4, 0.0, 0.0)
	dagon_colors["item_dagon_custom_2"] = Vector(0.2, 0.0, 0.2)
	dagon_colors["item_dagon_custom_3"] = Vector(0.0, 0.15, 0.25)
	dagon_colors["item_dagon_custom_4"] = Vector(0.3, 0.3, 0.0)
	dagon_colors["item_dagon_custom_5"] = Vector(0.0, 0.4, 0.0)

	-- Dagonize the main target
	self:DagonizeIt(caster, ability, caster, target, damage, particle_hit, dagon_colors[ability:GetAbilityName()])

	-- While there are potential sources, keep looping
	while #search_sources > 0 do

		-- Loop through every potential source this iteration
		for potential_source_index, potential_source in pairs(search_sources) do

			-- Iterate through potential targets near this source
			local nearby_enemies = FindUnitsInRadius(caster:GetTeamNumber(), potential_source:GetAbsOrigin(), nil, bounce_range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_ANY_ORDER, false)
			for _, potential_target in pairs(nearby_enemies) do

				-- Check if this target was already hit
				local already_hit = false
				for _, hit_target in pairs(targets_hit) do
					if potential_target == hit_target then
						already_hit = true
						break
					end
				end

				-- If not, dagonize it from this source, and mark it as a hit target and potential future source
				if not already_hit then
					self:DagonizeIt(caster, ability, potential_source, potential_target, bounce_damage, particle_hit, dagon_colors[ability:GetAbilityName()] + Vector(RandomFloat(0, 0.3), RandomFloat(0, 0.3), RandomFloat(0, 0.3)))
					targets_hit[#targets_hit+1] = potential_target
					search_sources[#search_sources+1] = potential_target
				end
			end

			-- Remove this potential source
			table.remove(search_sources, potential_source_index)
		end
	end
end

function item_dagon_custom:DagonizeIt(caster, ability, source, target, damage, particle, color)

	-- Draw particle
	local dagon_pfx = ParticleManager:CreateParticle(particle, PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlEnt(dagon_pfx, 0, source, PATTACH_POINT_FOLLOW, "attach_attack1", source:GetAbsOrigin(), false)
	ParticleManager:SetParticleControlEnt(dagon_pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
	ParticleManager:SetParticleControl(dagon_pfx, 2, Vector(500, 0, 0))
	ParticleManager:SetParticleControl(dagon_pfx, 3, color * 255)
	ParticleManager:ReleaseParticleIndex(dagon_pfx)

	-- Deal damage to the target
	ApplyDamage({attacker = caster, victim = target, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
end

item_dagon_custom_1 = class(item_dagon_custom)
item_dagon_custom_2 = class(item_dagon_custom)
item_dagon_custom_3 = class(item_dagon_custom)
item_dagon_custom_4 = class(item_dagon_custom)
item_dagon_custom_5 = class(item_dagon_custom)

modifier_item_dagon_custom = class({
	IsHidden = function() 
		return true 
	end,
	IsPurgable = function() 
		return false 
	end,
	IsPurgeException = function()
		return false
	end,
	DeclareFunctions = function() 
		return 
		{
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
		} 
	end,
	GetModifierBonusStats_Strength = function(self) 
		return self.bonusStr 
	end,
	GetModifierBonusStats_Agility = function(self) 
		return self.bonusAgi 
	end,
	GetModifierBonusStats_Intellect = function(self) 
		return self.bonusInt 
	end,
	GetAttributes = function()
		return MODIFIER_ATTRIBUTE_MULTIPLE
	end
})

function modifier_item_dagon_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_dagon_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusStr = self.ability:GetSpecialValueFor("bonus_intellect_real")
    self.bonusAgi = self.ability:GetSpecialValueFor("bonus_all_stats")
    self.bonusInt = self.ability:GetSpecialValueFor("bonus_all_stats")
end

LinkLuaModifier("modifier_item_dagon_custom", "items/item_dagon", LUA_MODIFIER_MOTION_NONE, modifier_item_dagon_custom)