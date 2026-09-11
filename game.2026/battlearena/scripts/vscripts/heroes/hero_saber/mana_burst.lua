require('lib/ability_kv')

-- ⚠️ Значения KV, захардкоженные для КЛИЕНТА: на клиентской VM нет
-- GetAbilityKeyValues() (AbilityKV:Get возвращает 0), поэтому клиентские
-- проперти-методы читают эти таблицы по уровню способности.
-- Держать синхронно с AbilityValues в hero_saber.txt!
local CLIENT_DAMAGE_PER_MANA = { 0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07 }
local CLIENT_ARMOR_PER_MANA = { 0.01, 0.015, 0.02, 0.025, 0.03, 0.035, 0.04 }
local CLIENT_WEAKNESS_DISARMOR = { -5, -8, -11, -14, -17, -20, -23 }
local CLIENT_MANA_WASTED_PCT = 30

local function getLevel(ability)
	if not ability or not IsValidEntity(ability) then return 1 end
	return math.max(1, ability:GetLevel() or 1)
end

local function perLevel(tbl, ability)
	local lvl = getLevel(ability)
	return tbl[math.min(lvl, #tbl)] or 0
end


saber_mana_burst = class({
	GetIntrinsicModifierName = function() return "modifier_saber_mana_burst" end,
})

function saber_mana_burst:GetManaCost(iLevel)
	local caster = self:GetCaster()
	if not caster or caster:IsNull() then return 0 end
	local pct = CLIENT_MANA_WASTED_PCT
	if IsServer() then
		pct = AbilityKV:Get(self, "mana_wasted_pct")
	end
	if not pct or pct <= 0 then pct = CLIENT_MANA_WASTED_PCT end
	return caster:GetMaxMana() * pct * 0.01
end

if IsServer() then
	function saber_mana_burst:OnSpellStart()
		local caster = self:GetCaster()
		caster:EmitSound("Arena.Hero_Saber.ManaBurst")
		local d = AbilityKV:Get(self, "duration")
		if not d or d <= 0 then d = 5 end
		local mod = caster:AddNewModifier(caster, self, "modifier_saber_mana_burst_active", {duration = d})
		if mod then
			mod:SetStackCount(self:GetManaCost())
		end
		ParticleManager:CreateParticle("particles/econ/items/outworld_devourer/od_shards_exile/od_shards_exile_prison_end_mana_flash.vpcf", PATTACH_ABSORIGIN, caster)
		local pct = caster:GetHealthPercent()
		if pct <= AbilityKV:Get(self, "purge_health_pct") then
			local purgeStuns = pct <= AbilityKV:Get(self, "purge_stun_health_pct")
			caster:Purge(false, true, false, purgeStuns, false)
		end
	end
end


modifier_saber_mana_burst = class({
	IsHidden         = function() return true end,
	DeclareFunctions = function() return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS} end,
	IsPurgable       = function() return false end
})

function modifier_saber_mana_burst:CheckState()
	if self:GetStackCount() == 1 then
		return { [MODIFIER_STATE_DISARMED] = true }
	end
	return {}
end

function modifier_saber_mana_burst:GetModifierPhysicalArmorBonus()
	if self:GetStackCount() ~= 1 then return 0 end
	if IsServer() then
		return AbilityKV:Get(self:GetAbility(), "weakness_disarmor")
	end
	return perLevel(CLIENT_WEAKNESS_DISARMOR, self:GetAbility())
end

if IsServer() then
	function modifier_saber_mana_burst:OnCreated()
		self:StartIntervalThink(0.1)
	end

	function modifier_saber_mana_burst:OnIntervalThink()
		local parent = self:GetParent()
		if parent:IsAlive() then
			local ability = self:GetAbility()
			local manacost = 0
			if ability and IsValidEntity(ability) then
				manacost = ability:GetManaCost()
			end
			local isWeak = (parent:GetMana() / parent:GetMaxMana()) * 100 < AbilityKV:Get(ability, "weakness_mana_pct")
			self:SetStackCount(isWeak and 1 or 0)
			if isWeak and not self.pfx then
				self.pfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_disarm.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
			elseif not isWeak and self.pfx then
				ParticleManager:DestroyParticle(self.pfx, false)
				self.pfx = nil
			end
			if ability and IsValidEntity(ability) and ability:GetAutoCastState() and manacost * 2 < parent:GetMana() then
				parent:CastAbilityNoTarget(ability, parent:GetPlayerID())
			end
		end
	end
end

modifier_saber_mana_burst_active = class({
	IsPurgable    = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
})
function modifier_saber_mana_burst_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
end

function modifier_saber_mana_burst_active:GetModifierPreAttack_BonusDamage()
	local stacks = self:GetStackCount()
	if stacks <= 0 then return 0 end
	if IsServer() then
		return stacks * AbilityKV:Get(self:GetAbility(), "damage_per_mana")
	end
	return stacks * perLevel(CLIENT_DAMAGE_PER_MANA, self:GetAbility())
end
function modifier_saber_mana_burst_active:GetModifierPhysicalArmorBonus()
	local stacks = self:GetStackCount()
	if stacks <= 0 then return 0 end
	if IsServer() then
		return stacks * AbilityKV:Get(self:GetAbility(), "armor_per_mana")
	end
	return stacks * perLevel(CLIENT_ARMOR_PER_MANA, self:GetAbility())
end
if IsServer() then
	function modifier_saber_mana_burst_active:OnCreated()
		local parent = self:GetParent()
		self.pfx = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_saber/mana_burst_stack.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControlEnt(self.pfx, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
	end
	function modifier_saber_mana_burst_active:OnDestroy()
		ParticleManager:DestroyParticle(self.pfx, false)
	end
end
