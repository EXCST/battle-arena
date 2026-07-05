function ChickenRush( keys )

	local ability = keys.ability
	local caster = keys.caster
	local chicken_count = ability:GetSpecialValueFor( "chicken_count" )
	local interval = ability:GetSpecialValueFor( "spawn_interval" )
	local chicken_duration = ability:GetSpecialValueFor( "chicken_duration" )

	local unit_name = "npc_dota_mad_chicken"--..RandomOrder[i]
	EmitSoundOn("ChickenKing.ChickenRush", caster)
	
	for i=1,chicken_count do
		Timers:CreateTimer(interval*i, function ()
			-- 7.31 cause crash if something is null
			if(caster and caster:IsNull() == false and ability and ability:IsNull() == false) then
				local chicken = CreateSummon(
					caster, 
					unit_name, 
					caster:GetAbsOrigin() + RandomInt(25, 100), 
					chicken_duration, 
					nil, 
					nil, 
					nil, 
					nil
				)
			end
		end)
	end
	
end

--sounds/weapons/hero/vengeful_spirit/chicken_dance.vsnd
--sounds/weapons/hero/skywrath/taunt_chicken.vsnd
--sounds/ambient/chicken.vsnd