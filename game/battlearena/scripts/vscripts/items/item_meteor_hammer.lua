require('items/generic_datadriven_item')

item_meteor_hammer_lua	= class({
	GetIntrinsicModifierName = function() return "modifier_item_meteor_hammer_lua" end,
	GetAOERadius = function(self) return self:GetSpecialValueFor("impact_radius") end
})

function item_meteor_hammer_lua:Precache(context)
    PrecacheResource("particle", "particles/custom/items/fallen_sky/fallen_sky.vpcf", context)
    PrecacheResource("particle", "particles/items4_fx/meteor_hammer_spell_debuff.vpcf", context)
	PrecacheResource("particle", "particles/items4_fx/meteor_hammer_aoe.vpcf", context)
	PrecacheResource("particle", "particles/items4_fx/meteor_hammer_cast.vpcf", context)
end

function item_meteor_hammer_lua:GetChannelTime()
	return self:GetSpecialValueFor("channel_time")
end

function item_meteor_hammer_lua:OnSpellStart()
	self.burn_duration = self:GetSpecialValueFor("burn_duration")
	self.stun_duration = self:GetSpecialValueFor("stun_duration")
	self.burn_interval = self:GetSpecialValueFor("burn_interval")
	self.land_time = self:GetSpecialValueFor("land_time")
	self.impact_radius = self:GetSpecialValueFor("impact_radius")
	self.impact_damage_buildings = self:GetSpecialValueFor("impact_damage_buildings")
	self.impact_damage_units = self:GetSpecialValueFor("impact_damage_units")

	if IsServer() then
		self.vPosition	= self:GetCursorPosition()

		EmitSoundOn("Item.MeteorHammer.Channel", self:GetCaster())

		AddFOWViewer(self:GetCaster():GetTeam(), self.vPosition, self.impact_radius, 3.8, false)

		self.nParticleIndex	= ParticleManager:CreateParticleForTeam("particles/items4_fx/meteor_hammer_aoe.vpcf", PATTACH_WORLDORIGIN, self:GetCaster(), self:GetCaster():GetTeam())
		ParticleManager:SetParticleControl(self.nParticleIndex, 0, self.vPosition)
		ParticleManager:SetParticleControl(self.nParticleIndex, 1, Vector(self.impact_radius, 1, 1))
		self.nParticleIndex2 = ParticleManager:CreateParticle("particles/items4_fx/meteor_hammer_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW,self:GetCaster())
    end
end


function item_meteor_hammer_lua:OnChannelFinish(bInterrupted)
	if not IsServer() then
		return
	end

	if bInterrupted then
		StopSoundOn("Item.MeteorHammer.Channel", self:GetCaster())
		ParticleManager:DestroyParticle(self.nParticleIndex, true)
		ParticleManager:DestroyParticle(self.nParticleIndex2, true)
	else
		EmitSoundOn("Item.MeteorHammer.Cast", self:GetCaster())
		local pidx = ParticleManager:CreateParticle("particles/custom/items/fallen_sky/fallen_sky.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
		ParticleManager:SetParticleControl(pidx, 0, self.vPosition + Vector(0, 0, 1000))
		ParticleManager:SetParticleControl(pidx, 1, self.vPosition)
		ParticleManager:SetParticleControl(pidx, 2, Vector(self.land_time, 0, 0))
		ParticleManager:ReleaseParticleIndex(pidx, self.land_time)
		Timers:CreateTimer(self.land_time, function()
			if self and not self:IsNull() then
				GridNav:DestroyTreesAroundPoint(self.vPosition, self.impact_radius, true)
				EmitSoundOnLocationWithCaster(self.vPosition, "Item.MeteorHammer.Impact", self:GetCaster())
				local vEnemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self.vPosition, nil, self.impact_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BUILDING + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
				for _, hEnemy in pairs(vEnemies) do
					hEnemy:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = self.stun_duration})
					hEnemy:AddNewModifier(self:GetCaster(), self, "modifier_item_meteor_hammer_lua_burn", {duration = self.burn_duration})
					local damageTable = {
						victim 			= hEnemy,
						damage 			= self.impact_damage_units,
						damage_type		= DAMAGE_TYPE_MAGICAL,
						damage_flags 	= DOTA_DAMAGE_FLAG_NONE,
						attacker 		= self:GetCaster(),
						ability 		= self
					}
					ApplyDamage(damageTable)
				end
			end
		end, self)
	end

	ParticleManager:ReleaseParticleIndex(self.nParticleIndex)
	ParticleManager:ReleaseParticleIndex(self.nParticleIndex2)
end

modifier_item_meteor_hammer_lua = class({
	IsHidden = function() return true end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	IsPurgable = function()
		return false
	end,
	IsPurgeException = function()
		return false
	end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
	} end,
	GetModifierExtraManaBonus = function(self) return self.bonus_mana end,
	GetModifierConstantManaRegen = function(self) return self.bonus_mp_regen end,
	GetModifierBonusStats_Strength = function(self) return self.bonus_allstats end,
	GetModifierBonusStats_Agility = function(self) return self.bonus_allstats end,
	GetModifierBonusStats_Intellect = function(self) return self.bonus_allstats end,
	GetTexture = function(self)
		return self.buffIcon
	end
})

function modifier_item_meteor_hammer_lua:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
	if not IsServer() then 
		self.buffIcon = self.ability:GetAbilityTextureName()
		return 
	end
end


function modifier_item_meteor_hammer_lua:OnRefresh()
	self.ability = self:GetAbility() or self.ability
	if(not self.ability or self.ability:IsNull()) then
		return
	end
	self.bonus_mana = self.ability:GetSpecialValueFor("bonus_mana")
	self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
	self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
end

modifier_item_meteor_hammer_lua_burn = class({
	GetEffectName = function() return "particles/items4_fx/meteor_hammer_spell_debuff.vpcf" end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end
})

function modifier_item_meteor_hammer_lua_burn:OnCreated()
	if IsServer() then
		self.burn_dps = self:GetAbility():GetSpecialValueFor("burn_dps_units") + self:GetCaster():GetPrimaryStatValue()*self:GetAbility():GetSpecialValueFor("burn_dps_units_int_pct")/100
		self.burn_interval=self:GetAbility():GetSpecialValueFor("burn_interval")

		self:StartIntervalThink(self.burn_interval)
    end
end

function modifier_item_meteor_hammer_lua_burn:OnIntervalThink()
	if IsServer() then
		ApplyDamage({
			victim 			= self:GetParent(),
			damage 			= self.burn_dps,
			damage_type		= DAMAGE_TYPE_MAGICAL,
			damage_flags 	= DOTA_DAMAGE_FLAG_NONE,
			attacker 		= self:GetCaster(),
			ability 		= self:GetAbility()
		})
	end

end


item_meteor_hammer_1 = class(item_meteor_hammer_lua)
item_meteor_hammer_2 = class(item_meteor_hammer_lua)
item_meteor_hammer_3 = class(item_meteor_hammer_lua)
item_meteor_hammer_4 = class(item_meteor_hammer_lua)
item_meteor_hammer_5 = class(item_meteor_hammer_lua)
item_meteor_hammer_6 = class(item_meteor_hammer_lua)

LinkLuaModifier("modifier_item_meteor_hammer_lua", "items/item_meteor_hammer", LUA_MODIFIER_MOTION_NONE, modifier_item_meteor_hammer_lua)
LinkLuaModifier("modifier_item_meteor_hammer_lua_burn", "items/item_meteor_hammer", LUA_MODIFIER_MOTION_NONE, modifier_item_meteor_hammer_lua_burn)