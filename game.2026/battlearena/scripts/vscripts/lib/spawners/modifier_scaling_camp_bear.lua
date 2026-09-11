modifier_scaling_camp_bear = class({})
local mod = modifier_scaling_camp_bear

local PURE_PCT = 0.50

function mod:IsHidden()         return false end
function mod:IsPurgable()       return false end
function mod:DestroyOnExpire()  return true end
function mod:IsPurgeException() return false end
function mod:GetTexture()       return "elder_titan_natural_order" end

function mod:OnTooltip()
    return "50% Pure DMG per attack"
end

function mod:OnCreated(kv)
	if not IsServer() then return end
	local parent = self:GetParent()
	if not parent then return end
	local ok, err = pcall(function()
		self:SetStackCount(parent.bear_spawn_cycle or 0)
		parent:SetRenderColor(255, 255, 255)
		local okp, p = pcall(ParticleManager.CreateParticle, ParticleManager, "particles/units/heroes/hero_elder_titan/elder_titan_natural_order_physical.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		if okp and p then
			self.particle = p
		end
		self:StartIntervalThink(0.5)
	end)
	if not ok then
		print("[SCALING-BEAR] OnCreated ERR: " .. tostring(err))
	end
end
function mod:OnIntervalThink()
	local p = self:GetParent()
	if not p or p:IsNull() then return end
	self:SetStackCount(p.bear_spawn_cycle or 0)
	if p:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
		p:SetTeam(DOTA_TEAM_NEUTRALS)
	end
end

function mod:OnDestroy()
	if not IsServer() then return end
	if self.particle then
		ParticleManager:DestroyParticle(self.particle, false)
		self.particle = nil
	end
	local parent = self:GetParent()
	if parent and not parent:IsNull() then
		parent:SetRenderColor(255, 255, 255)
	end
end

function mod:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_BASEDATTACKTIME,
	}
end

function mod:OnDeath(kv)
	if not IsServer() then return end
	local parent = self:GetParent()
	if kv.unit ~= parent then return end
	if ScalingCamp then
		ScalingCamp:OnBearDeath(parent)
	end
end

function mod:OnAttackLanded(kv)
	if not IsServer() then return end
	if kv.attacker ~= self:GetParent() then return end
	if not kv.target or kv.target:IsNull() or not kv.target:IsAlive() then return end
	if kv.damage <= 0 then return end

	local pureDmg = kv.damage * PURE_PCT
	ApplyDamage({
		victim = kv.target,
		attacker = self:GetParent(),
		damage = pureDmg,
		damage_type = DAMAGE_TYPE_PURE,
		damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
	})
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, kv.target, pureDmg, nil)
end

function mod:GetModifierAttackSpeedBonus_Constant()
	if not IsServer() then return 0 end
	local parent = self:GetParent()
	if parent and parent.bear_aspeed_bonus then
		return parent.bear_aspeed_bonus
	end
	return 0
end

function mod:GetModifierBaseAttackTime()
	if not IsServer() then return end
	local parent = self:GetParent()
	if parent and parent.bear_bat then
		return parent.bear_bat
	end
	return
end
