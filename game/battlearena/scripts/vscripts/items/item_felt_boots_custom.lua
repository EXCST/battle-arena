require('items/generic_datadriven_item')


item_felt_boots_custom = class({
	GetIntrinsicModifierName = function() return "modifier_item_felt_boots_custom" end
})

function item_felt_boots_custom:OnToggle()
	local caster = self:GetCaster()
	if not IsValidEntity(caster.penguin) then
		local fw = self:GetCaster():GetForwardVector()
		caster.penguin = CreateUnitByName("npc_dota_sled_penguin", self:GetCaster():GetAbsOrigin(), false, nil, nil, self:GetCaster():GetTeam())
		caster.penguin:AddNewModifier(caster.penguin, self, "modifier_sled_penguin_passive", nil)
		caster.penguin:SetForwardVector(self:GetCaster():GetForwardVector())
		Timers:CreateTimer(0.01, function()
			-- 7.31 cause crash if something is null
			if(caster and caster:IsNull() == false) then
				ExecuteOrderFromTable({
					UnitIndex = caster:entindex(),	--индекс кастера
					TargetIndex = caster.penguin:entindex(),
					OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET,	-- тип приказа
				})
			end
		end)
	else
		caster.penguin:RemoveSelf()
		self:GetCaster():RemoveModifierByName("modifier_sled_penguin_movement")
	end
end

modifier_item_felt_boots_custom = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	IsItem = function() return true end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT_UNIQUE,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
	} end,
	GetModifierMoveSpeedBonus_Constant_Unique = function(self) return self.ms_bonus end,
	GetModifierIncomingDamageResistance_Percentage = function(self) return self.damage_resist end,
    GetModifierStatusResistanceStacking = function(self) return self.status_resist end,
})

function modifier_item_felt_boots_custom:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.ms_bonus = self:GetAbility():GetSpecialValueFor("ms_bonus")
	self.damage_resist = self:GetAbility():GetSpecialValueFor("damage_resist")
	self.status_resist = self:GetAbility():GetSpecialValueFor("status_resist")
	self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_boots_of_travel_2", nil)
end

function modifier_item_felt_boots_custom:OnDestroy()
	local caster = self:GetCaster()
	if IsValidEntity(caster.penguin) and caster.penguin:IsAlive() then
		caster.penguin:Kill(nil,nil)
	end
	self.parent:RemoveModifierByName("modifier_item_boots_of_travel_2")
end




modifier_sled_penguin_passive = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_EVENT_ON_ORDER
	} end
})

function modifier_sled_penguin_passive:OnCreated( kv )
	if IsServer() then
		self.hPlayerEnt = nil
	end
end

function modifier_sled_penguin_passive:OnOrder( params )
	if IsServer() then
		local hOrderedUnit = params.unit 
		local hTargetUnit = params.target
		local nOrderType = params.order_type
		if nOrderType ~= DOTA_UNIT_ORDER_MOVE_TO_TARGET and nOrderType ~= DOTA_UNIT_ORDER_ATTACK_TARGET then
			return
		end

		if hTargetUnit == nil or hTargetUnit ~= self:GetParent() or hTargetUnit:HasModifier( "modifier_sled_penguin_movement" ) or hTargetUnit:HasModifier( "modifier_sled_penguin_crash" ) then
			return
		end

		if hOrderedUnit ~= nil and hOrderedUnit:IsRealHero() and hOrderedUnit:GetTeamNumber() == DOTA_TEAM_GOODGUYS and hOrderedUnit:HasModifier( "modifier_sled_penguin_movement" ) == false then
			self.hPlayerEnt = hOrderedUnit
			self:StartIntervalThink( 0.25 )
			return
		end
	end

	return 0
end

function modifier_sled_penguin_passive:OnDestroy()
	if IsServer() then
		if self.hPlayerEnt ~= nil and self.hPlayerEnt:IsNull() == false then
			self.hPlayerEnt:RemoveModifierByName( "modifier_sled_penguin_movement" )
		end
	end

	return 0
