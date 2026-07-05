
function SavageRoar( event )
	local caster = event.caster
	local ability = event.ability
	local origin = caster:GetAbsOrigin()
	local radius = ability:GetSpecialValueFor("radius")
	local duration = ability:GetSpecialValueFor("duration")

	local effect = "particles/units/heroes/hero_lone_druid/lone_druid_savage_roar.vpcf"
	ParticleManager:CreateParticle(effect, PATTACH_ABSORIGIN_FOLLOW, caster)
	
	local enemies = FindUnitsInRadius(caster:GetTeam(),
									 origin, 
									 caster, 
									 radius, 
									 DOTA_UNIT_TARGET_TEAM_ENEMY, 
									 DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 
									 DOTA_UNIT_TARGET_FLAG_NONE, 
									 FIND_CLOSEST, 
									 false)

	for _,unit in pairs(enemies) do
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_lone_druid_savage_roar_debuff", {duration = duration})
	end
	
end


