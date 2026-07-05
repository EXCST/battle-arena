require('items/generic_datadriven_item')


item_soul_gem = class({})

function item_soul_gem:GetIntrinsicModifierName()
	return "modifier_soul_gem"
end

modifier_soul_gem = class({
	IsHidden 				= function(self) return true end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return false end,
})
function modifier_soul_gem:OnCreated()
	if IsServer() then
		self.vision_radius = self:GetAbility():GetSpecialValueFor("vision_radius")
	end
end

function modifier_soul_gem:GetEffectName()
	return "particles/econ/wards/f2p/f2p_ward/f2p_ward_true_sight_ambient.vpcf"
end
function modifier_soul_gem:IsAura()
	return true
end
function modifier_soul_gem:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end
function modifier_soul_gem:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end
function modifier_soul_gem:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end
function modifier_soul_gem:GetAuraRadius()
	return self.vision_radius 
end
function modifier_soul_gem:GetModifierAura()
	return "modifier_truesight"
end



LinkLuaModifier("modifier_soul_gem", "items/custom/item_soul_gem", LUA_MODIFIER_MOTION_NONE, modifier_soul_gem)
LinkLuaModifier("modifier_soul_gem_vision", "items/custom/item_soul_gem", LUA_MODIFIER_MOTION_NONE, modifier_soul_gem_vision)
