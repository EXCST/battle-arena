satan_overpain = satan_overpain or class({})
LinkLuaModifier("modifier_satan_overpain_buff", "abilities/hero/satan/satan_overpain", LUA_MODIFIER_MOTION_NONE)


function satan_overpain:Precache(context)
	PrecacheResource("particle", "particles/econ/items/monkey_king/arcana/fire/monkey_king_spring_fire_base.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/legion/legion_fallen/legion_fallen_press_owner.vpcf", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_doombringer.vsndevts", context)
end


function satan_overpain:GetBehavior()
	if self:GetSpecialValueFor("can_cast_on_allies") > 0 then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	end

	return DOTA_ABILITY_BEHAVIOR_NO_TARGET
end


function satan_overpain:OnSpellStart()
	local caster = self:GetCaster()
	local target

	if self:GetSpecialValueFor("can_cast_on_allies") > 0 then
		target = self:GetCursorTarget()
	else
		target = caster
	end

	local duration = self:GetSpecialValueFor("duration")

	target:AddNewModifier(caster, self, "modifier_satan_overpain_buff", {
		duration = duration
	})

	local particle = ParticleManager:CreateParticle("particles/econ/items/monkey_king/arcana/fire/monkey_king_spring_fire_base.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(particle)

	caster:EmitSound("doom_bringer_doom_cast_0" .. RandomInt(1, 3))
end



modifier_satan_overpain_buff = modifier_satan_overpain_buff or class({})


function modifier_satan_overpain_buff:IsHidden() return false end
function modifier_satan_overpain_buff:IsPurgable() return false end


function modifier_satan_overpain_buff:GetEffectName()
	return "particles/econ/items/legion/legion_fallen/legion_fallen_press_owner.vpcf"
end


function modifier_satan_overpain_buff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end


function modifier_satan_overpain_buff:OnCreated()
	local ability = self:GetAbility()

	self.damage_reduction = ability:GetSpecialValueFor("damage_decrease")
	self.health_regen     = ability:GetSpecialValueFor("hp_regen")
end


function modifier_satan_overpain_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
	}
end


function modifier_satan_overpain_buff:GetModifierIncomingDamage_Percentage() return self.damage_reduction end
function modifier_satan_overpain_buff:GetModifierHealthRegenPercentage() return self.health_regen end
