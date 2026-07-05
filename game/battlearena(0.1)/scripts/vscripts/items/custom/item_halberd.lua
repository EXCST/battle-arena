require('items/generic_datadriven_item')


item_halberd = class({
	GetAOERadius = function(self) return self:GetSpecialValueFor("radius") end,
	GetIntrinsicModifierName = function() return "modifier_item_halberd" end
})

function item_halberd:Precache(context)
	PrecacheResource("soundfile", "soundevents/game_sounds_items.vsndevts", context)
	PrecacheResource("particle", "particles/items2_fx/heavens_halberd.vpcf", context)
end

function item_halberd:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		self:GetCursorPosition(),
		nil,
		self:GetSpecialValueFor("radius"),
		self:GetAbilityTargetTeam(),
		self:GetAbilityTargetType(),
		self:GetAbilityTargetFlags(),
		0,
		false
	)
	for _, enemy in pairs(enemies) do
		enemy:AddNewModifier(self:GetCaster(), self, "modifier_item_halberd_debuff", {duration = self:GetSpecialValueFor("duration")})
	end
	EmitSoundOnLocationWithCaster(self:GetCursorPosition(), "DOTA_Item.HeavensHalberd.Activate", self:GetCaster())
end

modifier_item_halberd = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	IsPermanent = function() return true end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	} end
})

function modifier_item_halberd:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("strength")
end

function modifier_item_halberd:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("attack_damage")
end

modifier_item_halberd_debuff = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	CheckState = function() return {
		[MODIFIER_STATE_DISARMED] = true
	} end,
	GetEffectName = function() return "particles/items2_fx/heavens_halberd.vpcf" end,
	GetEffectAttachType = function() return PATTACH_ABSORIGIN_FOLLOW end
})


LinkLuaModifier("modifier_item_halberd", "items/custom/item_halberd", LUA_MODIFIER_MOTION_NONE, modifier_item_halberd)
LinkLuaModifier("modifier_item_halberd_debuff", "items/custom/item_halberd", LUA_MODIFIER_MOTION_NONE, modifier_item_halberd_debuff)
