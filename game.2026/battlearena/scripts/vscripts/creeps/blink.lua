require('lib/ability_kv')

function Blink(keys)
	local point = keys.target_points[1]
	local caster = keys.caster
	local casterPos = caster:GetAbsOrigin()
	local difference = point - casterPos
	local ability = keys.ability
	local range = AbilityKV:Get(ability, "blink_range")
	if not range or range <= 0 then range = 2150 end

	ProjectileManager:ProjectileDodge(caster)

	if difference:Length2D() > range then
		point = casterPos + (point - casterPos):Normalized() * range
	end

	FindClearSpaceForUnit(caster, point, false)	
end
