joe_black_song = joe_black_song or class({})
LinkLuaModifier("modifier_joe_black_song_buff", "heroes/joeblack/joe_black_song", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_joe_black_song_debuff", "heroes/joeblack/joe_black_song", LUA_MODIFIER_MOTION_NONE)


function joe_black_song:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end


function joe_black_song:OnSpellStart()
	local caster = self:GetCaster()
	local team = caster:GetTeamNumber()
	local position = caster:GetAbsOrigin()

	self.active_targets = self.active_targets or {}

	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")
	local apply_on_allies = self:GetSpecialValueFor("ally_health_regen_pct") > 0

	local units = FindUnitsInRadius(
		team,
		position,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_CLOSEST,
		false
	)

	for _, unit in pairs(units) do
		if unit:GetTeamNumber() == team then
			if apply_on_allies then
				unit:AddNewModifier(caster, self, "modifier_joe_black_song_buff", {duration = duration})
			end
		else
			unit:AddNewModifier(caster, self, "modifier_joe_black_song_debuff", {duration = duration})
		end
	end

	local song_part = ParticleManager:CreateParticle("particles/econ/items/queen_of_pain/qop_2022_immortal/queen_2022_scream_of_pain_owner_blue.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(song_part, 0, position)
	ParticleManager:SetParticleControl(song_part, 1, position)
	ParticleManager:SetParticleControl(song_part, 2, position)
	ParticleManager:ReleaseParticleIndex(song_part)

	caster:EmitSound("Hero_QueenOfPain.SonicWave")
end



modifier_joe_black_song_buff = modifier_joe_black_song_buff or class({})


function modifier_joe_black_song_buff:IsPurgable() return false end
function modifier_joe_black_song_buff:IsPurgeException() return true end


function modifier_joe_black_song_buff:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	if not IsValidEntity(self.ability) then return end

	self.regen_pct = self.ability:GetSpecialValueFor("ally_health_regen_pct")

	if not IsServer() then return end

	self.ability.active_targets[self.parent:GetEntityIndex()] = self.parent
end


function modifier_joe_black_song_buff:OnDestroy()
	if not IsServer() then return end

	if not IsValidEntity(self.ability) or not IsValidEntity(self.parent) then return end

	self.ability.active_targets[self.parent:GetEntityIndex()] = nil
end


function modifier_joe_black_song_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
	}
end


function modifier_joe_black_song_buff:GetModifierHealthRegenPercentage()
	return self.regen_pct
end



modifier_joe_black_song_debuff = modifier_joe_black_song_debuff or class({})


function modifier_joe_black_song_debuff:IsPurgable() return false end
function modifier_joe_black_song_debuff:IsPurgeException() return true end


function modifier_joe_black_song_debuff:GetEffectName()
	return "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell_fear_debuff.vpcf"
end


function modifier_joe_black_song_debuff:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()

	self.miss_chance 	   = self.ability:GetSpecialValueFor("miss_chance")
	self.fixed_vision 	   = self.ability:GetSpecialValueFor("fixed_vision")
	self.status_resistance = -self.ability:GetSpecialValueFor("status_resistance")
	self.finish_damage     = self.ability:GetSpecialValueFor("finish_damage")

	if not IsServer() then return end

	self.damage_table = {
		attacker    = self:GetCaster(),
		victim      = self.parent,
		damage      = self.finish_damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability     = self.ability
	}

	self.ability.active_targets[self.parent:GetEntityIndex()] = self.parent
end


function modifier_joe_black_song_debuff:CheckState()
	return {
		[MODIFIER_STATE_EVADE_DISABLED] = true,
		[MODIFIER_STATE_BLOCK_DISABLED] = true
	}
end


function modifier_joe_black_song_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MISS_PERCENTAGE,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_FIXED_DAY_VISION,
		MODIFIER_PROPERTY_FIXED_NIGHT_VISION
	}
end


function modifier_joe_black_song_debuff:GetModifierMiss_Percentage() return self.miss_chance end
function modifier_joe_black_song_debuff:GetModifierStatusResistanceStacking() return self.status_resistance  end
function modifier_joe_black_song_debuff:GetFixedDayVision() return self.fixed_vision end
function modifier_joe_black_song_debuff:GetFixedNightVision() return self.fixed_vision end


function modifier_joe_black_song_debuff:OnDestroy()
	if not IsServer() then return end
	if not IsValidEntity(self.parent) then return end
	if not IsValidEntity(self.ability) then return end

	ApplyDamage(self.damage_table)

	local dmg_part = ParticleManager:CreateParticle("particles/units/heroes/hero_silencer/silencer_last_word_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl(dmg_part, 0, self.parent:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(dmg_part)

	self.parent:EmitSound("Hero_QueenOfPain.ShadowStrike")
	self.ability.active_targets[self.parent:GetEntityIndex()] = nil
end