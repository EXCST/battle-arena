modifier_possessed_leap = modifier_possessed_leap or class({})
local mod = modifier_possessed_leap

require('creeps/boss/possessed/possessed_helpers')


function mod:IsHidden() return true end
function mod:IsPurgable() return false end


function mod:OnCreated(kv)
	if not IsServer() then return end

	self.start_pos = self:GetParent():GetAbsOrigin()
	self.target_pos = Vector(tonumber(kv.target_x), tonumber(kv.target_y), tonumber(kv.target_z))
	self.duration = kv.duration or 0.7
	self.elapsed = 0

	if not self:ApplyHorizontalMotionController() then self:Destroy() return end
	if not self:ApplyVerticalMotionController() then self:Destroy() return end
end


function mod:UpdateHorizontalMotion(me, dt)
	if not IsServer() then return end

	self.elapsed = self.elapsed + dt

	local pct = math.min(1, self.elapsed / self.duration)
	local parent = self:GetParent()

	if not IsValidEntity(parent) then return end

	parent:SetAbsOrigin(self.start_pos + (self.target_pos - self.start_pos) * pct)

	if pct >= 1 then
		parent:InterruptMotionControllers(true)
		self:Destroy()
	end
end


function mod:UpdateVerticalMotion(me, dt)
	if not IsServer() then return end

	local parent = self:GetParent()

	if not IsValidEntity(parent) then return end

	local pct = math.min(1, self.elapsed / self.duration)
	local arc = 300 * 2 * pct * (1 - pct)
	local pos = parent:GetAbsOrigin()

	parent:SetAbsOrigin(Vector(pos.x, pos.y, pos.z + arc))
end


function mod:OnHorizontalMotionInterrupted()
	self:Destroy()
end


function mod:OnDestroy()
	if not IsServer() then return end

	local caster = self:GetParent()
	local ability = self:GetAbility()

	if not IsValidEntity(caster) or not IsValidEntity(ability) then return end

	caster:InterruptMotionControllers(true)

	local aoe = AbilityKV:Get(ability, "aoe")
	local stun = AbilityKV:Get(ability, "stun_duration")
	local pos = caster:GetAbsOrigin()

	local p = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_c.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(p, 0, pos)
	ParticleManager:SetParticleControl(p, 1, Vector(aoe, 0, 0))
	ParticleManager:ReleaseParticleIndex(p)

	local enemies = PossessedHelpers:FindEnemies(caster:GetTeamNumber(), pos, aoe)

	for _, enemy in pairs(enemies) do
		if IsValidEntity(enemy) then
			PossessedHelpers:DealDamage(ability, caster, enemy)
			PossessedHelpers:Stun(enemy, caster, ability, stun)
		end
	end

	EmitSoundOnLocationWithCaster(pos, "Boss_Possessed.DevilStomp.Cast", caster)
end
