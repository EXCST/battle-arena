require('lib/ability_kv')

LinkLuaModifier("modifier_pet_wolf_vampire_aura", "creeps/pet_wolf_vampire", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pet_wolf_vampire", "creeps/pet_wolf_vampire", LUA_MODIFIER_MOTION_NONE)

pet_ancient_wolf_vampire = pet_ancient_wolf_vampire or class({})

function pet_ancient_wolf_vampire:GetIntrinsicModifierName()
	return "modifier_pet_wolf_vampire_aura"
end

local function GetLifestealPct(modifier)
	local v = AbilityKV:Get(modifier:GetAbility(), "lifesteal")
	if not v or v <= 0 then v = 10 end
	return v
end

local function TryLifesteal(modifier, params)
	if not IsServer() then return end
	local parent = modifier:GetParent()
	if not parent or parent:IsNull() or not parent:IsAlive() then return end
	if params.attacker ~= parent then return end

	local target = params.target
	if not target or target:IsNull() then return end

	local pct = GetLifestealPct(modifier)
	local damage = params.damage or 0
	if damage <= 0 then return end

	local heal = damage * pct / 100
	local source = modifier:GetAbility() or parent
	parent:Heal(heal, source)
end

modifier_pet_wolf_vampire_aura = modifier_pet_wolf_vampire_aura or class({})

function modifier_pet_wolf_vampire_aura:IsHidden() return true end
function modifier_pet_wolf_vampire_aura:IsPurgable() return false end

function modifier_pet_wolf_vampire_aura:IsAura() return true end
function modifier_pet_wolf_vampire_aura:GetModifierAura() return "modifier_pet_wolf_vampire" end
function modifier_pet_wolf_vampire_aura:GetAuraRadius() return 900 end
function modifier_pet_wolf_vampire_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_pet_wolf_vampire_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end

function modifier_pet_wolf_vampire_aura:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_pet_wolf_vampire_aura:OnAttackLanded(params)
	local ok, err = xpcall(function() TryLifesteal(self, params) end, function(e) return tostring(e) end)
	if not ok then
		print("[WOLF] aura OnAttackLanded error: " .. tostring(err))
	end
end

modifier_pet_wolf_vampire = modifier_pet_wolf_vampire or class({})

function modifier_pet_wolf_vampire:IsHidden() return false end
function modifier_pet_wolf_vampire:IsPurgable() return false end

function modifier_pet_wolf_vampire:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_pet_wolf_vampire:OnAttackLanded(params)
	local caster = self:GetCaster()
	if caster and params.attacker == caster then return end
	local ok, err = xpcall(function() TryLifesteal(self, params) end, function(e) return tostring(e) end)
	if not ok then
		print("[WOLF] child OnAttackLanded error: " .. tostring(err))
	end
end
