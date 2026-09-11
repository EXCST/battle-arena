require('items/generic_datadriven_item')


item_rd_mekansm = class({
	GetIntrinsicModifierName = function() return "modifier_rd_mekansm" end
})

function item_rd_mekansm:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local heal = self:GetSpecialValueFor("heal")
		local heal_radius = self:GetSpecialValueFor("heal_radius")
		local heal_pct = self:GetSpecialValueFor("heal_pct")

		caster:EmitSound("DOTA_Item.Mekansm.Activate")
		local mekansm_pfx = ParticleManager:CreateParticle("particles/items2_fx/mekanism.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
		ParticleManager:ReleaseParticleIndex(mekansm_pfx)

		local caster_loc = caster:GetAbsOrigin()
		local nearby_allies = FindUnitsInRadius(caster:GetTeam(), caster_loc, nil, heal_radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
		for _, ally in pairs(nearby_allies) do
			if not ally:HasModifier("modifier_rd_mekansm_cant_heal") then
				local pct_heal = ally:GetMaxHealth() / 100 * heal_pct
				local healingDone = ally:Heal(heal + pct_heal, caster, DOTA_HEAL_TYPE_HEALING)
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, healingDone, nil)

				local mekansm_target_pfx = ParticleManager:CreateParticle("particles/items2_fx/mekanism_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, ally)
				ParticleManager:SetParticleControl(mekansm_target_pfx, 0, caster_loc)
				ParticleManager:SetParticleControl(mekansm_target_pfx, 1, ally:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(mekansm_target_pfx)
				ally:AddNewModifier(caster, self, "modifier_rd_mekansm_cant_heal", {duration = self:GetCooldown(self:GetLevel())})
			end
		end
	end
end

modifier_rd_mekansm = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	IsPermanent = function() return true end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	} end
})

function modifier_rd_mekansm:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("strength")
end

function modifier_rd_mekansm:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("agility")
end

function modifier_rd_mekansm:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("intellect")
end

function modifier_rd_mekansm:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("armor")
end

modifier_rd_mekansm_cant_heal = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	RemoveOnDeath = function() return false end
})


LinkLuaModifier("modifier_rd_mekansm", "items/custom/item_rd_mekansm", LUA_MODIFIER_MOTION_NONE, modifier_rd_mekansm)
LinkLuaModifier("modifier_rd_mekansm_cant_heal", "items/custom/item_rd_mekansm", LUA_MODIFIER_MOTION_NONE, modifier_rd_mekansm_cant_heal)