end

function modifier_sled_penguin_passive:OnIntervalThink()
	if IsServer() then
		if self:GetParent():HasModifier( "modifier_sled_penguin_movement" ) or self:GetParent():HasModifier( "modifier_sled_penguin_crash" ) then
			self:StartIntervalThink( -1 )
			return
		end

		if self.hPlayerEnt ~= nil then
			local flTalkDistance = 250.0
			if flTalkDistance >= ( self.hPlayerEnt:GetOrigin() - self:GetParent():GetOrigin() ):Length2D() then
				self.hPlayerEnt:Interrupt()
				EmitSoundOn( "SledPenguin.PlayerHopOn", self:GetParent() )
				self:GetCaster():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_sled_penguin_movement", nil)
				self.hPlayerEnt:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_sled_penguin_movement", nil)
			end
		end
	end
end





modifier_sled_penguin_movement = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	GetModifierDisableTurning = function() return 1 end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_DISABLE_TURNING,
		MODIFIER_EVENT_ON_ORDER
	} end
})

function modifier_sled_penguin_movement:GetOverrideAnimation( params )
	if self:GetParent() ~= self:GetCaster() then
		return ACT_DOTA_FLAIL
	end

	return ACT_DOTA_SLIDE_LOOP
end

function modifier_sled_penguin_movement:OnCreated( kv )
	if IsServer() then
		self.max_sled_speed = self:GetAbility():GetSpecialValueFor( "max_sled_speed" )
		self.speed_step = self:GetAbility():GetSpecialValueFor( "speed_step" )
		self.crash_impaired_duration = self:GetAbility():GetSpecialValueFor( "crash_impaired_duration" )
		self.tree_destroy_radius = self:GetAbility():GetSpecialValueFor( "tree_destroy_radius" )
		self.speed_turn = self:GetAbility():GetSpecialValueFor( "speed_turn" )
		self.pinata_burst_radius = self:GetAbility():GetSpecialValueFor( "pinata_burst_radius" )

		self.nCurSpeed = 20
		self.flDesiredYaw = self:GetCaster():GetAnglesAsVector().y

		self.bPlayedVroomSinceLastCrash = false

		if kv.just_crashed ~= nil then
			self.speed_step = self.speed_step / 2.0
			self.nCurSpeed = 0

			local impaired_duration = self:GetAbility():GetSpecialValueFor( "impaired_duration" )
			self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_sled_penguin_impairment", { duration = impaired_duration } )

			self:GetParent():StartGesture( ACT_DOTA_DIE )

			if self:IsParentPenguin() then
				FindClearSpaceForUnit( self:GetParent(), self:GetParent():GetAbsOrigin(), true )
			end
		end

		if self:ApplyMotionController() == false then
			self:Destroy()
			return
		end
	end
end

function modifier_sled_penguin_movement:OnControlledMotionInterrupted()
    if(not IsServer()) then
        return
    end
    self:Destroy()
end

function modifier_sled_penguin_movement:OnDestroy()
	if IsServer() then
		self:RemoveMotionController()
		if self:IsParentPenguin() then
			self:GetCaster():RemoveGesture( ACT_DOTA_SLIDE_LOOP )

			--StopSoundOn( "SledPenguin.RidingLoop", self:GetParent() )

			EmitSoundOn( "Hero_Tusk.IceShards.Penguin", self:GetParent() )
		else
			local parent = self:GetParent()
			-- Apply knockback to player hero
			local vLocation = parent:GetForwardVector()
			parent:ApplyKnockback(parent, self:GetAbility(), vLocation, 0, 0.5, 100, false)
			if(parent.penguin and IsValidEntity(parent.penguin)) then
				UTIL_Remove(parent.penguin)
			end
		end
	end
end

