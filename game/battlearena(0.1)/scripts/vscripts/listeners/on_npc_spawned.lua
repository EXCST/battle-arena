OnNPCSpawnedListener = OnNPCSpawnedListener or class({})

function OnNPCSpawnedListener:OnNPCSpawned(event)
	local spawnedUnit = EntIndexToHScript(event.entindex)
	if not spawnedUnit then return end
	
	if spawnedUnit and spawnedUnit:IsRealHero() then
		-- Если вы удалили item_golden_lock, вам нужно удалить или заменить этот блок кода
		-- if not spawnedUnit.golden_lock then
		-- 	spawnedUnit.golden_lock = true
		-- 	local item = CreateItem('item_golden_lock', nil, nil)
		-- 	if item then
		-- 		spawnedUnit:AddItem(item)
		-- 		item:SetDroppable(false)
		-- 		item:SetSellable(false)
		-- 		item:SetPurchaser(nil)
		-- 		item:StartCooldown(GOLDEN_LOCK_CD)
				
		-- 		Timers:CreateTimer(
		-- 			GOLDEN_LOCK_CD,
		-- 			function()
		-- 				item:SetPurchaser(spawnedUnit)
		-- 			end
		-- 		)
		-- 	else
		-- 		print("Ошибка: Не удалось создать предмет 'item_golden_lock'")
		-- 	end
		-- end
	
		if spawnedUnit.medical_tractates then
			spawnedUnit:RemoveModifierByName("modifier_medical_tractate")
			spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_medical_tractate", { duration = -1 })
		end
	end
end
