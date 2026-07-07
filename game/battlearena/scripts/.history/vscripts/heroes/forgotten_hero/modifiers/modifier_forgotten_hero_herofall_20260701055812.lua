modifier_forgotten_hero_herofall = modifier_forgotten_hero_herofall or class({})
local mod = modifier_forgotten_hero_herofall

function mod:IsHidden() 	 	return false end
function mod:RemoveOnDeath() 	return true  end
function mod:IsDebuff() 	 	return false end
function mod:IsPurgable() 	 	return false end
function mod:DestroyOnExpire()  return true  end
function mod:IsPurgeException() return true  end

function mod:OnCreated( kv )
	if not IsServer() then return end

	print("[HEROFALL] OnCreated started")

	local parent  = self:GetParent()
	local ability = self:GetAbility()

	if not parent then
		print("[HEROFALL] ERROR: parent is nil!")
		self:Destroy()
		return
	end

	if not ability then
		print("[HEROFALL] ERROR: ability is nil!")
		self:Destroy()
		return
	end

	self.basePos = parent:GetAbsOrigin()
	
	self.height  = ability:GetSpecialValueFor("height") 
	self.speed   = ability:GetSpecialValueFor("speed")
	self.damage  = ability:GetSpecialValueFor("damage")
	self.stunDur = ability:GetSpecialValueFor("stun_duration")

	self.aoe      = ability:GetAOERadius()
	self.aoeTeam  = ability:GetAbilityTargetTeam()
	self.aoeType  = ability:GetAbilityTargetType()
	self.aoeFlags = ability:GetAbilityTargetFlags()
	self.dmgType  = ability:GetAbilityDamageType()

	self.pos     = Vector(kv.px, kv.py, kv.pz)

	self.val 	 = 0

	print("[HEROFALL] basePos:", self.basePos, "targetPos:", self.pos, "distance:", (self.basePos - self.pos):Length())

	if (self.basePos - self.pos):Length() < 50 then
		print("[HEROFALL] Distance too short, destroying")
		self:Destroy()
		return
	end

	local horizResult = self:ApplyHorizontalMotionController()
	local vertResult = self:ApplyVerticalMotionController()

	print("[HEROFALL] Motion controllers applied - Horizontal:", horizResult, "Vertical:", vertResult)

	if horizResult == false or vertResult == false then 
		print("[HEROFALL] ERROR: Failed to apply motion controllers!")
		self:Destroy()
	end
end

function mod:OnDestroy()
	if not IsServer() then return end

	print("[HEROFALL] OnDestroy called")

	local parent = self:GetParent()

	if not parent or parent:IsNull() then
		print("[HEROFALL] ERROR: parent is nil/null in OnDestroy!")
		return
	end

	parent:InterruptMotionControllers(true)

	ParticleManager:CreateParticle("particles/econ/items/monkey_king/arcana/fire/monkey_king_spring_arcana_fire.vpcf", PATTACH_ABSORIGIN, parent)

	parent:StopSound("Hero_ForgottenHero.Herofall.Cast")
	parent:EmitSound("Hero_ForgottenHero.Herofall.Hit")

	local ability = self:GetAbility()

	if not ability then
		print("[HEROFALL] ERROR: ability is nil in OnDestroy!")
		return
	end

	local pos = parent:GetAbsOrigin()
	local radius = self.aoe

	print("[HEROFALL] Landing at:", pos, "radius:", radius)

	local units = FindUnitsInRadius( parent:GetTeamNumber(),
									 pos,
									 parent,
									 radius,
									 self.aoeTeam,
									 self.aoeType,
									 self.aoeFlags,
									 FIND_ANY_ORDER,
									 false )

	print("[HEROFALL] Found", #units, "units in AoE")

	GridNav:DestroyTreesAroundPoint(pos, radius, true)

	for _, unit in pairs(units) do
		unit:AddNewModifier(parent, ability, "modifier_forgotten_hero_herofall_debuff", { duration = self.stunDur })

		ApplyDamage({
			victim 		= unit,
			attacker 	= parent,
			damage 		= self.damage,
			damage_type = self.dmgType,
			ability 	= ability,
		})

		if parent:HasTalent("forgotten_hero_talent_herofall_attack") then
			parent:PerformAttack(unit, true, true, true, true, false, false, false)
		end

	end
end

local function lerp(a, b, t)
	return a + t * (b - a)
end

function mod:UpdateHorizontalMotion( parent, dt )
	if not IsServer() then return end
	if not self then return end
	if self:IsNull() then return end
	if not self:GetAbility() then return end

	if not parent then return end
	if parent:IsNull() then return end

	if not parent:IsAlive() then
		print("[HEROFALL] Parent died during jump, destroying")
		parent:InterruptMotionControllers(true)
		self:Destroy()
		return
	end

	local basePos = self.basePos
	local pos = self.pos

	local totalLen = (basePos - pos):Length()

	local newLen = math.min(self.val + self.speed * dt, totalLen)

	self.val = newLen

	local relVal = newLen / totalLen

	local newHeight = self.height * math.sin( relVal * math.pi )

	local newPos = lerp( basePos, pos, relVal ) + Vector(0, 0, newHeight)

	parent:SetAbsOrigin(newPos)

	if newLen >= totalLen then
		print("[HEROFALL] Jump completed, landing")
		parent:InterruptMotionControllers(true)
		self:Destroy()
	end
end

function mod:UpdateVerticalMotion( parent, dt )
	-- Vertical motion is handled inside UpdateHorizontalMotion
	-- This prevents double-processing and potential desync
end

function mod:OnHorizontalMotionInterrupted()
	if not IsServer() then return end
	if not self or self:IsNull() then return end

	print("[HEROFALL] Horizontal motion interrupted, destroying")
	self:Destroy()
end

function mod:OnVerticalMotionInterrupted()
	if not IsServer() then return end
	if not self or self:IsNull() then return end

	print("[HEROFALL] Vertical motion interrupted, destroying")
	self:Destroy()
end

function mod:DeclareFunctions() return 
{ 
	MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
} 
end

function mod:GetOverrideAnimation( params )
	return ACT_DOTA_MK_SPRING_SOAR
end

function mod:GetEffectName()
	return "particles/econ/items/monkey_king/arcana/fire/mk_arcana_spring_jump_trail.vpcf"
end

function mod:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end