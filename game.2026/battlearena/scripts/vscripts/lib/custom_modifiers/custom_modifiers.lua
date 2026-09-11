CustomModifiers = CustomModifiers or class({})

-- Steam ID3 table
local modTable = {
	-- leha
	[112315140] = "modifier_tester",

	-- homyak
	[136098003] = "modifier_dcp_tester",

	-- Banned
	[284066040] 	= "modifier_banned_custom",
	[229856102] 	= "modifier_banned_custom",
	[114152435] 	= "modifier_banned_custom",
	[339595187] 	= "modifier_banned_custom",
	[254249264] 	= "modifier_banned_custom",
	[262065464] 	= "modifier_banned_custom",
	[119682577] 	= "modifier_banned_custom",
	[187357138] 	= "modifier_banned_custom",
}

LinkLuaModifier("modifier_tester", 			'lib/custom_modifiers/modifiers/modifier_tester', 			LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dcp_tester", 		'lib/custom_modifiers/modifiers/modifier_dcp_tester', 		LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_banned_custom", 	'lib/custom_modifiers/modifiers/modifier_banned_custom', 	LUA_MODIFIER_MOTION_NONE)

function CustomModifiers:OnHeroSpawn(hero)
	if not hero then return end

	local steam_id = PlayerResource:GetSteamAccountID( hero:GetPlayerOwnerID() )

	local modName = modTable[steam_id]

	if not modName then return end

	hero:AddNewModifier(hero, nil, modName, { duration = -1 })
end
