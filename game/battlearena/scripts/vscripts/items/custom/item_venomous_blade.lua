require('items/generic_datadriven_item')


item_venomous_blade = class({
	GetIntrinsicModifierName = function() return "modifier_venomous_blade_passive" end
})

function item_venomous_blade:Precache(context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_viper.vsndevts", context)
	PrecacheResource("particle", "particles/units/heroes/hero_viper/viper_viper_strike_debuff.vpcf", context)
end

function item_venomous_blade:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	ProjectileManager:CreateTrackingProjectile({
		Target = self:GetCursorTarget(),
		Source = caster,
		EffectName = "particles/units/heroes/hero_viper/viper_viper_strike.vpcf",
		Ability = self,
		bProvidesVision = false,
		bDodgeable = true,
		iMoveSpeed = self:GetSpecialValueFor("proj_speed"),
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
	})
	EmitSoundOn("hero_viper.viperStrike", caster)
end

function item_venomous_blade:OnProjectileHit(hTarget, vLocation)
	if not IsServer() then return end
	if hTarget then
		hTarget:AddNewModifier(self:GetCaster(), self, "modifier_venomous_blade_debuff", {duration = self:GetSpecialValueFor("duration")})
		EmitSoundOn("Hero_Viper.viperStrikeImpact", self:GetCaster())
	end
end

modifier_venomous_blade_passive = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
	
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_PERCENTAGE,
        } end,
	GetModifierBonusStats_Agility = function(self) return self.bonus_agi end,
	GetModifierPreAttack_BonusDamage = function(self) return self.bonus_dmg end
})

function modifier_venomous_blade_passive:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self:OnRefresh()
	self:SetHasCustomTransmitterData(true)
end

function modifier_venomous_blade_passive:OnRefresh()
	if not self.ability then return end
	self.bonus_agi = self.ability:GetSpecialValueFor("bonus_agi")
	self.bonus_dmg = self.ability:GetSpecialValueFor("bonus_dmg")
end

function modifier_venomous_blade_passive:AddCustomTransmitterData()
	return {
		bonus_agi = self.bonus_agi,
		bonus_dmg = self.bonus_dmg
	}
end

function modifier_venomous_blade_passive:HandleCustomTransmitterData(data)
	self.bonus_dmg = data.bonus_dmg
	self.bonus_agi = data.bonus_agi
end


modifier_venomous_blade_debuff = class({
	IsHidden = function() return false end,
	IsPurgable = function() return true end,
	IsDebuff = function() return true end,
	GetEffectName = function() return "particles/units/heroes/hero_viper/viper_viper_strike_debuff.vpcf" end,
	GetEffectAttachType = function() return PATTACH_ABSORIGIN_FOLLOW end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ROSHDEF_ATTACK_SPEED_PERCENTAGE
	
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_PERCENTAGE,
        } end,
	GetModifierMoveSpeedBonus_Percentage = function(self) return -self.as_ms_debuff end,
	GetModifierAttackSpeed_Percentage = function(self) return -self.as_ms_debuff end

})

function modifier_venomous_blade_debuff:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self:OnRefresh()
	self:StartIntervalThink(self.interval)
	self:SetHasCustomTransmitterData(true)
end

function modifier_venomous_blade_debuff:OnRefresh()
	if not self.ability then return end
	self.interval = self.ability:GetSpecialValueFor("interval")
	self.dmg_per_sec = self.ability:GetSpecialValueFor("dmg_per_sec")
	self.as_ms_debuff = self.ability:GetSpecialValueFor("as_ms_debuff")
end

function modifier_venomous_blade_debuff:OnIntervalThink()
	if not IsServer() then return end
	ApplyDamage({
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		ability = self.ability,
		damage = self.dmg_per_sec * self.interval,
		damage_type = self.ability:GetAbilityDamageType(),
		damage_flags = self.ability:GetAbilityTargetFlags()
	})
end

function modifier_venomous_blade_debuff:AddCustomTransmitterData()
	return {
		as_ms_debuff = self.as_ms_debuff
	}
end

function modifier_venomous_blade_debuff:HandleCustomTransmitterData(data)
	self.as_ms_debuff = data.as_ms_debuff
end

LinkLuaModifier("modifier_venomous_blade_passive", "items/custom/item_venomous_blade", LUA_MODIFIER_MOTION_NONE, modifier_venomous_blade_passive)
LinkLuaModifier("modifier_venomous_blade_debuff", "items/custom/item_venomous_blade", LUA_MODIFIER_MOTION_NONE, modifier_venomous_blade_debuff)
