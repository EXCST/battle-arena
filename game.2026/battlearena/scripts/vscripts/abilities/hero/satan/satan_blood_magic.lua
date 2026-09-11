satan_blood_magic = satan_blood_magic or class({})
LinkLuaModifier("modifier_satan_blood_magic", "abilities/hero/satan/satan_blood_magic", LUA_MODIFIER_MOTION_NONE)


function satan_blood_magic:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_axe/axe_counterhelix_ad.vpcf", context)
end


function satan_blood_magic:Spawn()
	if not IsServer() then return end
	-- for some reason innate intrinsic gets immediately destroyed, so have to refresh it manually
	Timers:CreateTimer(0.5, function()
		if not IsValidEntity(self) then return end
		self:RefreshIntrinsicModifier()
	end)
end


function satan_blood_magic:GetIntrinsicModifierName()
	return "modifier_satan_blood_magic"
end



modifier_satan_blood_magic = modifier_satan_blood_magic or class({})

function modifier_satan_blood_magic:IsHidden() return false end
function modifier_satan_blood_magic:IsPurgable() return false end
function modifier_satan_blood_magic:RemoveOnDeath() return false end
function modifier_satan_blood_magic:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end


function modifier_satan_blood_magic:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	self.health_cost_as_damage = self.ability:GetSpecialValueFor("health_cost_as_damage") / 100.0
	self.radius = self.ability:GetSpecialValueFor("radius")
end


function modifier_satan_blood_magic:OnRefresh()
	self.health_cost_as_damage = self.ability:GetSpecialValueFor("health_cost_as_damage") / 100.0
	self.radius = self.ability:GetSpecialValueFor("radius")
end


function modifier_satan_blood_magic:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_CONVERT_MANA_COST_TO_HEALTH_COST, -- GetModifierConvertManaCostToHealthCost
		MODIFIER_EVENT_ON_SPENT_HEALTH, -- OnSpentHealth
	}
end


function modifier_satan_blood_magic:GetModifierConvertManaCostToHealthCost()
	return 100
end


if not IsServer() then return end


function modifier_satan_blood_magic:OnSpentHealth(event)
	if event.unit ~= self.parent then return end
	local cost = event.health_cost
	local damage = cost * self.health_cost_as_damage

	local targets = FindUnitsInRadius(
		self.parent:GetTeam(),
		self.parent:GetAbsOrigin(),
		nil,
		self.radius or 1,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
		0,
		FIND_ANY_ORDER,
		false
	)

	local damage_table = {
		damage 			= damage,
		damage_type		= DAMAGE_TYPE_MAGICAL,
		damage_flags	= DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL,
		attacker 		= self.parent,
		victim 			= nil,
		ability 		= self.ability,
	}

	for _, enemy in pairs(targets) do
		if IsValidEntity(enemy) then
			damage_table.victim = enemy
			ApplyDamage(damage_table)
		end
	end

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_counterhelix_ad.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:ReleaseParticleIndex(particle)

	return 0
end
