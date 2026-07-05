modifier_dark_edge_invisible = modifier_dark_edge_invisible or class({})

function modifier_dark_edge_invisible:IsHidden() return false end
function modifier_dark_edge_invisible:IsPurgable() return false end
function modifier_dark_edge_invisible:RemoveOnDeath() return false end
function modifier_dark_edge_invisible:DestroyOnExpire() return true end

function modifier_dark_edge_invisible:OnCreated()
	self.fade_time_block = true
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()

	if not IsServer() then return end

	Timers:CreateTimer(self.invis_fade_time, function()
		local invis_fx = ParticleManager:CreateParticle("particles/generic_hero_status/status_invisibility_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControl(invis_fx, 0, self.parent:GetOrigin())
		ParticleManager:ReleaseParticleIndex(invis_fx)

		self.fade_time_block = false
		return nil
	end)
end

function modifier_dark_edge_invisible:OnRefresh()
	if not IsValidEntity(self.ability) then return end

	self.break_duration = self.ability:GetSpecialValueFor("break_duration")
	self.invis_movespeed_bonus_pct = self.ability:GetSpecialValueFor("invis_movespeed_bonus_pct")
	self.invis_bonus_damage = self.ability:GetSpecialValueFor("invis_bonus_damage")
	self.invis_fade_time = self.ability:GetSpecialValueFor("invis_fade_time")
end

function modifier_dark_edge_invisible:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK, -- GetModifierProcAttack_Feedback
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, -- GetModifierMoveSpeedBonus_Percentage
		MODIFIER_PROPERTY_ON_ABILITY_EXECUTED_CUSTOM, -- OnAbilityExecuted
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL, -- GetModifierInvisibilityLevel
		MODIFIER_PROPERTY_TOOLTIP , -- OnTooltip
	}
end

function modifier_dark_edge_invisible:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = not self.fade_time_block,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_CANNOT_MISS] = true,
	}
end

function modifier_dark_edge_invisible:OnTooltip(params)
	return self.invis_bonus_damage
end

function modifier_dark_edge_invisible:OnAbilityExecuted(params)
	if not IsServer() then return end
	if not IsValidEntity(self.parent) then return end
	if params.unit ~= self.parent then return end

	self:Destroy()
end

function modifier_dark_edge_invisible:GetModifierProcAttack_Feedback(params)
	local target = params.target

	if not IsValidEntity(target) then return end
	if not IsValidEntity(self.parent) then return end

	if target:GetTeamNumber() == self.parent:GetTeamNumber() then return end
	if params.attacker ~= self.parent then return end
	if self.fade_time_block then return end

	ApplyDamage({
		victim = target,
		attacker = self.parent,
		damage = self.invis_bonus_damage,
		damage_type = DAMAGE_TYPE_PHYSICAL
	})

	EmitSoundOn("DOTA_Item.SilverEdge.Target", target)
	target:AddNewModifier(self.parent, self.ability, "modifier_dark_edge_break", { duration = self.break_duration })

	self:Destroy()
end

function modifier_dark_edge_invisible:GetModifierMoveSpeedBonus_Percentage() return self.invis_movespeed_bonus_pct end
function modifier_dark_edge_invisible:GetModifierInvisibilityLevel() return 1 end
