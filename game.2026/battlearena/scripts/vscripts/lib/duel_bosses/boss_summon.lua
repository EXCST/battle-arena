-- lib/duel_bosses/boss_summon.lua
-- Призывы дуэльных боссов: создание юнита с тегом-лимитом (пул живых
-- призывов на боссе), защитой при рождении и опцией «беги на игрока».

require('lib/duel_bosses/boss_aim')
require('lib/duel_bosses/modifiers/modifier_duel_boss_summon_protect')
-- ⚠️ БЕЗ require('lib/timers') — клиентская VM падает (см. AGENTS.md)

DuelBossSummon = DuelBossSummon or {}

-- unit — кастер (босс), ability — способность-источник.
-- unitName — имя KV-юнита призыва. tag — ключ пула (лимит живых).
-- opts: protect (сек защиты), scale (модель-скейл), chase (бежать к ближайшему игроку)
function DuelBossSummon:Create(unit, ability, unitName, pos, tag, maxSummons, opts)
	opts = opts or {}

	if not IsValidEntity(unit) or not unit:IsAlive() then return nil end

	local pool = unit.duel_summon_pool or {}
	unit.duel_summon_pool = pool

	local key = tag or unitName
	local list = pool[key] or {}

	-- чистим мёртвых
	local alive = 0
	for _, s in ipairs(list) do
		if IsValidEntity(s) and not s:IsNull() and s:IsAlive() then
			alive = alive + 1
		end
	end
	if alive >= (maxSummons or 99) then
		return nil
	end

	local summon = CreateUnitByName(unitName, pos, true, nil, nil, unit:GetTeamNumber())
	if not summon then
		print("[DuelBossSummon] failed to spawn", unitName)
		return nil
	end

	print("[SUMMON] created", unitName)

	FindClearSpaceForUnit(summon, pos, true)
	summon:Stop()

	summon.duel_summon_tag = key
	summon.duel_summon_owner = unit

	-- регистрация в пуле
	list = {}
	for _, s in ipairs(pool[key] or {}) do
		if IsValidEntity(s) and not s:IsNull() and s:IsAlive() then
			list[#list + 1] = s
		end
	end
	list[#list + 1] = summon
	pool[key] = list

	-- уровень способностей призыва (конвенция проекта: SetLevel(1))
	for i = 0, 15 do
		local ab = summon:GetAbilityByIndex(i)
		if ab and ab:GetLevel() == 0 then ab:SetLevel(1) end
	end

	if opts.protect and opts.protect > 0 then
		summon:AddNewModifier(unit, ability, "modifier_duel_boss_summon_protect", { duration = opts.protect })
	end

	if opts.scale then
		summon:SetModelScale(opts.scale)
	end

	if opts.chase then
		local target = DuelBossAim:GetNearestEnemy(summon, 3000, summon:GetAbsOrigin())
		if target then
			summon:MoveToTargetToAttack(target)
		end
	end

	return summon
end

-- Убить всех живых призывов босса по тегу (напр. при окончании дуэли).
function DuelBossSummon:KillTag(unit, tag)
	if not IsValidEntity(unit) then return end
	local list = (unit.duel_summon_pool or {})[tag]
	if not list then return end

	for _, s in ipairs(list) do
		if IsValidEntity(s) and not s:IsNull() and s:IsAlive() then
			s:ForceKill(false)
		end
	end
end

-- Убить ВСЕ призывы босса (все теги). Вызывается при смерти/финале дуэли,
-- чтобы минеры/гончие не добивали героев после кила босса.
function DuelBossSummon:KillAll(unit)
	if not IsValidEntity(unit) then return end
	for tag, list in pairs(unit.duel_summon_pool or {}) do
		for _, s in ipairs(list) do
			if IsValidEntity(s) and not s:IsNull() and s:IsAlive() then
				s:ForceKill(false)
			end
		end
	end
end