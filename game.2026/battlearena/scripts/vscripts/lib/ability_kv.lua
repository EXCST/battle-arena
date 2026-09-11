-- ============================================================
-- BATTLE ARENA — AbilityKV
-- Чтение значений способностей напрямую из KV через GetAbilityKeyValues().
-- GetSpecialValueFor/GetLevelSpecialValueFor в текущем движке возвращают 0
-- даже при корректном KV (регрессия движкового вызова), поэтому читаем KV сами.
-- ============================================================

AbilityKV = AbilityKV or {}

--- Читает значение ключа из AbilityValues/AbilitySpecial блока способности.
--- Поддерживает три формата:
---   1) плоский:  "key" "value"
---   2) named:    "key" { "var_type" ... "value" "300 400 500" }
---   3) numbered: "01"  { "var_type" ... "key" "value" }   (классический формат проекта)
--- Per-level строки ("300 400 500") берутся по уровню способности.
function AbilityKV:Get(ability, key)
	if not ability or not IsValidEntity(ability) then return 0 end
	-- ⚠️ На клиентской VM метода GetAbilityKeyValues НЕТ (nil) — проперти-методы
	-- модификаторов (броня/урон/тултипы) вызываются и на клиенте; без guard
	-- падало «attempt to call method 'GetAbilityKeyValues' (a nil value)»
	-- → «error in error handling» ×N при спавне героя.
	if not ability.GetAbilityKeyValues then return 0 end

	local kv = ability:GetAbilityKeyValues()
	if not kv then return 0 end

	local specials = kv.AbilityValues or kv.AbilitySpecial
	if not specials then return 0 end

	-- прямое обращение по имени ключа: плоский формат и named-блоки
	local direct = specials[key]
	if direct ~= nil then
		if type(direct) == "table" then
			local value = direct.value
			if value ~= nil then
				return AbilityKV:ParseValue(value, ability)
			end
			-- named-блок с ключом внутри (редкий случай)
			value = direct[key]
			if value ~= nil then
				return AbilityKV:ParseValue(value, ability)
			end
			return 0
		end
		return AbilityKV:ParseValue(direct, ability)
	end

	-- numbered-блоки: "01" { "var_type" ... "key" "value" }
	for _, block in pairs(specials) do
		if type(block) == "table" then
			local value = block[key]

			if value ~= nil then
				return AbilityKV:ParseValue(value, ability)
			end
		end
	end

	return 0
end

--- Разбирает значение с per-level строками ("300 400 500" — берётся уровень способности).
function AbilityKV:ParseValue(value, ability)
	if type(value) == "number" then return value end

	if type(value) == "string" then
		local parts = {}

		for part in string.gmatch(value, "%S+") do
			parts[#parts + 1] = part
		end

		local index = math.min(ability:GetLevel() or 1, #parts)

		return tonumber(parts[index]) or tonumber(parts[#parts]) or 0
	end

	return 0
end
