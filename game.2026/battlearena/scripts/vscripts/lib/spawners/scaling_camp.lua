ScalingCamp = ScalingCamp or class({})

LinkLuaModifier("modifier_scaling_camp_bear", 'lib/spawners/modifier_scaling_camp_bear', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scaling_camp_boss", 'lib/spawners/modifier_scaling_camp_boss', LUA_MODIFIER_MOTION_NONE)

require("lib/timers")

local DEFAULT_SPAWN = Vector(1439.32, 1939.85, 158.116)

local MODEL_SCALE_BASE = 0.40
local SPAWN_RADIUS = 120
local BOSS_INTERVAL = 50
local BOSS_COUNT = 1
local BOSS_HP_MULT = 15
local BOSS_DMG_MULT = 8
local BOSS_ARMOR = 40
local BOSS_GOLD_MULT = 15
local BOSS_XP_MULT = 10
local BOSS_MODEL = "models/customboss/elemental_curse_true_form/elemental_curse_set_elemental_curse_true_form.vmdl"

function ScalingCamp:Init()
	self.groups = {}
	self.bear_count = 3
	self.unit_name = "npc_aa_scaling_bear"
	local i = 1
	while true do
		local ent = Entities:FindByName(nil, "scaling_spawn_" .. i)
		if not ent then break end
		local group = {
			pos = ent:GetOrigin(),
			alive_bears = {},
			cycle = 0
		}
		table.insert(self.groups, group)
		i = i + 1
	end
	if #self.groups == 0 then
		local group = {
			pos = DEFAULT_SPAWN,
			alive_bears = {},
			cycle = 0
		}
		table.insert(self.groups, group)
		print("[ScalingCamp] no info_targets found, using default")
	end
	print("[ScalingCamp] found", #self.groups, "spawn point(s)")
	self.spawn_dir = Vector(1, 0, 0)

	PrecacheUnitByNameAsync(self.unit_name, function()
		PrecacheModel(BOSS_MODEL, function() end)
	end)
end

function ScalingCamp:StartSpawning()
	print("[ScalingCamp] StartSpawning, points:", #self.groups)
	for _, group in ipairs(self.groups) do
		self:_SpawnGroup(group)
	end
	Timers:CreateTimer(1.0, function() self:_CheckConverted(); return 1.0 end)
end

function ScalingCamp:OnBearDeath(unit)
	if not unit or unit:IsNull() then return end
	if unit:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then return end

	for _, group in ipairs(self.groups) do
		for i, bear in ipairs(group.alive_bears) do
			if bear == unit or (not bear:IsNull() and bear:GetEntityIndex() == unit:GetEntityIndex()) then
				table.remove(group.alive_bears, i)
				print("[ScalingCamp] Bear died at group, alive:", #group.alive_bears)
				if #group.alive_bears == 0 then
					Timers:CreateTimer(0.5, function()
						self:_SpawnGroup(group)
					end)
				end
				return
			end
		end
	end
end

function ScalingCamp:_SpawnGroup(group)
	group.cycle = group.cycle + 1
	print("[ScalingCamp] Spawning cycle", group.cycle)

	local is_boss = (group.cycle % BOSS_INTERVAL == 0)
	local count = is_boss and BOSS_COUNT or self.bear_count

	group.alive_bears = {}

	for i = 1, count do
		local pos = group.pos + Vector(
			RandomFloat(-SPAWN_RADIUS, SPAWN_RADIUS),
			RandomFloat(-SPAWN_RADIUS, SPAWN_RADIUS),
			0
		)

		local unit_name = is_boss and "npc_aa_scaling_boss" or self.unit_name
	local bear = CreateUnitByName(unit_name, pos, true, nil, nil, DOTA_TEAM_NEUTRALS)
		if bear then
			print("[ScalingCamp] Bear spawned ok idx", bear:GetEntityIndex())
			for i = 0, 15 do
				local ab = bear:GetAbilityByIndex(i)
				if ab and ab:GetLevel() == 0 then ab:SetLevel(1) end
			end
			FindClearSpaceForUnit(bear, bear:GetOrigin(), true)
			if self.spawn_dir then
				bear:SetForwardVector(self.spawn_dir)
			end
			bear:Stop()

		if is_boss then
			self:_ApplyBossScaling(bear, group.cycle)
		else
			self:_ApplyScaling(bear, group.cycle)
		end

			bear.is_scaling_bear = true
			table.insert(group.alive_bears, bear)
		else
			print("[ScalingCamp] FAILED to spawn bear at", group.pos)
		end
	end
end

function ScalingCamp:_ApplyScaling(bear, cycle)
	if not bear then return end

	local n = cycle - 1
	local hpFactor = (1.035) ^ n
	local statFactor = (1.015) ^ n

	local baseHp = 500
	local baseDmgMin = 32
	local baseDmgMax = 37
	local baseArmor = 3
	local baseBat = 1.5
	local baseGoldMin = 35
	local baseGoldMax = 40
	local baseXp = 67

	local hp = math.floor(baseHp * hpFactor)
	local dmgMin = math.floor(baseDmgMin * statFactor)
	local dmgMax = math.floor(baseDmgMax * statFactor)
	local armor = math.floor(baseArmor * statFactor * 10) / 10
	local bat = baseBat / statFactor
	local aspeed = math.floor((statFactor - 1) * 100)
	local goldMin = math.floor(baseGoldMin * hpFactor)
	local goldMax = math.floor(baseGoldMax * hpFactor)
	local xp = math.floor(baseXp * hpFactor)

	bear:SetBaseMaxHealth(hp)
	bear:SetMaxHealth(hp)
	bear:SetHealth(hp)
	bear:SetBaseDamageMin(dmgMin)
	bear:SetBaseDamageMax(dmgMax)
	bear:SetPhysicalArmorBaseValue(armor)
	bear:SetMinimumGoldBounty(goldMin)
	bear:SetMaximumGoldBounty(goldMax)
	bear:SetDeathXP(0)

	bear.scaling_xp = xp
	bear.bear_spawn_cycle = cycle
	bear.bear_bat = bat

	bear:SetCustomHealthLabel("lvl " .. cycle, 255, 200, 0)
	bear.bear_aspeed_bonus = aspeed

	local modelScale = MODEL_SCALE_BASE + math.floor(n / 5) * 0.1
	bear:SetModelScale(modelScale)
end

function ScalingCamp:_ApplyBossScaling(bear, cycle)
	if not bear then return end

	self:_ApplyScaling(bear, cycle)

	local n = cycle - 1
	local hpFactor = (1.035) ^ n
	local statFactor = (1.015) ^ n

	local hp = math.floor(500 * hpFactor * BOSS_HP_MULT)
	local dmgMin = math.floor(32 * statFactor * BOSS_DMG_MULT)
	local dmgMax = math.floor(37 * statFactor * BOSS_DMG_MULT)
	local goldMin = math.floor(35 * hpFactor * BOSS_GOLD_MULT)
	local goldMax = math.floor(40 * hpFactor * BOSS_GOLD_MULT)
	local xp = math.floor(67 * hpFactor * BOSS_XP_MULT)

	bear:SetBaseMaxHealth(hp)
	bear:SetMaxHealth(hp)
	bear:SetHealth(hp)
	bear:SetBaseDamageMin(dmgMin)
	bear:SetBaseDamageMax(dmgMax)
	bear:SetMinimumGoldBounty(goldMin)
	bear:SetMaximumGoldBounty(goldMax)
	bear.scaling_xp = xp

	bear:SetCustomHealthLabel("BOSS lvl " .. cycle, 255, 50, 50)
	bear:SetModel(BOSS_MODEL)
	bear:SetOriginalModel(BOSS_MODEL)
	bear:SetModelScale(2.0)
	bear:SetPhysicalArmorBaseValue(BOSS_ARMOR)


end

function ScalingCamp:_CheckConverted()
	for _, group in ipairs(self.groups) do
		local removed = false
		for i = #group.alive_bears, 1, -1 do
			local bear = group.alive_bears[i]
			if bear:IsNull() or bear:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
				table.remove(group.alive_bears, i)
				removed = true
			end
		end
		if removed and #group.alive_bears == 0 then
			self:_SpawnGroup(group)
		end
	end
end

function ScalingCamp:IsScalingBear(unit)
	if not unit or unit:IsNull() then return false end
	return unit.is_scaling_bear
end

function ScalingCamp:GetSoloXP(unit)
	if not unit or unit:IsNull() then return 0 end
	local xp = unit:GetDeathXP()
	if xp and xp > 0 then
		return xp
	end
	return 0
end