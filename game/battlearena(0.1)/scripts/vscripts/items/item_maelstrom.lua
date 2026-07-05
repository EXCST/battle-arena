require('items/generic_datadriven_item')


item_maelstorm_custom = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_maelstorm_custom"
	end
})

function item_maelstorm_custom:Precache(context)
	PrecacheResource("particle", "particles/items_fx/chain_lightning.vpcf", context)
	PrecacheResource("particle", "particles/items2_fx/mjollnir_shield.vpcf", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_mjollnir_shield.vpcf", context)
end

item_maelstorm_custom_1 = class(item_maelstorm_custom)
item_maelstorm_custom_2 = class(item_maelstorm_custom)
item_maelstorm_custom_3 = class(item_maelstorm_custom)
item_maelstorm_custom_4 = class(item_maelstorm_custom)
item_maelstorm_custom_5 = class(item_maelstorm_custom)
item_maelstorm_custom_6 = class(item_maelstorm_custom)

modifier_item_maelstorm_custom = class({
    IsHidden = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    DeclareFunctions = function()
        return {
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
        }
    end,
	IsDebuff = function()
		return false
	end,
	IsPermanent = function()
		return true
	end,
	GetAttributes = function()
		return MODIFIER_ATTRIBUTE_MULTIPLE
	end,
	GetModifierPreAttack_BonusDamage = function(self)
		return self.bonusDamage
	end,
	GetModifierAttackSpeedBonus_Constant = function(self)
		return self.bonusAttackSpeed
	end
})

function modifier_item_maelstorm_custom:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.bonusAttackSpeed = self.ability:GetSpecialValueFor("bonus_attack_speed")
	self.bonusDamage = self.ability:GetSpecialValueFor("bonus_damage")
	if(not IsServer()) then
		return
	end
	self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_maelstorm_custom_unique", {duration = -1})
end

function modifier_item_maelstorm_custom:OnDestroy()
	if(not IsServer()) then
		return
	end
	local modifiers = self.parent:FindAllModifiersByName("modifier_item_maelstorm_custom")
	if(#modifiers == 0) then
		self.parent:RemoveModifierByName("modifier_item_maelstorm_custom_unique")
	end
end

modifier_item_maelstorm_custom_unique = class({
    IsHidden = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    DeclareFunctions = function()
        return {
			MODIFIER_EVENT_ON_ATTACK_LANDED
        }
    end,
	IsDebuff = function()
		return false
	end,
	IsPermanent = function()
		return true
	end,
	GetAttributes = function()
		return MODIFIER_ATTRIBUTE_PERMANENT
	end
})

function modifier_item_maelstorm_custom_unique:OnCreated()
	if(not IsServer()) then
		return
	end
	self.parent = self:GetParent()
	self:OnRefresh()
    self.parentTeam = self.parent:GetTeamNumber()
	self.targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	self.targetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
	self.targetFlags = DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
end

function modifier_item_maelstorm_custom_unique:OnRefresh()
	if(not IsServer()) then
		return
	end
	self.ability = self:GetAbility()
	if(not self.ability) then
		return
	end
	self.procChance = self.ability:GetSpecialValueFor("proc_chance")
	self.bounceDamage = self.ability:GetSpecialValueFor("bounce_damage")
	self.bouncePrimaryAttributeToDamagePct = self.ability:GetSpecialValueFor("bounce_primary_stat_to_damage_pct") / 100
	self.bounceRadius = self.ability:GetSpecialValueFor("bounce_radius")
	self.bounceDelay = self.ability:GetSpecialValueFor("bounce_delay")
	self.cooldown = self.ability:GetSpecialValueFor("bounce_cooldown")
	self.bounceLimit = self.ability:GetSpecialValueFor("bounce_count")
end

function modifier_item_maelstorm_custom_unique:OnIntervalThink()
	self.inCooldown = nil
	self:StartIntervalThink(-1)
end

function modifier_item_maelstorm_custom_unique:OnAttackLanded(kv)
	if(not IsServer()) then
		return
	end
	if(self.inCooldown) then
		return
	end
	-- If this attack is irrelevant, do nothing
	if self.parent ~= kv.attacker then
		return
	end

	-- If this is an illusion, do nothing either
	if self.parent:IsIllusion() then
		return
	end
	-- If the target is invalid, still do nothing
	if (not kv.target:IsBaseNPC()) then
		return
	end
	if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parentTeam) ~= UF_SUCCESS) then
        return
    end
	-- zap the target's ass
	if RollPseudoRandom(self.procChance, self) then
		local bounceDamage = (self.bounceDamage * (1 + self.parent:GetSpellAmplification(false)))
		if(self.parent.GetPrimaryStatValue) then
			bounceDamage = bounceDamage + (self.bouncePrimaryAttributeToDamagePct * self.parent:GetPrimaryStatValue())
		end
		LaunchLightning(kv.attacker, kv.target, self.ability, bounceDamage, self.bounceRadius, self.bounceDelay, self.bounceLimit, self.targetTeam, self.targetType, self.targetFlags, self.parentTeam)
		self.inCooldown = true
		self:StartIntervalThink(self.cooldown)
	end
