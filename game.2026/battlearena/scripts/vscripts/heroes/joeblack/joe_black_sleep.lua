joe_black_sleep = joe_black_sleep or class({})
LinkLuaModifier("modifier_joe_black_sleep", "heroes/joeblack/joe_black_sleep", LUA_MODIFIER_MOTION_NONE)


function joe_black_sleep:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:TriggerSpellAbsorb(self) or target:TriggerSpellReflect(self) then
		return
	end

	local duration = self:GetSpecialValueFor("duration")
	local spread_radius = self:GetSpecialValueFor("spread_radius")
	local spread_speed = self:GetSpecialValueFor("spread_speed")

	target:AddNewModifier(caster, self, "modifier_joe_black_sleep", {
		duration = duration
	})

	if spread_radius <= 0 then return end

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(), target:GetAbsOrigin(), nil, spread_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false
	)

	local projectile_table = {
		Target 		= nil,
		Source 		= target,
		Ability 	= self,
		EffectName 	= "particles/units/heroes/hero_bane/bane_projectile.vpcf",
		bDodgeable 	= true,
		iMoveSpeed 	= spread_speed,
	}

	for _, enemy in pairs(enemies or {}) do
		if IsValidEntity(enemy) and enemy ~= target then
			projectile_table.Target = enemy
			ProjectileManager:CreateTrackingProjectile(projectile_table)
		end
	end
end


function joe_black_sleep:OnProjectileHit( target, location )
	if not IsValidEntity(target) or not IsValidEntity(self) then return end
	if target:IsMagicImmune() then return end
	if target:TriggerSpellAbsorb(self) or target:TriggerSpellReflect(self) then
		return
	end

	target:AddNewModifier(self:GetCaster(), self, "modifier_joe_black_sleep", {
		duration = self:GetSpecialValueFor("duration")
	})
end



modifier_joe_black_sleep = modifier_joe_black_sleep or class({})


function modifier_joe_black_sleep:GetEffectName()
	return "particles/units/heroes/hero_bane/bane_nightmare.vpcf"
end


function modifier_joe_black_sleep:OnCreated()
	self.parent = self:GetParent()

	local ability = self:GetAbility()

	self.interval        	= ability:GetSpecialValueFor("interval")
	self.health_drain_const = ability:GetSpecialValueFor("health_drain_const") * self.interval
	self.health_drain_pct   = ability:GetSpecialValueFor("health_drain_pct") * self.interval / 100
	self.mana_drain_const 	= ability:GetSpecialValueFor("mana_drain_const") * self.interval
	self.mana_drain_pct     = ability:GetSpecialValueFor("mana_drain_pct") * self.interval / 100

	if not IsServer() then return end

	self.damage_table = {
		attacker    = self:GetCaster(),
		victim      = self.parent,
		damage      = nil,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability     = ability
	}

	self.parent:EmitSound("Hero_Bane.Nightmare")
	self.parent:EmitSound("Hero_Bane.Nightmare.Loop")
	self.ability = ability

	self:StartIntervalThink(self.interval)
end


function modifier_joe_black_sleep:OnIntervalThink()
	if not IsValidEntity(self.parent) or not self.parent:IsAlive() then return end

	self.damage_table.damage = self.parent:GetHealth() * self.health_drain_pct + self.health_drain_const

	ApplyDamage(self.damage_table)

	self.parent:Script_ReduceMana(self.parent:GetMana() * self.mana_drain_pct + self.mana_drain_const, self.ability)
end


function modifier_joe_black_sleep:OnDestroy()
	if not IsServer() then return end
	if not IsValidEntity(self.parent) then return end

	self.parent:StopSound("Hero_Bane.Nightmare.Loop")
	self.parent:EmitSound("Hero_Bane.Nightmare.End")
end


function modifier_joe_black_sleep:CheckState()
	return {
		[MODIFIER_STATE_BLIND]      		 = true,
		[MODIFIER_STATE_NIGHTMARED] 		 = true,
		[MODIFIER_STATE_STUNNED]    		 = true,
		[MODIFIER_STATE_LOW_ATTACK_PRIORITY] = true,
	}
end


function modifier_joe_black_sleep:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
		MODIFIER_PROPERTY_AVOID_DAMAGE,
	}
end


function modifier_joe_black_sleep:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end


function modifier_joe_black_sleep:GetOverrideAnimationRate()
	return 0.2
end


function modifier_joe_black_sleep:GetModifierAvoidDamage(params)
	if params.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end

	self:Destroy()
end