-- lib/duel_bosses/modifiers/modifier_duel_boss_summon_protect.lua
-- Защита призываемых юнитов при рождении:
-- инвулн + неуязвимость к таргету + рост модели из 0.18 → 1.

modifier_duel_boss_summon_protect = modifier_duel_boss_summon_protect or class({})

function modifier_duel_boss_summon_protect:OnCreated()
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.original_scale = self.parent:GetModelScale()
	self.parent:SetModelScale(self.original_scale * 0.18)
	self:StartIntervalThink(FrameTime())
end

function modifier_duel_boss_summon_protect:OnIntervalThink()
	if not IsServer() then return end
	if not self.parent or self.parent:IsNull() or not IsValidEntity(self.parent) then return end

	local remaining = self:GetRemainingTime()
	local total = self:GetDuration()
	if total <= 0 then return end

	local k = 1 - math.max(0, remaining / total)
	self.parent:SetModelScale(self.original_scale * (0.18 + 0.82 * k))
end

function modifier_duel_boss_summon_protect:OnDestroy()
	if not IsServer() then return end
	if self.parent and not self.parent:IsNull() and IsValidEntity(self.parent) then
		self.parent:SetModelScale(self.original_scale)
	end
end

function modifier_duel_boss_summon_protect:IsHidden()         return true  end
function modifier_duel_boss_summon_protect:IsPurgable()       return false end
function modifier_duel_boss_summon_protect:IsDebuff()          return false end
function modifier_duel_boss_summon_protect:DestroyOnExpire()  return true  end

function modifier_duel_boss_summon_protect:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE]           = true,
		[MODIFIER_STATE_UNSELECTABLE]           = true,
		[MODIFIER_STATE_NO_HEALTH_BAR]          = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION]      = true,
		[MODIFIER_STATE_ROOTED]                 = true,
		[MODIFIER_STATE_DISARMED]               = true,
	}
end