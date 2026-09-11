require('lib/ability_kv')


saber_invisible_air = class({
	GetIntrinsicModifierName = function() return "modifier_saber_invisible_air" end,
})

if IsServer() then
	function saber_invisible_air:OnSpellStart()
		local caster = self:GetCaster()
		caster:EmitSound("Arena.Hero_Saber.InvisibleAir")
		local modifier = caster:FindModifierByName("modifier_saber_invisible_air")
		local damage = modifier and modifier.stacks or 0
		if modifier then
			modifier.stacks = 0
			modifier:SetStackCount(0)
		end
		local teamFilter = self:GetAbilityTargetTeam()
		local typeFilter = self:GetAbilityTargetType()
		local flagFilter = self:GetAbilityTargetFlags()
		local teamNumber = caster:GetTeamNumber()
		local position = caster:GetAbsOrigin() + caster:GetForwardVector() * AbilityKV:Get(self, "forward_offset")
		local radius = AbilityKV:Get(self, "aoe_radius")
		local force = AbilityKV:Get(self, "push_velocity")
		for _,v in ipairs(FindUnitsInRadius(teamNumber, position, nil, radius, teamFilter, typeFilter, flagFilter, FIND_ANY_ORDER, false)) do
			v:AddNewModifier(caster, self, "modifier_knockback", {
				center_x = position.x,
				center_y = position.y,
				center_z = position.z,
				duration = force / 1000,
				knockback_duration = force / 1000,
				knockback_distance = force / 2,
				knockback_height = force / 50,
			})

			ApplyDamage({
				victim = v,
				attacker = caster,
				damage = damage,
				damage_type = self:GetAbilityDamageType(),
				damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
				ability = self
			})
		end

		local pfx = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_saber/invisible_air.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(pfx, 0, position)
		ParticleManager:SetParticleControl(pfx, 1, Vector(radius))
	end
end


modifier_saber_invisible_air = class({
	IsPurgable = function() return false end,
})

if IsServer() then
	function modifier_saber_invisible_air:OnCreated()
		self:StartIntervalThink(0.1)
	end

	function modifier_saber_invisible_air:OnIntervalThink()
		local ability = self:GetAbility()
		self.stacks = math.min((self.stacks or 0) + AbilityKV:Get(ability, "damage_per_second") * 0.1, AbilityKV:Get(ability, "damage_max"))
		self:SetStackCount(self.stacks)
	end
else
	function modifier_saber_invisible_air:DeclareFunctions()
		return {MODIFIER_PROPERTY_TOOLTIP}
	end
	function modifier_saber_invisible_air:OnTooltip()
		return self:GetStackCount()
	end
end
