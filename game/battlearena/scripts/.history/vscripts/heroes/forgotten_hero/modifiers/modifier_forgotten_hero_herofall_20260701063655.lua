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
	if not self.basePos then
		self.basePos = Vector(0,0,0)
		print("[HEROFALL] WARNING: parent:GetAbsOrigin() returned nil! Using zero vector.")
	end
	
	self.height  = ability:GetLevelSpecialValueFor("height", ability:GetLevel()-1) 
	self.speed   = ability:GetLevelSpecialValueFor("speed", ability:GetLevel()-1)
	self.damage  = ability:GetLevelSpecialValueFor("damage", ability:GetLevel()-1)
	self.stunDur = ability:GetLevelSpecialValueFor("stun_duration", ability:GetLevel()-1)

	print("[HEROFALL] Special values - height:", self.height, "speed:", self.speed, "damage:", self.damage, "stunDur:", self.stunDur)
	print("[HEROFALL] Ability level:", ability:GetLevel())

	self.aoe      = ability:GetAOERadius() 
	self.aoeTeam  = ability:GetAbilityTargetTeam() 
	self.aoeType  = ability:GetAbilityTargetType() 
	self.aoeFlags = ability:GetAbilityTargetFlags() 
	self.dmgType  = ability:GetAbilityDamageType() 

	print("[HEROFALL] Derived values - aoe:", self.aoe, "aoeTeam:", self.aoeTeam, "aoeType:", self.aoeType, "aoeFlags:", self.aoeFlags, "dmgType:", self.dmgType)

	self.pos     = Vector(kv.px or 0, kv.py or 0, kv.pz or 0)
	if not self.pos then
		self.pos = Vector(0,0,0)
		print("[HEROFALL] WARNING: kv.px, kv.py, kv.pz are all nil! Using zero vector.")
	end

	if kv.px == nil or kv.py == nil or kv.pz == nil then
		print("[HEROFALL] INFO: kv.px, kv.py, kv.pz are nil! Using zero vector.")
	end

	-- Safety check: if either vector is nil, we cannot compute distance safely.
	if not self.basePos or not self.pos then
		print("[HEROFALL] ERROR: basePos or pos is nil! Destroying modifier.")
		self:Destroy()
		return
	end

	local distance = (self.basePos - self.pos):Length()
	print("[HEROFALL] basePos:", self.basePos, "targetPos:", self.pos, "distance:", distance)

	if distance < 50 then
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

	print("[HEROFALL] UpdateMotion - val:", self.val, "speed:", self.speed, "dt:", dt, "totalLen:", totalLen)

	local newLen = math.min(self.val + self.speed * dt, totalLen)

	self.val = newLen

	local relVal = newLen / totalLen

	print("[HEROFALL] UpdateMotion - newLen:", newLen, "relVal:", relVal, "height:", self.height, "newHeight:", self.height * math.sin(relVal * math.pi))

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