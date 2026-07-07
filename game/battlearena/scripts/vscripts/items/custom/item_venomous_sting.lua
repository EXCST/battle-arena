require('items/generic_datadriven_item')


item_venomous_sting = class({
	GetIntrinsicModifierName = function() return "modifier_venomous_sting_passive" end
})

modifier_venomous_sting_passive = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	} end,
	GetModifierPreAttack_BonusDamage = function(self) return self.bonus_dmg end
})

function modifier_venomous_sting_passive:OnCreated()
	if not IsServer() then return end
	self.caster = self:GetParent()
	self.ability = self:GetAbility()
	self.bonus_dmg = self:GetAbility():GetSpecialValueFor("bonus_dmg")
	self.duration = self:GetAbility():GetSpecialValueFor("duration")
end

function modifier_venomous_sting_passive:OnAttackLanded(kv)
	if not IsServer() then return end
	if kv.attacker == self:GetParent() and not kv.attacker:IsNull() then
		kv.target:AddNewModifier(self.caster, self.ability, "modifier_venomous_sting_debuff", {duration = self.duration})
	end
end

modifier_venomous_sting_debuff = class({
	IsHidden = function() return false end,
	IsPurgable = function() return true end
})

function modifier_venomous_sting_debuff:OnCreated()
	if not IsServer() then return end
	self.interval = self:GetAbility():GetSpecialValueFor("interval")
	self.dmg_per_sec = self:GetAbility():GetSpecialValueFor("dmg_per_sec")
	self.damage = self.interval * self.dmg_per_sec
	self:StartIntervalThink(self.interval)
end

function modifier_venomous_sting_debuff:OnIntervalThink()
	if not IsServer() then return end
	ApplyDamage({
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self.damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility()
	})
end


LinkLuaModifier("modifier_venomous_sting_passive", "items/custom/item_venomous_sting", LUA_MODIFIER_MOTION_NONE, modifier_venomous_sting_passive)
LinkLuaModifier("modifier_venomous_sting_debuff", "items/custom/item_venomous_sting", LUA_MODIFIER_MOTION_NONE, modifier_venomous_sting_debuff)
