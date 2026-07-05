require('items/generic_datadriven_item')

item_unhallowed_icon = class({})


--------------------------------------------------------------------------------

function item_unhallowed_icon:GetIntrinsicModifierName()
	return "modifier_item_unhallowed_icon"
end

modifier_item_unhallowed_icon = class({})

--------------------------------------------------------------------------------

function modifier_item_unhallowed_icon:IsHidden() 
	return true
end

--------------------------------------------------------------------------------

function modifier_item_unhallowed_icon:IsPurgable()
	return false
end

----------------------------------------

function modifier_item_unhallowed_icon:IsAura()
	return true
end

----------------------------------------

function modifier_item_unhallowed_icon:GetModifierAura()
	return  "modifier_item_unhallowed_icon_effect"
end

----------------------------------------

function modifier_item_unhallowed_icon:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

----------------------------------------

function modifier_item_unhallowed_icon:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

----------------------------------------

function modifier_item_unhallowed_icon:GetAuraRadius()
	return self.radius
end

----------------------------------------

function modifier_item_unhallowed_icon:OnCreated( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.bonus_strength = self:GetAbility():GetSpecialValueFor( "bonus_strength" )
end

----------------------------------------

function modifier_item_unhallowed_icon:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
	return funcs
end

----------------------------------------

function modifier_item_unhallowed_icon:GetModifierBonusStats_Strength( params )
	return self.bonus_strength
end


modifier_item_unhallowed_icon_effect = class({})

function modifier_item_unhallowed_icon_effect:OnCreated( kv )
	self.lifesteal_pct = self:GetAbility():GetSpecialValueFor( "lifesteal_pct" )
	self.hp_regen = self:GetAbility():GetSpecialValueFor( "hp_regen" )
end

----------------------------------------

function modifier_item_unhallowed_icon_effect:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
	return funcs
end

----------------------------------------

function modifier_item_unhallowed_icon_effect:GetModifierConstantHealthRegen( params )
	return self.hp_regen
end

----------------------------------------

function modifier_item_unhallowed_icon_effect:OnTakeDamage( params )
	if IsServer() then
		local Target = params.unit
		local Attacker = params.attacker
		local Ability = params.inflictor
		local flDamage = params.damage
		
		if Attacker ~= nil and Attacker == self:GetParent() and Target ~= nil and not Target:IsBuilding() and Ability == nil then
			local allies = FindUnitsInRadius( Attacker:GetTeamNumber(), self:GetCaster():GetOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
			for _,ally in pairs( allies ) do
				if ally ~= nil and ally:FindModifierByName( "modifier_item_unhallowed_icon_effect" ) then
					local heal = ( flDamage * self.lifesteal_pct / 100 ) / #allies
					ally:Heal( heal, self:GetAbility(), DOTA_HEAL_TYPE_HEALING)
				end
			end
		end
	end
	return 0
end






LinkLuaModifier("modifier_item_unhallowed_icon", "items/siltbreaker/item_unhallowed_icon", LUA_MODIFIER_MOTION_NONE ,  modifier_item_unhallowed_icon)
LinkLuaModifier("modifier_item_unhallowed_icon_effect", "items/siltbreaker/item_unhallowed_icon", LUA_MODIFIER_MOTION_NONE ,  modifier_item_unhallowed_icon_effect)
