satan_might = satan_might or class({})
LinkLuaModifier("modifier_satan_might_passive", "abilities/hero/satan/satan_might", LUA_MODIFIER_MOTION_NONE)


function satan_might:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_bringer_devour.vpcf", context)
end


function satan_might:GetIntrinsicModifierName()
	return "modifier_satan_might_passive"
end



modifier_satan_might_passive = modifier_satan_might_passive or class({})


function modifier_satan_might_passive:IsHidden() return true end
function modifier_satan_might_passive:IsPurgable() return false end


if not IsServer() then return end


function modifier_satan_might_passive:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	self.chance = self.ability:GetSpecialValueFor("chance")
	self.radius = self.ability:GetSpecialValueFor("radius")
	self.stun_duration = self.ability:GetSpecialValueFor("stun_duration")
	self.overpain_bonus = self.ability:GetSpecialValueFor("overpain_bonus")
end


function modifier_satan_might_passive:OnRefresh()
	self:OnCreated()
end


function modifier_satan_might_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end


function modifier_satan_might_passive:OnAttackLanded(params)
	if params.target ~= self.parent then return end
	if not IsValidEntity(self.parent) or not IsValidEntity(params.target) then return end

	if self.parent:GetTeamNumber() == params.attacker:GetTeamNumber() then return end
	if self.parent:PassivesDisabled() then return end

	if not self.ability:IsCooldownReady() then return end

	if (params.attacker:GetAbsOrigin() - params.target:GetAbsOrigin()):Length2D() > self.radius then return end

	local proc_guaranteed = self.parent:HasModifier("modifier_satan_overpain_buff") and self.overpain_bonus > 0

	if RollPercentage(self.chance) or proc_guaranteed then
		params.attacker:AddNewModifier(self.parent, self.ability, "modifier_stunned", {duration = self.stun_duration})
		params.attacker:EmitSound("DOTA_Item.SkullBasher")

		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_devour.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.attacker)
		ParticleManager:SetParticleControl(particle, 0, params.attacker:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle, 1, params.target:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(particle)

		self.ability:UseResources(false, false, false, true)
	end
end