function modifier_sled_penguin_movement:CheckState()
	return {
		[ MODIFIER_STATE_STUNNED ] = self:IsParentPenguin(),
		[ MODIFIER_STATE_INVULNERABLE ] = self:IsParentPenguin(),
		[ MODIFIER_STATE_NO_HEALTH_BAR ] = self:IsParentPenguin(),
		[ MODIFIER_STATE_UNSELECTABLE ] = self:IsParentPenguin(),

		--[ MODIFIER_STATE_MUTED ] = self:IsParentPenguin() == false,
	}
end

function modifier_sled_penguin_movement:OnControlledMotion( me, dt )
	if IsServer() then
		if not self:GetCaster() then
			return
		end

		if self:IsParentPenguin() then
			if self.bStartedLoop == nil and self:GetElapsedTime() > 0.3 then
				self.bStartedLoop = true
				self:GetCaster():StartGesture( ACT_DOTA_SLIDE_LOOP )
			end

			local flTurnAmount = 0.0
			local curAngles = self:GetCaster():GetAngles()

			local flAngleDiff = AngleDiff( self.flDesiredYaw, curAngles.y )

--			local flTurnRate = 125
			flTurnAmount = self.speed_turn * dt
			flTurnAmount = math.min( flTurnAmount, math.abs( flAngleDiff ) )

			if flAngleDiff < 0.0 then
				flTurnAmount = flTurnAmount * -1
			end

			if flAngleDiff ~= 0.0 then
				curAngles.y = curAngles.y + flTurnAmount
				me:SetAbsAngles( curAngles.x, curAngles.y, curAngles.z )
			end

			local vNewPos = self:GetCaster():GetOrigin() + self:GetCaster():GetForwardVector() * ( dt * self.nCurSpeed )
			if GridNav:CanFindPath( me:GetOrigin(), vNewPos ) == false then
				self:CrashAndRecover()
				return
			end
			me:SetOrigin( vNewPos )
			self.nCurSpeed = math.min( self.nCurSpeed + self.speed_step, self.max_sled_speed )

			if ( self.nCurSpeed >= self.max_sled_speed ) and ( self.bPlayedVroomSinceLastCrash == false ) then
				EmitSoundOn( "Frosthaven.Vroom", self:GetParent() )
				self.bPlayedVroomSinceLastCrash = true

				self.nHasteFXIndex = ParticleManager:CreateParticle( "particles/generic_gameplay/rune_haste.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
			end
		else
			if self:GetCaster():IsAlive() == false or self:GetCaster():FindModifierByName( "modifier_sled_penguin_movement" ) == nil then
				self:Destroy()
				return
			end
			me:SetOrigin( self:GetCaster():GetOrigin() )
			local casterAngles = self:GetCaster():GetAngles()
			me:SetAbsAngles( casterAngles.x, casterAngles.y, casterAngles.z )
		end

	end
end

function modifier_sled_penguin_movement:CrashAndRecover()
	GridNav:DestroyTreesAroundPoint( self:GetParent():GetOrigin(), self.tree_destroy_radius, false, self:GetParent())

	-- Start a screenshake with the following parameters: vecCenter, flAmplitude, flFrequency, flDuration, flRadius, eCommand( SHAKE_START = 0, SHAKE_STOP = 1 ), bAirShake
	ScreenShake( self:GetParent():GetOrigin(), 10.0, 100.0, 0.5, 1300.0, 0, true )
	self.reset_pos_offset = self:GetAbility():GetSpecialValueFor( "reset_pos_offset" )

	EmitSoundOn( "SledPenguin.Crash.Impact", self:GetParent() )
	EmitSoundOn( "SledPenguin.Crash.Ow", self:GetParent() )

	if self.nHasteFXIndex then
		ParticleManager:DestroyParticle( self.nHasteFXIndex, false )
	end

	local vForward = self:GetParent():GetForwardVector()
	self.vResetPos = self:GetParent():GetAbsOrigin() - ( vForward * self.reset_pos_offset )

	self:GetParent():SetForwardVector( self:GetParent():GetForwardVector() * -1 )
	self:GetParent():SetAbsOrigin( self.vResetPos )

	self.bPlayedVroomSinceLastCrash = false

	self:Destroy()

	local kv = {}
	kv.just_crashed = true

	self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_sled_penguin_movement", kv )
end

function modifier_sled_penguin_movement:OnOrder( params )
	if IsServer() then
		if not self:GetCaster() then
			return 0
		end

		local hOrderedUnit = params.unit
		local hTargetUnit = params.target
		local nOrderType = params.order_type
		if nOrderType == DOTA_UNIT_ORDER_MOVE_TO_POSITION or nOrderType == DOTA_UNIT_ORDER_ATTACK_MOVE then

			if hOrderedUnit == self:GetParent() and self:IsParentPenguin() == false then
				local vDir = params.new_pos - self:GetCaster():GetOrigin()
				vDir.z = 0
				vDir = vDir:Normalized()
				local angles = VectorAngles( vDir )
				local hBuff = self:GetCaster():FindModifierByName( "modifier_sled_penguin_movement" )
				if hBuff ~= nil then
					hBuff.flDesiredYaw = angles.y
				end
			end
		end
	end

	return 0
end

function modifier_sled_penguin_movement:IsParentPenguin()
	return ( self:GetCaster() == self:GetParent() )
end





modifier_sled_penguin_crash = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	CheckState = function() return {
		[MODIFIER_STATE_STUNNED] = true
	} end,
})

