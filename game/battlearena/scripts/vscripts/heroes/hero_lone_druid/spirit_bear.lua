
lone_druid_spirit_bear_datadriven = class({})

function lone_druid_spirit_bear_datadriven:OnSpellStart(isUpgrade)
	local caster = self:GetCaster()
	local player = caster:GetPlayerID()
	if caster.bear then
		caster.bear:RespawnUnit()
	else
		caster.bear = CreateSummon(
			caster, 
			"npc_dota_lone_druid_bear1", 
			caster:GetAbsOrigin(), 
			-1, 
			nil, 
			nil, 
			nil, 
			nil
		)
		caster.bear:SetUnitCanRespawn(true)
		caster.bear:AddNewModifier(caster, self, "modifier_spirit_bear_custom_bear", nil)
	end
	local pidx = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_bear_spawn.vpcf", PATTACH_POINT, caster)
	ParticleManager:SetParticleControlEnt(pidx, 0, caster.bear, PATTACH_POINT_FOLLOW, "attach_hitloc", caster.bear:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(pidx)
	EmitSoundOn("Hero_LoneDruid.SpiritBear.Cast", caster)
	if(not isUpgrade) then
		FindClearSpaceForUnit(caster.bear, caster:GetAbsOrigin(), true)
		caster.bear:SetForwardVector(caster:GetForwardVector())
	else
		if(caster.bear.modifier and caster.bear.modifier:IsNull() == false) then
			caster.bear.modifier:ForceRefresh()
		end
	end
	local abilities = {
		"lone_druid_spirit_bear_return",
		"lone_druid_spirit_bear_resist",
		"lone_druid_spirit_bear_vitality"
	}
	for _, abilityName in pairs(abilities) do
		local ability = caster.bear:FindAbilityByName(abilityName)
		if(ability) then
			ability:SetLevel(math.max(self:GetLevel(), ability:GetMaxLevel()))
		end
	end
	self:SetBearStats(caster, caster.bear)
end

function lone_druid_spirit_bear_datadriven:OnUpgrade()
	if(self:GetLevel() == 1) then
		return
	end
	local caster = self:GetCaster()
	if(caster and caster.bear and caster.bear:IsAlive()) then
		self:OnSpellStart(true)
	end
end

function lone_druid_spirit_bear_datadriven:SetBearStats(caster, bear)
	local strenght = caster:GetStrength()
	local agility = caster:GetAgility()
	local base_hp = self:GetSpecialValueFor("summon_hp") + (self:GetSpecialValueFor("hp_per_str") * strenght)
	local base_hpreg = self:GetSpecialValueFor("summon_hpreg")
	local base_dmg = self:GetSpecialValueFor("summon_dmg") + (self:GetSpecialValueFor("dmg_per_agi") * agility)
	local base_armor = self:GetSpecialValueFor("summon_armor")
	local model_scale = self:GetSpecialValueFor("summon_scale")
	local bat = self:GetSpecialValueFor("summon_bat")
	UpdateSummon(bear, -1, base_dmg, base_armor, base_hp, bat)
	bear:SetBaseHealthRegen(base_hpreg)
	bear:SetModelScale(model_scale)
end

modifier_spirit_bear_custom_bear = class({
	IsHidden = function() 
		return true 
	end,
	IsPurgable = function()
		 return false
	end,
	RemoveOnDeath = function() 
		return false 
	end,
	DeclareFunctions = function() 
		return {
			MODIFIER_EVENT_ON_DEATH
		} 
	end
})

function modifier_spirit_bear_custom_bear:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.caster = self.ability:GetCaster()
	self.damageTable = {
		victim = self.caster,
		attacker = self.caster,
		ability = self.ability,
		damage = 0,
		damage_type = DAMAGE_TYPE_PURE,
		damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS
	}
	self.parent.modifier = self
	self:OnRefresh()
end

function modifier_spirit_bear_custom_bear:OnRefresh(ignoreRefresh)
	self.ability = self:GetAbility() or self.ability
	if(not self.ability or self.ability:IsNull() == true) then
		return
	end
	self.backlashDamage = self.ability:GetSpecialValueFor("backlash_damage") / 100
end

function modifier_spirit_bear_custom_bear:OnDeath(keys)
	if(keys.unit ~= self.parent) then
		return
	end
	self.damageTable.attacker = keys.attacker
	self.damageTable.victim = self.caster
	self.damageTable.damage = self.caster:GetMaxHealth() * self.backlashDamage
	ApplyDamage(self.damageTable)
end

LinkLuaModifier("modifier_spirit_bear_custom_bear", "abilities/heroes/hero_lone_druid/spirit_bear", LUA_MODIFIER_MOTION_NONE, modifier_spirit_bear_custom_bear)