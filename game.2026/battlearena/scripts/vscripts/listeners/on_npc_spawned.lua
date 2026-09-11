OnNPCSpawnedListener = OnNPCSpawnedListener or class({})

function OnNPCSpawnedListener:OnNPCSpawned(event)
	local ok, err = pcall(function()
		local spawnedUnit = EntIndexToHScript(event.entindex)
		if not spawnedUnit then return end

		local spawnedName = spawnedUnit:GetUnitName()

		-- diagnostic: stegius / illusion spawns
		if spawnedUnit:IsIllusion() or string.find(spawnedName, "stegius", 1, true) then
			print("[STEGIUS] npc_spawned: " .. tostring(spawnedName) .. " isIll=" .. tostring(spawnedUnit:IsIllusion()) .. " isRealHero=" .. tostring(spawnedUnit:IsRealHero()))
		end

		if spawnedUnit:IsRealHero() then
			-- MANA POOL: обход капа маны 65535 (оверкап-пул)
			if ManaPool then ManaPool:TrackHero(spawnedUnit) end

			if spawnedName == "npc_hero_satan" or spawnedName == "npc_dota_hero_doom_bringer" then
				print("[COSMETICS] Applying Doom Litany to " .. spawnedName)
				spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_doom_litany_cosmetics", {})
			end
			if spawnedUnit.medical_tractates then
				spawnedUnit:RemoveModifierByName("modifier_medical_tractate")
				spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_medical_tractate", { duration = -1 })
			end

			-- STARGAZER: стат-таланты вешаем при спавне (интринзик уровня 0
			-- не создаётся в этой сборке — 2026-08-12). inverse_field: обычный
			-- путь — движковый интринзик при прокачке до 1+ уровня
			-- (GetIntrinsicModifierName, MODIFIER_EVENT_ON_ATTACK_LANDED —
			-- доказанно работает: pet_wolf_vampire); ниже страховка для
			-- спавна с уже прокачанным скиллом.
			if spawnedName == "npc_dota_hero_stargazer" then
				print("[STARGAZER] spawn diag: has_inverse_mod=" .. tostring(spawnedUnit:HasModifier("modifier_stargazer_inverse_field"))
					.. " inv_lvl=" .. tostring((spawnedUnit:FindAbilityByName("stargazer_inverse_field") or {}).GetLevel and spawnedUnit:FindAbilityByName("stargazer_inverse_field"):GetLevel() or "nil"))
				if not spawnedUnit:HasModifier("modifier_stargazer_talent_stats") then
					local ult = spawnedUnit:FindAbilityByName("stargazer_cosmic_countdown")
					spawnedUnit:AddNewModifier(spawnedUnit, ult, "modifier_stargazer_talent_stats", { duration = -1 })
					print("[STARGAZER] talent_stats attached on spawn, ult=" .. tostring(ult))
				end
				if not spawnedUnit:HasModifier("modifier_stargazer_cosmic_countdown") then
					local ult = spawnedUnit:FindAbilityByName("stargazer_cosmic_countdown")
					spawnedUnit:AddNewModifier(spawnedUnit, ult, "modifier_stargazer_cosmic_countdown", {})
					print("[STARGAZER] cosmic_countdown attached on spawn, ult=" .. tostring(ult))
				end
				-- inverse_field: страховка для спавна с УЖЕ прокачанным скиллом
				-- (репик/респавн с сохранёнными уровнями). Обычный путь —
				-- движковый интринзик при прокачке до 1+ уровня
				-- (GetIntrinsicModifierName в inverse_field.lua); уровень 0 =
				-- пассивка не работает.
				local inv = spawnedUnit:FindAbilityByName("stargazer_inverse_field")
				if inv and inv:GetLevel() >= 1 and not spawnedUnit:HasModifier("modifier_stargazer_inverse_field") then
					spawnedUnit:AddNewModifier(spawnedUnit, inv, "modifier_stargazer_inverse_field", {})
					print("[STARGAZER] inverse_field attached on spawn (lvl=" .. inv:GetLevel() .. ")")
				end
			end

			-- MIRRATIE: Sixth Sense (перепорт из BS, 2026-08-13).
			-- 1) SetLevel(1) при спавне — эквивалент BS SetFirstLevel (kv.lua
			--    вызывался в OnCreated способности): пассивка активна с 1
			--    уровня (эвейшн 10%, радиус 940), как в BS.
			-- 2) Додж-холдер: в BS додж жил в общем фильтре урона
			--    INCOMING_DAMAGE_MODIFIERS (у нас его нет) — адаптирован как
			--    скрытый модификатор INCOMING_DAMAGE_PERCENTAGE (паттерн
			--    stargazer cosmic_countdown/talent_stats: вешаем при спавне).
			-- ⚠️ Вариант А (self-сканер) откачен 2026-08-13: FOW-позиция от
			-- self-модификатора видна только своей команде — чувство пропадало.
			if spawnedName == "npc_dota_hero_mirratie" then
				local sixth = spawnedUnit:FindAbilityByName("mirratie_sixth_sense")
				if sixth then
					if sixth:GetLevel() == 0 then
						sixth:SetLevel(1)
						print("[MIRRATIE] sixth_sense forced to lvl 1 on spawn")
					end
					if not spawnedUnit:HasModifier("modifier_mirratie_sixth_sense_dodge") then
						spawnedUnit:AddNewModifier(spawnedUnit, sixth, "modifier_mirratie_sixth_sense_dodge", { duration = -1 })
						print("[MIRRATIE] sixth_sense dodge holder attached on spawn")
					end
				end

				-- DARKBLADE ADEPT: одеваем сет рантайм-пропами (паттерн
				-- modifier_doom_litany_cosmetics; KV AttachWearables в секции
				-- героя в этой сборке молча игнорируется — см. пометку stargazer).
				if not spawnedUnit:HasModifier("modifier_mirratie_darkblade") then
					spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_mirratie_darkblade", { duration = -1 })
					print("[MIRRATIE] darkblade adept attached on spawn")
				end
			end

			-- AUGMENTS: init augments on first spawn / after repick
			local player_id = spawnedUnit:GetPlayerOwnerID()
			if IsValidPlayerID(player_id) then
				spawnedUnit.augment_state = spawnedUnit.augment_state or {}

				if not spawnedUnit:HasModifier("modifier_augment_overrider") then
					spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_augment_overrider", {})
				end

				if not spawnedUnit:HasModifier("modifier_augment_primary_reader") then
					spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_augment_primary_reader", {duration = -1})
				end

				Augments:AttachCarrier(spawnedUnit)

				if not spawnedUnit.augments_initialized then
					spawnedUnit.augments_initialized = true
					RerollBank:PreparePlayer(player_id)
				end

				-- MR от инта отключён движковым проперти (modifier_override_magic_resist),
				-- ценность инта возвращена через spell amp (modifier_spell_amp_from_int)
				if not spawnedUnit:HasModifier("modifier_override_magic_resist") then
					spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_override_magic_resist", { duration = -1 })
				end
				if not spawnedUnit:HasModifier("modifier_spell_amp_from_int") then
					spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_spell_amp_from_int", { duration = -1 })
				end
			end
		elseif spawnedUnit:IsIllusion() or spawnedUnit:IsTempestDouble() or spawnedUnit:GetUnitLabel() == "spirit_bear" then
			-- иллюзии / Tempest Double / Spirit Bear наследуют статы героя
			if not spawnedUnit:HasModifier("modifier_override_magic_resist") then
				spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_override_magic_resist", { duration = -1 })
			end
			if not spawnedUnit:HasModifier("modifier_spell_amp_from_int") then
				spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_spell_amp_from_int", { duration = -1 })
			end

			-- stegius illusions: grant Desolating Touch passive (with main hero ability)
			-- so their hits reduce the ENEMY's armor on behalf of the hero.
			if spawnedUnit:IsIllusion() then
				local owner_pid = spawnedUnit:GetPlayerOwnerID()
				print("[STEGIUS] any illusion spawned: " .. tostring(spawnedName) .. " owner=" .. tostring(owner_pid))
				local main_hero = GetIllusionSource(spawnedUnit)
				local ability = main_hero and main_hero:FindAbilityByName("stegius_desolating_touch")
				if main_hero and ability then
					if not spawnedUnit:HasModifier("modifier_stegius_desolating_touch") then
						spawnedUnit:AddNewModifier(main_hero, ability, "modifier_stegius_desolating_touch", {})
						print("[STEGIUS] illusion got passive, hero=" .. tostring(main_hero:GetUnitName()))
					end
				else
					print("[STEGIUS] illusion hook: no hero/ability, main=" .. tostring(main_hero))
				end
			end
		end

		if GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME then
			if spawnedUnit and spawnedUnit:IsRealHero() then
				print("[STUN] Applying pregame stun to " .. spawnedName)
				spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_pregame_stunned", {duration = 5})
			end
		end
	end)
	if not ok then
		print("[DIAG] OnNPCSpawned error: " .. tostring(err))
	end
end
