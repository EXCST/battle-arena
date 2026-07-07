OnNPCSpawnedListener = OnNPCSpawnedListener or class({})

function OnNPCSpawnedListener:OnNPCSpawned(event)
	local spawnedUnit = EntIndexToHScript(event.entindex)
	if not spawnedUnit then return end
	
	if spawnedUnit and spawnedUnit:IsRealHero() then
		if spawnedUnit.medical_tractates then
			spawnedUnit:RemoveModifierByName("modifier_medical_tractate")
			spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_medical_tractate", { duration = -1 })
		end
	end
end