end

item_imba_mjollnir = class(item_maelstorm_custom_2)

function item_imba_mjollnir:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local target = self:GetCursorTarget()
	target:AddNewModifier(target, self, "modifier_item_imba_mjollnir_static", {duration = self:GetSpecialValueFor("static_duration")})
	target:EmitSound("Mjollnir.Activate")
end

item_imba_mjollnir_2 = class(item_imba_mjollnir)

item_greater_mjollnir = class(item_imba_mjollnir_2)

modifier_item_imba_mjollnir_static = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return true
    end,
    DeclareFunctions = function()
        return {
			MODIFIER_EVENT_ON_TAKEDAMAGE
        }
    end,
	IsDebuff = function()
		return false
	end,
	GetEffectName = function()
		return "particles/items2_fx/mjollnir_shield.vpcf"
	end,
	GetEffectAttachType = function()
		return PATTACH_ABSORIGIN_FOLLOW
	end,
	GetStatusEffectName = function()
		return "particles/status_fx/status_effect_mjollnir_shield.vpcf"
	end
})

-- Start playing sound and store ability parameters
function modifier_item_imba_mjollnir_static:OnCreated()
	if(not IsServer()) then
		return
	end
	self.parent = self:GetParent()
	self.parent :EmitSound("Mjollnir.Loop")
	self.damageTable = {
		attacker = self.parent,
		victim = nil,
		ability = self.ability,
		damage = 0,
		damage_type = DAMAGE_TYPE_MAGICAL,
		damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
	}
	self:OnRefresh()
end

function modifier_item_imba_mjollnir_static:OnRefresh()
	if(not IsServer()) then
		return
	end
	self.ability = self:GetAbility()
	if(not self.ability) then
		return
	end
	self.procChance = self.ability:GetSpecialValueFor("static_proc_chance")
	self.staticDamage = self.ability:GetSpecialValueFor("static_damage")
	self.staticPrimaryAttributeToDamagePct = self.ability:GetSpecialValueFor("static_primary_stat_to_damage_pct") / 100
	self.staticRadius = self.ability:GetSpecialValueFor("static_radius")
	self.staticSlowDuration = self.ability:GetSpecialValueFor("static_slow_duration")
	self.staticCooldown = self.ability:GetSpecialValueFor("static_cooldown")
	self.staticSlow = self.ability:GetSpecialValueFor("static_slow")
end

function modifier_item_imba_mjollnir_static:OnTakeDamage(keys)
	if(not IsServer()) then
		return
	end
	-- If this damage event is irrelevant, do nothing
	if self.parent ~= keys.unit then
		return
	end

	-- If the attacker is invalid, do nothing either
	if keys.attacker:GetTeam() == self.parent:GetTeam() then
		return
	end
	if RollPseudoRandom(self.procChance, self) then
		self.damageTable.damage = (self.staticDamage * (1 + self.parent:GetSpellAmplification(false)))
		if(self.parent.GetPrimaryStatValue) then
			self.damageTable.damage = self.damageTable.damage + (self.staticPrimaryAttributeToDamagePct * self.parent:GetPrimaryStatValue())
		end
		local nearby_enemies = FindUnitsInRadius(
			self.parent:GetTeamNumber(),
			self.parent:GetAbsOrigin(),
			nil,
			self.staticRadius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
			FIND_ANY_ORDER,
			false
		)
		for _, enemy in pairs(nearby_enemies) do
			-- Play particle
			local static_pfx = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
			ParticleManager:SetParticleControlEnt(static_pfx, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
			ParticleManager:SetParticleControlEnt(static_pfx, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
			ParticleManager:ReleaseParticleIndex(static_pfx)

			-- Apply damage
			self.damageTable.victim = enemy
			ApplyDamage(self.damageTable)

			-- Apply slow modifier
			enemy:AddNewModifier(
				self.parent,
				self.ability,
				"modifier_item_imba_mjollnir_slow",
				{
					duration = self.staticSlowDuration,
					staticSlow = self.staticSlow
				}
			)
		end
		-- Play hit sound if at least one enemy was hit
		if #nearby_enemies > 0 then
			self.parent:EmitSound("Maelstrom.Chain_Lightning.Jump")
		end
	end
end

function modifier_item_imba_mjollnir_static:OnDestroy()
	if(not IsServer()) then
		return
	end
	StopSoundEvent("Mjollnir.Loop", self.parent)
end

modifier_item_imba_mjollnir_slow = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return true
    end,
    DeclareFunctions = function()
        return {
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        }
    end,
	IsDebuff = function()
		return true
	end,
	GetModifierMoveSpeedBonus_Percentage = function(self)
		return self.staticSlow
	end,
	GetModifierAttackSpeedBonus_Constant = function(self)
		return self.staticSlow
	end
})

