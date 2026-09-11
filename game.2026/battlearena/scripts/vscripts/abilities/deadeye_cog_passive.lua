-- abilities/deadeye_cog_passive.lua
-- Интринзик когса «Гранёного крюка» Deadeye. Поведение как у оригинальных
-- Power Cogs Clockwerk: когс — турель (стреляет KV-атакой) и ПЛОХОЙ сосед:
--   • героя в PRISON_RADIUS от когса ДЕРЖИТ рут (stick-дек 0.6с, обновляется
--     тиком — «застрял, пока не сломаешь»; юниты в Dota физически не блокируют
--     heroes, поэтому «стена» сделана рутом);
--   • умирает ТОЛЬКО от 5 атак (HP пинится, заклинания не добивают):
--     каждый удар героя снимает стак; 0 → Kill (килл засчитан атакующему);
--   • пока жив: жжёт 5% ТЕКУЩЕЙ маны каждые 0.5с героям в DRAIN_RADIUS (=10%/с,
--     за 5с жизни до ~50%) (SetMana: ReduceMana в сборке сломан, паттерн travaler);
--   • LIFETIME — авто-despawn.
-- ⚠️ БЕЗ require('lib/timers'); Timers — глобал сервера.

LinkLuaModifier("modifier_deadeye_cog", "abilities/deadeye_cog_passive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_deadeye_cog_stick", "abilities/deadeye_cog_passive", LUA_MODIFIER_MOTION_NONE)

deadeye_cog_passive = deadeye_cog_passive or class({})

function deadeye_cog_passive:GetIntrinsicModifierName()
	return "modifier_deadeye_cog"
end

modifier_deadeye_cog = modifier_deadeye_cog or class({})

local HIT_STACKS = 5
local DRAIN_RADIUS = 300
local DRAIN_PCT_PER_SEC = 10
local PRISON_RADIUS = 260
local LIFETIME = 5
local TICK = 0.5
local STICK_DURATION = 0.6
local BURN_PFX = "particles/econ/items/antimage/antimage_weapon_basher_ti5/am_basher_manaburn_impact_lightning.vpcf"

function modifier_deadeye_cog:OnCreated()
	if not IsServer() then return end

	self._stacks = HIT_STACKS
	self._age = 0
	self:SetStackCount(HIT_STACKS)

	local parent = self:GetParent()
	parent:SetHealth(parent:GetMaxHealth())

	self:StartIntervalThink(TICK)
end

function modifier_deadeye_cog:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_deadeye_cog:OnAttackLanded(params)
	if not IsServer() then return end

	local parent = self:GetParent()
	if params.target ~= parent then return end
	if not IsValidEntity(parent) or not parent:IsAlive() then return end

	local attacker = params.attacker
	if not IsValidEntity(attacker) or attacker:IsOther() then return end

	self._stacks = self._stacks - 1
	self:SetStackCount(math.max(0, self._stacks))

	parent:EmitSound("Hero_Rattletrap.Battery_Assault_Impact")

	if self._stacks <= 0 then
		parent:Kill(nil, attacker)
		return
	end

	-- пиним HP: урон атаки может быть любым — решение только по стакам
	parent:SetHealth(parent:GetMaxHealth())
end

function modifier_deadeye_cog:OnIntervalThink()
	if not IsServer() then return end

	local parent = self:GetParent()
	if not IsValidEntity(parent) or not parent:IsAlive() then return end

	self._age = self._age + TICK
	if self._age >= LIFETIME then
		parent:RemoveSelf()
		return
	end

	local enemies = FindUnitsInRadius(
		parent:GetTeamNumber(),
		parent:GetAbsOrigin(),
		nil,
		DRAIN_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)

	local pos = parent:GetAbsOrigin()

	for _, hero in ipairs(enemies) do
		if IsValidEntity(hero) and hero:IsAlive() then
			-- ДЕРЖИМ героя у когса, пока тот не сломан (BKB режет — как в ваниле)
			local d = (hero:GetAbsOrigin() - pos):Length2D()
			if d <= PRISON_RADIUS then
				hero:AddNewModifier(parent, self:GetAbility(), "modifier_deadeye_cog_stick", { duration = STICK_DURATION })
			end

			if hero:GetMana() > 1 then
				hero:SetMana(math.max(0, hero:GetMana() - hero:GetMana() * DRAIN_PCT_PER_SEC * TICK / 100))

				local p = ParticleManager:CreateParticle(BURN_PFX, PATTACH_ABSORIGIN_FOLLOW, hero)
				ParticleManager:SetParticleControl(p, 0, hero:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(p)
			end
		end
	end
end

function modifier_deadeye_cog:IsHidden() return false end
function modifier_deadeye_cog:IsPurgable() return false end
function modifier_deadeye_cog:RemoveOnDeath() return false end

function modifier_deadeye_cog:GetTexture()
	return "rattletrap_battery_assault"
end

-- ─── «застревание»: короткий рут-дек, обновляется тиком когса ───

modifier_deadeye_cog_stick = modifier_deadeye_cog_stick or class({})

function modifier_deadeye_cog_stick:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
	}
end

function modifier_deadeye_cog_stick:IsDebuff() return true end
function modifier_deadeye_cog_stick:IsHidden() return true end
function modifier_deadeye_cog_stick:IsPurgable() return false end
function modifier_deadeye_cog_stick:RemoveOnDeath() return true end