function modifier_sled_penguin_crash:OnCreated( kv )
	if IsServer() then
		self.reset_pos_offset = self:GetAbility():GetSpecialValueFor( "reset_pos_offset" )

		local vForward = self:GetCaster():GetForwardVector()
		self.vResetPos = self:GetCaster():GetAbsOrigin() - ( vForward * self.reset_pos_offset )

		self:GetCaster():RemoveGesture( ACT_DOTA_IDLE )
		self:GetCaster():RemoveGesture( ACT_DOTA_SLIDE_LOOP )
		self:GetCaster():StartGesture( ACT_DOTA_DIE )

		EmitSoundOn( "SledPenguin.Crash.Impact", self:GetParent() )
		EmitSoundOn( "SledPenguin.Crash.Ow", self:GetParent() )
	end
end

function modifier_sled_penguin_crash:OnDestroy()
	if IsServer() then
		self:GetCaster():SetForwardVector( self:GetCaster():GetForwardVector() * -1 )

		self:GetCaster():SetAbsOrigin( self.vResetPos )

	end
end





modifier_sled_penguin_impairment = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	GetEffectName = function() return "particles/units/heroes/hero_brewmaster/brewmaster_drunken_haze_debuff.vpcf" end,
	GetStatusEffectName = function() return "particles/status_fx/status_effect_brewmaster_drunken_haze.vpcf" end,
	StatusEffectPriority = function() return 50 end
})


LinkLuaModifier("modifier_item_felt_boots_custom", "items/item_felt_boots_custom", LUA_MODIFIER_MOTION_NONE ,  modifier_item_felt_boots_custom)
LinkLuaModifier("modifier_sled_penguin_passive", "items/item_felt_boots_custom", LUA_MODIFIER_MOTION_NONE ,  modifier_sled_penguin_passive)
LinkLuaModifier("modifier_sled_penguin_movement", "items/item_felt_boots_custom", LUA_MODIFIER_MOTION_NONE ,  modifier_sled_penguin_movement)
LinkLuaModifier("modifier_sled_penguin_crash", "items/item_felt_boots_custom", LUA_MODIFIER_MOTION_NONE ,  modifier_sled_penguin_crash)
LinkLuaModifier("modifier_sled_penguin_impairment", "items/item_felt_boots_custom", LUA_MODIFIER_MOTION_NONE ,  modifier_sled_penguin_impairment)
