require('items/generic_datadriven_item')

item_bkb_custom = class({
	GetIntrinsicModifierName = function() return "modifier_item_bkb_custom" end
})

item_bkb_custom_1 = class(item_bkb_custom)
item_bkb_custom_2 = class(item_bkb_custom)
item_bkb_custom_3 = class(item_bkb_custom)

item_vandal_helm_1 = class(item_bkb_custom)
item_vandal_helm_2 = class(item_bkb_custom)
item_vandal_helm_3 = class(item_bkb_custom)

item_marauder_helm_1 = class(item_bkb_custom)
item_marauder_helm_2 = class(item_bkb_custom)
item_marauder_helm_3 = class(item_bkb_custom)

function item_bkb_custom:Precache(context)
    PrecacheResource("soundfile", "soundevents/game_sounds_items.vsndevts", context)
end

function ActivateBKB(self, caster)
	if not IsServer() then return end
	caster:AddNewModifier(caster, self, "modifier_avatar_custom", {duration = self:GetSpecialValueFor("bkb_duration")})
	caster:Purge(false, true, false, false, false)
	EmitSoundOn("DOTA_Item.BlackKingBar.Activate", caster)
end

function item_bkb_custom_1:OnSpellStart()
	ActivateBKB(self, self:GetCaster())
end
function item_bkb_custom_2:OnSpellStart()
	ActivateBKB(self, self:GetCaster())
end
function item_bkb_custom_3:OnSpellStart()
	ActivateBKB(self, self:GetCaster())
end

function item_vandal_helm_1:OnSpellStart()
	ActivateBKB(self, self:GetCaster())
end
function item_vandal_helm_2:OnSpellStart()
	ActivateBKB(self, self:GetCaster())
end
function item_vandal_helm_3:OnSpellStart()
	ActivateBKB(self, self:GetCaster())
end

function item_marauder_helm_1:OnSpellStart()
	ActivateBKB(self, self:GetCaster())
end
function item_marauder_helm_2:OnSpellStart()
	ActivateBKB(self, self:GetCaster())
end
function item_marauder_helm_3:OnSpellStart()
	ActivateBKB(self, self:GetCaster())
end

modifier_item_bkb_custom = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
    IsPurgeException = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	} end,
	GetModifierBonusStats_Strength = function(self) return self.bonus_str end,
	GetModifierPhysicalArmorBonus = function(self) return self.bonus_armor end
})

function modifier_item_bkb_custom:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_item_bkb_custom:OnRefresh()
	self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
	self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
	self.bonus_armor = self.ability:GetSpecialValueFor("bonus_armor")
end

modifier_avatar_custom = class({
	IsPurgable = function() return false end,
	CheckState = function() return {
		[MODIFIER_STATE_MAGIC_IMMUNE] = true
	} end,
	GetEffectName = function() return "particles/items_fx/black_king_bar_avatar.vpcf" end,
	GetEffectAttachType = function() return PATTACH_ABSORIGIN_FOLLOW end
})

LinkLuaModifier("modifier_item_bkb_custom", "items/item_bkb_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_bkb_custom)
LinkLuaModifier("modifier_avatar_custom", "items/item_bkb_custom", LUA_MODIFIER_MOTION_NONE, modifier_avatar_custom)