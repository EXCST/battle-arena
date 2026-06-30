require("items/item_auto_precache")
item_dark_edge = item_dark_edge or class(item_auto_precache)

LinkLuaModifier("modifier_dark_edge", "items/dark_edge/dark_edge", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_edge_break", "items/dark_edge/modifier_dark_edge_break", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_edge_cold", "items/dark_edge/modifier_dark_edge_cold", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_edge_invisible", "items/dark_edge/modifier_dark_edge_invisible", LUA_MODIFIER_MOTION_NONE)

function item_dark_edge:Precache(context)
	PrecacheResource("particle", "particles/dark_edge/dark_edge.vpcf", context)
end
function item_dark_edge:GetIntrinsicModifierName() return "modifier_dark_edge" end

function item_dark_edge:OnSpellStart()
	local caster = self:GetCaster()
	if not IsValidEntity(caster) then return end

	local invis_duration = self:GetSpecialValueFor("invis_duration")

	caster:AddNewModifier(caster, self, "modifier_dark_edge_invisible", { duration = invis_duration })

	EmitSoundOn("DOTA_Item.InvisibilitySword.Activate", caster)
end

modifier_dark_edge = modifier_dark_edge or class({})

function modifier_dark_edge:IsHidden() return true end
function modifier_dark_edge:IsPurgable() return false end
function modifier_dark_edge:RemoveOnDeath() return false end
function modifier_dark_edge:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_dark_edge:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_dark_edge:OnRefresh()
	if not IsValidEntity(self.ability) then return end

	self.cold_duration = self.ability:GetSpecialValueFor("cold_duration")

	self.damage = self.ability:GetSpecialValueFor("damage")
	self.attack_speed = self.ability:GetSpecialValueFor("attack_speed")
	self.all_stats = self.ability:GetSpecialValueFor("all_stats")
	self.health = self.ability:GetSpecialValueFor("health")
	self.mana = self.ability:GetSpecialValueFor("mana")
	self.hp_regen = self.ability:GetSpecialValueFor("hp_regen")
end

function modifier_dark_edge:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK, -- GetModifierProcAttack_Feedback

		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, -- GetModifierPreAttack_BonusDamage
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, -- GetModifierAttackSpeedBonus_Constant
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, -- GetModifierBonusStats_Strength
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS, -- GetModifierBonusStats_Agility
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS, -- GetModifierExtraHealthBonus
		MODIFIER_PROPERTY_EXTRA_MANA_BONUS, -- GetModifierExtraManaBonus
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, -- GetModifierConstantHealthRegen
	}
end

function modifier_dark_edge:GetModifierProcAttack_Feedback(params)
	local target = params.target

	if not IsValidEntity(target) then return end
	if not IsValidEntity(self.parent) then return end

	if target:GetTeamNumber() == self.parent:GetTeamNumber() then return end
	if params.attacker ~= self.parent then return end

	target:AddNewModifier(self.parent, self.ability, "modifier_dark_edge_cold", { duration = self.cold_duration })
end

function modifier_dark_edge:GetModifierPreAttack_BonusDamage() return self.damage end
function modifier_dark_edge:GetModifierAttackSpeedBonus_Constant() return self.attack_speed end
function modifier_dark_edge:GetModifierBonusStats_Strength() return self.all_stats end
function modifier_dark_edge:GetModifierBonusStats_Agility() return self.all_stats end
function modifier_dark_edge:GetModifierBonusStats_Intellect() return self.all_stats end
function modifier_dark_edge:GetModifierExtraHealthBonus() return self.health end
function modifier_dark_edge:GetModifierExtraManaBonus() return self.mana end
function modifier_dark_edge:GetModifierConstantHealthRegen() return self.hp_regen end