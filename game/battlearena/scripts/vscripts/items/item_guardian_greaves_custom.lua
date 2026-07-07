require('items/generic_datadriven_item')


item_guardian_greaves_custom = class({
	GetIntrinsicModifierName = function() return "modifier_item_guardian_greaves_custom" end
})

function item_guardian_greaves_custom:OnSpellStart()
	local allies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		self:GetCaster():GetAbsOrigin(),
		nil,
		self:GetSpecialValueFor("active_radius"),
		self:GetAbilityTargetTeam(),
		self:GetAbilityTargetType(),
		self:GetAbilityTargetFlags(),
		0,
		false
	)
	local arcane_pfx = ParticleManager:CreateParticle("particles/items_fx/arcane_boots.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:ReleaseParticleIndex(arcane_pfx)
	local mekansm_pfx = ParticleManager:CreateParticle("particles/items2_fx/mekanism.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:ReleaseParticleIndex(mekansm_pfx)
	for _, ally in pairs(allies) do
		ally:AddNewModifier(self:GetCaster(), self, "modifier_item_guardian_greaves_custom_buff", {duration = self:GetSpecialValueFor("duration")})

		local arcane_target_pfx = ParticleManager:CreateParticle("particles/items_fx/arcane_boots_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, ally)
		ParticleManager:ReleaseParticleIndex(arcane_target_pfx)

		local mekansm_target_pfx = ParticleManager:CreateParticle("particles/items2_fx/mekanism_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, ally)
		ParticleManager:SetParticleControlEnt(mekansm_target_pfx, 1, ally, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
		ParticleManager:ReleaseParticleIndex(mekansm_target_pfx)
	end
	EmitSoundOn("Item.GuardianGreaves.Activate", self:GetCaster())
end

modifier_item_guardian_greaves_custom = class({
	IsHidden = function() return true end,
	IsAura = function() return true end,
	IsPurgable = function() return false end,
	IsItem = function() return true end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT_UNIQUE
	} end,
	GetModifierMoveSpeedBonus_Constant_Unique = function(self) return self.ms_bonus end,
	GetAuraSearchTeam = function(self) return self:GetAbility():GetAbilityTargetTeam() end,
	GetAuraSearchType = function(self) return self:GetAbility():GetAbilityTargetType() end,
	GetAuraSearchFlags = function(self) return self:GetAbility():GetAbilityTargetFlags() end,
	GetAuraRadius = function(self) return self.aura_radius end,
	GetModifierAura = function() return "modifier_item_guardian_greaves_custom_aura" end,
	GetAuraDuration = function() return 0 end
})

function modifier_item_guardian_greaves_custom:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.ms_bonus = self:GetAbility():GetSpecialValueFor("ms_bonus")
	self.aura_radius = self:GetAbility():GetSpecialValueFor("aura_radius")
	self:OnRefresh()
end

function modifier_item_guardian_greaves_custom:OnRefresh()
	if self.ability:GetLevel() == 3 then
        self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_boots_of_travel", nil)
    elseif self.ability:GetLevel() > 3 then
        self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_boots_of_travel_2", nil)
    end
end

function modifier_item_guardian_greaves_custom:OnDestroy()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    if self.ability:GetLevel() == 3 then
        self.parent:RemoveModifierByName("modifier_item_boots_of_travel")
    elseif self.ability:GetLevel() > 3 then
        self.parent:RemoveModifierByName("modifier_item_boots_of_travel_2")
    end
end
modifier_item_guardian_greaves_custom_aura = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	} end,
	GetModifierConstantHealthRegen = function(self) return self.aura_hp_regen end,
	GetModifierConstantManaRegen = function(self) return self.aura_mana_regen end,
	GetModifierPhysicalArmorBonus = function(self) return self.aura_armor_bonus end,
	GetTexture = function(self) return self:GetAbility():GetAbilityTextureName() end
})

function modifier_item_guardian_greaves_custom_aura:OnCreated()
	self.aura_hp_regen = self:GetAbility():GetSpecialValueFor("aura_hp_regen")
	self.aura_mana_regen = self:GetAbility():GetSpecialValueFor("aura_mana_regen")
	self.aura_armor_bonus = self:GetAbility():GetSpecialValueFor("aura_armor_bonus")
end

modifier_item_guardian_greaves_custom_buff = class({
	IsHidden = function() return false end,
	IsPurgable = function() return true end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	} end,
	GetModifierConstantHealthRegen = function(self) return self.active_hp_regen end,
	GetModifierConstantManaRegen = function(self) return self.active_mana_regen end,
	GetModifierPhysicalArmorBonus = function(self) return self.active_armor_bonus end,
	GetTexture = function(self) return self:GetAbility():GetAbilityTextureName() end
})

function modifier_item_guardian_greaves_custom_buff:OnCreated()
	self.active_hp_regen = self:GetAbility():GetSpecialValueFor("active_hp_regen")
	self.active_mana_regen = self:GetAbility():GetSpecialValueFor("active_mana_regen")
	self.active_armor_bonus = self:GetAbility():GetSpecialValueFor("active_armor_bonus")
end

item_guardian_greaves_1 = class(item_guardian_greaves_custom)
item_guardian_greaves_2 = class(item_guardian_greaves_custom)
item_guardian_greaves_3 = class(item_guardian_greaves_custom)
item_guardian_greaves_4 = class(item_guardian_greaves_custom)


LinkLuaModifier("modifier_item_guardian_greaves_custom", "items/item_guardian_greaves_custom", 0, modifier_item_guardian_greaves_custom)
LinkLuaModifier("modifier_item_guardian_greaves_custom_aura", "items/item_guardian_greaves_custom", 0, modifier_item_guardian_greaves_custom_aura)
LinkLuaModifier("modifier_item_guardian_greaves_custom_buff", "items/item_guardian_greaves_custom", 0, modifier_item_guardian_greaves_custom_buff)
