require('items/generic_datadriven_item')


old_book = class({
	GetIntrinsicModifierName = function() return "modifier_old_book" end,
	GetAOERadius = function(self) return self:GetSpecialValueFor("radius") end
})

function old_book:Precache(context)
	PrecacheResource("particle", "particles/custom/items/old_book/cast.vpcf", context)
	PrecacheResource("particle", "particles/custom/items/old_book/debuff.vpcf", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_shadow_demon.vsndevts", context)
end

function old_book:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local units = FindUnitsInRadius(
		caster:GetTeamNumber(),
		point,
		nil,
		self:GetSpecialValueFor("radius"),
		self:GetAbilityTargetTeam(),
		self:GetAbilityTargetType(),
		self:GetAbilityTargetFlags(),
		0,
		false
	)
	local particle_ground = "particles/custom/items/old_book/cast.vpcf"
	local particle_ground_fx = ParticleManager:CreateParticle(particle_ground, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle_ground_fx, 0, point)
	ParticleManager:SetParticleControl(particle_ground_fx, 1, Vector(self:GetSpecialValueFor("radius"), 0, 0))
	ParticleManager:SetParticleControl(particle_ground_fx, 2, point)
	ParticleManager:ReleaseParticleIndex(particle_ground_fx)

	for _, unit in pairs(units) do
		if unit:GetTeamNumber() == caster:GetTeamNumber() then
			local unit_heal = unit:GetMaxHealth() / 100 * (self:GetSpecialValueFor("ally_heal_pct") or 0)
			local healingDone = unit:Heal(unit_heal, caster, DOTA_HEAL_TYPE_HEALING)
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, unit, healingDone, nil)
			unit:Purge(false, true, false, true, true)
		else
			unit:Purge(true, false, false, false, false)
			unit:AddNewModifier(caster, self, "modifier_old_book_debuff", {duration = self:GetSpecialValueFor("duration")})
		end
	end
	EmitSoundOnLocationWithCaster(point, "Hero_ShadowDemon.DemonicPurge.Cast", caster)
	EmitSoundOn("Hero_ShadowDemon.DemonicPurge.Cast", caster)
end

modifier_old_book = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	IsPermanent = function() return true end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	} end
})

function modifier_old_book:GetModifierSpellAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("spell_amp_pct")
end

function modifier_old_book:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("spell_lifesteal_amp_pct")
end

function modifier_old_book:GetModifierMPRegenAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("mana_regen_amp_pct")
end

function modifier_old_book:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("strength")
end

function modifier_old_book:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("agility")
end

function modifier_old_book:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("intellect")
end

function modifier_old_book:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("armor")
end

modifier_old_book_debuff = class({
	IsPurgable = function() return false end,
	GetEffectName = function() return "particles/custom/items/old_book/debuff.vpcf" end,
	GetEffectAttachType = function() return PATTACH_ABSORIGIN_FOLLOW end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	} end,
	GetModifierDamageOutgoing_Percentage = function(self) return -self.damage_reduction_pct end,
	GetModifierMoveSpeedBonus_Percentage = function(self) return -self.ms_reduction_pct end
})

function modifier_old_book_debuff:OnCreated()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self:OnRefresh()
	if IsServer() then
		self.damageTable = {
			victim = self.parent,
			attacker = self.caster,
			ability = self.ability,
			damage = 0,
			damage_type = self.ability:GetAbilityDamageType(),
			damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
		}
		self:OnIntervalThink()
		self:StartIntervalThink(1)
		StartSoundEvent("Hero_ShadowDemon.DemonicPurge.Impact", self.parent)
	end
end

function modifier_old_book_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
	self.int_multplier = self.ability:GetSpecialValueFor("int_multplier")
	self.damage_reduction_pct = self.ability:GetSpecialValueFor("damage_reduction_pct")
	self.ms_reduction_pct = self.ability:GetSpecialValueFor("ms_reduction_pct")
end

function modifier_old_book_debuff:OnIntervalThink()
	if not IsServer() then return end
	self.damageTable.damage = self.caster:GetPrimaryStatValue() * self.int_multplier
	local damageDone = ApplyDamage(self.damageTable)
	damageDone = tonumber(damageDone) or 0
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, self.damageTable.victim, damageDone, nil)
end

function modifier_old_book_debuff:OnDestroy()
	if not IsServer() then return end
	StopSoundEvent("Hero_ShadowDemon.DemonicPurge.Impact", self.parent)
	self.parent:EmitSound("Hero_ShadowDemon.DemonicPurge.Damage")
end

item_old_book = class(old_book)
item_ancient_bible = class(old_book)


LinkLuaModifier("modifier_old_book", "items/custom/item_old_book", LUA_MODIFIER_MOTION_NONE, modifier_old_book)
LinkLuaModifier("modifier_old_book_debuff", "items/custom/item_old_book", LUA_MODIFIER_MOTION_NONE, modifier_old_book_debuff)
