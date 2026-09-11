huntress_curse_arrow = huntress_curse_arrow or class({})
local debuffModifier = "modifier_huntress_curse_arrow"
LinkLuaModifier(debuffModifier, "heroes/huntress/huntress_curse_arrow/" .. debuffModifier, LUA_MODIFIER_MOTION_NONE)

function huntress_curse_arrow:OnSpellStart()
	if not IsServer() then return end
	self.target = self:GetCursorTarget()
	if not self.target or self.target:IsNull() or not self.target:IsAlive() then return end
	if self.target:TriggerSpellAbsorb(self) or self.target:TriggerSpellReflect(self) then return end

	self.channelTime = 0
	self.min_duration = self:GetSpecialValueFor("min_duration")
	self.max_duration = self:GetSpecialValueFor("max_duration")

	self.target:Purge(true, false, false, false, false)
end

function huntress_curse_arrow:OnChannelThink(intervalTime)
	self.channelTime = self.channelTime + intervalTime
end

function huntress_curse_arrow:OnChannelFinish(bInterrupted)
	if bInterrupted or not self.target or self.target:IsNull() or not self.target:IsAlive() then return end
	local caster = self:GetCaster()
	if not caster or caster:IsNull() then return end

	local channelTime = self:GetChannelTime()
	if not channelTime or channelTime == 0 then channelTime = 2.0 end
	local duration = self.channelTime / channelTime * (self.max_duration - self.min_duration) + self.min_duration

	self.target:AddNewModifier(caster, self, debuffModifier, { duration = duration })
end
