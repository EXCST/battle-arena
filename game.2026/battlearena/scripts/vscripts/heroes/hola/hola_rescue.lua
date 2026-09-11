hola_rescue = hola_rescue or class({})


function hola_rescue:IsHiddenWhenStolen() return false end


function hola_rescue:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_oracle/oracle_false_promise.vpcf", context)
end


function hola_rescue:OnSpellStart()
	local caster = self:GetCaster()

	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")

	local allies = FindUnitsInRadius(
		caster:GetTeamNumber(), caster:GetOrigin(), caster, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false
	)

	local grace_ability = caster:FindAbilityByName("hola_grace")
	local apply_grace = self:GetSpecialValueFor("apply_grace") > 0 and IsValidEntity(grace_ability)

	for _, ally in pairs(allies) do
		ally:Purge(false, true, false, true, true)

		ally:AddNewModifier(caster, self, "modifier_oracle_false_promise", {duration = duration})

		if apply_grace then
			grace_ability:Apply(ally)
		end
	end

	EmitSoundOnClient("keeper_of_the_light_keep_spiritform_0" .. RandomInt(1, 6), caster:GetPlayerOwner())
end