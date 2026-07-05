modifier_item_soul_merchant_buff = modifier_item_soul_merchant_buff or class({})
modifier_item_soul_merchant_buff.sign = 1

function modifier_item_soul_merchant_buff:IsPurgable() return false end
function modifier_item_soul_merchant_buff:IsPurgeException() return true end
function modifier_item_soul_merchant_buff:IsDebuff() return false end
function modifier_item_soul_merchant_buff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_item_soul_merchant_buff:RemoveOnDeath() return true end

function modifier_item_soul_merchant_buff:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.caster = self:GetCaster()
	self.interval = 0.2

	self.heal_change_max = self.ability:GetSpecialValueFor("heal_change_max")
	self.movespeed_change_max = self.ability:GetSpecialValueFor("movespeed_change_max")
	self.link_max_distance = self.ability:GetSpecialValueFor("link_max_distance")

	if not IsServer() then return end

	if self.sign < 0 then
		local link_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_dazzle/dazzle_nothl_voyage_tether.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControlEnt(link_particle, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetOrigin(), true)
		ParticleManager:SetParticleControlEnt(link_particle, 1, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetOrigin(), true)
		self:AddParticle(link_particle, false, false, 1, false, false)
	end

	self:StartIntervalThink(self.interval)
end


function modifier_item_soul_merchant_buff:OnDestroy()
	if not IsServer() then return end
	if self.cm and not self.cm:IsNull() then
		self.cm:Destroy()
		self.cm = nil
	end
end


function modifier_item_soul_merchant_buff:OnIntervalThink()
	if not IsValidEntity(self.ability) then self:Destroy() return end
	if not IsValidEntity(self.target) or not self.target:IsAlive() then self:Destroy() return end

	local max_distance = (self.link_max_distance + self.caster:GetCastRangeBonus())
	if (self.parent:GetOrigin() - self.target:GetOrigin()):Length2D() >= max_distance then self:Destroy() return end
	if self.sign > 0 then return end -- only deal damage to the enemy

	local dps_base = self.ability:GetSpecialValueFor("link_dps_base")
	local attribute_name = self.target:GetPrimaryAttribute() == DOTA_ATTRIBUTE_ALL and "link_dps_primary_attribute_universal" or "link_dps_primary_attribute"
	local dps_attribute = self.ability:GetSpecialValueFor(attribute_name) / 100.0
	local damage = (dps_base + dps_attribute * self.target:GetPrimaryStatValue()) * self.interval

	local damage_dealt = ApplyDamage({
		victim = self.parent,
		attacker = self.target,
		damage = damage,
		damage_type = self.ability:GetAbilityDamageType(),
		ability = self.ability
	})

	damage_dealt = GameLoop:ApplyCustomLifestealAmp(self.target, damage_dealt, {})
	self.target:HealWithParams(damage_dealt, self.ability, false, true, self.target, true)
end


function modifier_item_soul_merchant_buff:CheckState()
	return {
		[MODIFIER_STATE_TETHERED] = self.sign < 0
	}
end


function modifier_item_soul_merchant_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, -- GetModifierMoveSpeedBonus_Percentage
		MODIFIER_CUSTOM_PROPERTY_LIFESTEAL_AMPLIFICATION, -- GetCustomLifestealAmplification
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE, -- GetModifierHealAmplify_PercentageSource
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, -- GetModifierHealAmplify_PercentageTarget
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierHPRegenAmplify_Percentage
	}
end

function modifier_item_soul_merchant_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.sign * self.movespeed_change_max * (self:GetElapsedTime() / self:GetDuration())
end

function modifier_item_soul_merchant_buff:GetCustomLifestealAmplification()
	return self.sign * self.heal_change_max * (self:GetElapsedTime() / self:GetDuration())
end

function modifier_item_soul_merchant_buff:GetModifierHealAmplify_PercentageSource()
	return self.sign * self.heal_change_max * (self:GetElapsedTime() / self:GetDuration())
end

function modifier_item_soul_merchant_buff:GetModifierHealAmplify_PercentageTarget()
	return self.sign * self.heal_change_max * (self:GetElapsedTime() / self:GetDuration())
end

function modifier_item_soul_merchant_buff:GetModifierHPRegenAmplify_Percentage()
	return self.sign * self.heal_change_max * (self:GetElapsedTime() / self:GetDuration())
end



modifier_item_soul_merchant_debuff = modifier_item_soul_merchant_debuff or class(modifier_item_soul_merchant_buff)
modifier_item_soul_merchant_debuff.sign = -1

function modifier_item_soul_merchant_debuff:IsDebuff() return true end
