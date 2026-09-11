-- Minimal CDOTA_BaseNPC extensions required by the upgrades system.
-- (ported from Angel Arena Frontier, web/api-independent parts only)

function CDOTA_BaseNPC:HasShard()
	return self:HasModifier("modifier_item_aghanims_shard")
end


function CDOTA_BaseNPC:GetClones()
	if self:GetUnitName() ~= "npc_dota_hero_meepo" then return {} end

	local clones = {}

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsClone() and hero:GetCloneSource() == self then
			table.insert(clones, hero)
		end
	end

	return clones
end


function CDOTA_BaseNPC:IsSpiritBear()
	return self:GetUnitLabel() == "spirit_bear"
end


function CDOTA_BaseNPC:IsMonkeyKingSoldier()
	return self:HasModifier("modifier_monkey_king_fur_army_soldier") or self:HasModifier("modifier_monkey_king_fur_army_soldier_hidden")
end


function CDOTA_BaseNPC:IsMonkeyClone()
	return (self:HasModifier("modifier_monkey_king_fur_army_soldier") or self:HasModifier("modifier_wukongs_command_warrior"))
end


function CDOTA_BaseNPC:IsMainHero()
	return
	self and (not self:IsNull()) and self:IsRealHero() and not self:IsTempestDouble()
			and not self:IsMonkeyClone() and not self:IsClone() and not self:IsSpiritBear()
end


--- Returns the main hero that spawned this illusion/summon.
--- Принимает СУЩНОСТЬ (рекомендуется) или имя юнита (строка) — строка-вариант
--- добавлен, чтобы старые вызовы с GetUnitName() не роняли обработчики.
function GetIllusionSource(illusion)
	local unit_name = illusion
	if type(illusion) ~= "string" then
		if not IsValidEntity(illusion) then return nil end
		unit_name = illusion:GetUnitName()
	end

	for player_id = 0, DOTA_MAX_PLAYERS do
		if PlayerResource:IsValidPlayerID(player_id) then
			local hero = PlayerResource:GetSelectedHeroEntity(player_id)
			if IsValidEntity(hero) and hero:GetUnitName() == unit_name then
				return hero
			end
		end
	end

	return nil
end


--- Safe player id check (negative ids for AI/neutrals are invalid).
function IsValidPlayerID(player_id)
	return player_id ~= nil
		and type(player_id) == "number"
		and player_id >= 0
		and player_id < DOTA_MAX_PLAYERS
		and PlayerResource:IsValidPlayerID(player_id)
end


require('lib/ability_kv')

--- Boss check (flag is set by BossSpawner on spawned bosses).
function CDOTA_BaseNPC:IsBoss()
	return self.IsAngelArenaBoss == true
end


-- Max-health reduction helpers (Brightness of Desolate aura, ported from angel-arena-black-star).
-- pct кэшируется в OnCreated дебаффа (поле health_decrease_pct), фолбэк — AbilityKV.
function CDOTA_BaseNPC_Hero:GetTotalHealthReduction()
	local pct = 0
	local mod = self:FindModifierByName("modifier_stegius_brightness_of_desolate_effect")
	if mod then
		if mod.health_decrease_pct then
			pct = pct + mod.health_decrease_pct
		else
			pct = pct + AbilityKV:Get(mod:GetAbility(), "health_decrease_pct")
		end
	end
	return pct
end

function CDOTA_BaseNPC_Hero:CalculateHealthReduction()
	self:CalculateStatBonus(true)
	local pct = self:GetTotalHealthReduction()
	self:SetMaxHealth(pct >= 100 and 1 or self:GetMaxHealth() - pct * (self:GetMaxHealth()/100))
end
