item_invis_sword = item_invis_sword or class({})
LinkLuaModifier("modifier_item_invis_sword_lua", "items/dark_edge/item_invis_sword", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_invis_sword_invisible", "items/dark_edge/item_invis_sword", LUA_MODIFIER_MOTION_NONE)


function item_invis_sword:GetIntrinsicModifierName() return "modifier_item_invis_sword_lua" end

function item_invis_sword:OnSpellStart()
	local caster = self:GetCaster()
	if not IsValidEntity(caster) then return end

	local invis_duration = self:GetSpecialValueFor("windwalk_duration")

	caster:AddNewModifier(caster, self, "modifier_item_invis_sword_invisible", { duration = invis_duration })

	EmitSoundOn("DOTA_Item.InvisibilitySword.Activate", caster)
end


modifier_item_invis_sword_lua = modifier_item_invis_sword_lua or class({})

function modifier_item_invis_sword_lua:IsHidden() return true end
function modifier_item_invis_sword_lua:IsPurgable() return false end
function modifier_item_invis_sword_lua:RemoveOnDeath() return false end
function modifier_item_invis_sword_lua:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_invis_sword_lua:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_item_invis_sword_lua:OnRefresh()
	if not IsValidEntity(self.ability) then return end

	self.damage = self.ability:GetSpecialValueFor("bonus_damage")
	self.attack_speed = self.ability:GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_invis_sword_lua:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, -- GetModifierPreAttack_BonusDamage
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, -- GetModifierAttackSpeedBonus_Constant
	}
end

function modifier_item_invis_sword_lua:GetModifierPreAttack_BonusDamage() return self.damage end
function modifier_item_invis_sword_lua:GetModifierAttackSpeedBonus_Constant() return self.attack_speed end

modifier_item_invis_sword_invisible = modifier_item_invis_sword_invisible or class({})



function modifier_item_invis_sword_invisible:IsHidden() return false end
function modifier_item_invis_sword_invisible:IsPurgable() return false end
function modifier_item_invis_sword_invisible:RemoveOnDeath() return false end
function modifier_item_invis_sword_invisible:DestroyOnExpire() return true end

function modifier_item_invis_sword_invisible:OnCreated()
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

function modifier_item_invis_sword_invisible:OnRefresh()
	if not IsValidEntity(self.ability) then return end

	self.invis_movespeed_bonus_pct = self.ability:GetSpecialValueFor("windwalk_movement_speed")
	self.invis_bonus_damage = self.ability:GetSpecialValueFor("windwalk_bonus_damage")
	self.invis_fade_time = self.ability:GetSpecialValueFor("windwalk_fade_time")
end

function modifier_item_invis_sword_invisible:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK, -- GetModifierProcAttack_Feedback
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, -- GetModifierMoveSpeedBonus_Percentage
		MODIFIER_PROPERTY_ON_ABILITY_EXECUTED_CUSTOM, -- OnAbilityExecuted
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL, -- GetModifierInvisibilityLevel
		MODIFIER_PROPERTY_TOOLTIP , -- OnTooltip
	}
end

function modifier_item_invis_sword_invisible:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = not self.fade_time_block,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_CANNOT_MISS] = true,
	}
end

function modifier_item_invis_sword_invisible:OnTooltip(params)
	return self.invis_bonus_damage
end

function modifier_item_invis_sword_invisible:OnAbilityExecuted(params)
	if not IsServer() then return end
	if not IsValidEntity(self.parent) then return end
	if params.unit ~= self.parent then return end

	self:Destroy()
end

function modifier_item_invis_sword_invisible:GetModifierProcAttack_Feedback(params)
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

	self:Destroy()
end

function modifier_item_invis_sword_invisible:GetModifierMoveSpeedBonus_Percentage() return self.invis_movespeed_bonus_pct end
function modifier_item_invis_sword_invisible:GetModifierInvisibilityLevel() return 1 end