function modifier_item_imba_mjollnir_slow:OnCreated(kv)
	if(not IsServer()) then
		return
	end
	self.staticSlow = kv.staticSlow
	self:SetHasCustomTransmitterData(true)
end

function modifier_item_imba_mjollnir_slow:AddCustomTransmitterData()
    return
    {
        staticSlow = self.staticSlow
    }
end

function modifier_item_imba_mjollnir_slow:HandleCustomTransmitterData(data)
    self.staticSlow = data.staticSlow
end

-----------------------------------------------------------------------------------------------------------
--	Lightning proc functions
-----------------------------------------------------------------------------------------------------------

-- Initial launch + main loop
function LaunchLightning(caster, target, ability, damage, bounce_radius, delay, bounce_limit, targetTeam, targetType, targetFlags, parentTeam)
	if target:IsMagicImmune() then
		return
	end

	-- Parameters
	local targets_hit = {}

	-- Play initial sound
	caster:EmitSound("Maelstrom.Chain_Lightning")

	-- Play first bounce sound
	target:EmitSound("Maelstrom.Chain_Lightning.Jump")
	local targets_hit = {}
	ZapThem(caster, ability, caster, target, damage, bounce_radius, targets_hit, delay, 0, bounce_limit, targetTeam, targetType, targetFlags, parentTeam)
end

-- One bounce. Particle + damage
function ZapThem(caster, ability, source, target, damage, bounce_radius, targets_hit, delay, current_bounce_count, bounce_limit, targetTeam, targetType, targetFlags, parentTeam)
	-- 7.31 cause crash if something is null
	if(not caster or caster:IsNull() == true or not ability or ability:IsNull() == true or not source or source:IsNull() == true) then
		return
	end
	if(not target or target:IsNull() == true) then
		return
	end
	-- Draw particle
	local bounce_pfx = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, source)
	ParticleManager:SetParticleControlEnt(bounce_pfx, 0, source, PATTACH_POINT_FOLLOW, "attach_hitloc", source:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(bounce_pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(bounce_pfx, 2, Vector(1, 1, 1))
	ParticleManager:ReleaseParticleIndex(bounce_pfx)
	ApplyDamage({attacker = caster, victim = target, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_NONE})
	targets_hit[target] = true
	current_bounce_count = current_bounce_count + 1
	if(current_bounce_count >= bounce_limit) then
		return
	end
	local lastKnownPosition = target:GetAbsOrigin()
	local bounceFunction = function()
		local searchPosition = lastKnownPosition
		if(target:IsNull() == false) then
			searchPosition = target:GetAbsOrigin()
		end
		local nearby_enemies = FindUnitsInRadius(
			parentTeam,
			searchPosition,
			nil,
			bounce_radius,
			targetTeam,
			targetType,
			targetFlags,
			FIND_CLOSEST,
			false
		)
		for _, enemy in pairs(nearby_enemies) do
			if(not targets_hit[enemy]) then
				ZapThem(caster, ability, target, enemy, damage, bounce_radius, targets_hit, delay, current_bounce_count, bounce_limit, targetTeam, targetType, targetFlags, parentTeam)
				break
			end
		end
	end
	if(delay > 0) then
		Timers:CreateTimer(delay, bounceFunction)
	else
		bounceFunction()
	end
end


LinkLuaModifier("modifier_item_maelstorm_custom", "items/item_maelstrom", LUA_MODIFIER_MOTION_NONE	, modifier_item_maelstorm_custom)
LinkLuaModifier("modifier_item_maelstorm_custom_unique", "items/item_maelstrom", LUA_MODIFIER_MOTION_NONE	, modifier_item_maelstorm_custom_unique)
LinkLuaModifier("modifier_item_imba_mjollnir_static", "items/item_maelstrom", LUA_MODIFIER_MOTION_NONE, modifier_item_imba_mjollnir_static)
LinkLuaModifier("modifier_item_imba_mjollnir_slow", "items/item_maelstrom", LUA_MODIFIER_MOTION_NONE		, modifier_item_imba_mjollnir_slow)
