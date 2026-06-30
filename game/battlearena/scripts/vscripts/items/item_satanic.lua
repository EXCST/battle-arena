require('items/generic_datadriven_item')

item_satanic_lua = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_satanic_lua"
	end
})

function item_satanic_lua:Precache(context)
    PrecacheResource("particle", "particles/items2_fx/satanic_buff.vpcf", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_items.vsndevts", context)
end

function item_satanic_lua:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local caster = self:GetCaster()
	EmitSoundOn("DOTA_Item.Satanic.Activate", caster)
	caster:AddNewModifier(caster, self, "modifier_item_satanic_lua_buff", {duration = self:GetSpecialValueFor("unholy_duration")})
end

modifier_item_satanic_lua = class({
	IsHidden = function()
		return true
	end,
	IsPurgable = function()
		return false
	end,
	IsPermanent = function()
		return true
	end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
		}
	end,
	GetModifierPreAttack_BonusDamage = function(self)
		return self.bonusDamage
	end,
	GetModifierBonusStats_Strength = function(self)
		return self.bonusStr
	end,
	GetModifierStatusResistanceStacking = function(self)
		return self.bonusStatusResistance
	end,
	GetAttributes = function()
		return MODIFIER_ATTRIBUTE_MULTIPLE 
	end
})

function modifier_item_satanic_lua:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.bonusDamage = self.ability:GetSpecialValueFor("bonus_damage")
end

modifier_item_satanic_lua_buff = class({
	IsHidden = function()
		return false
	end,
	IsPurgable = function()
		return true
	end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_TOOLTIP
		}
	end,
	OnTooltip = function(self)
		return self.bonusLifestealPct
	end,
	GetEffectName = function()
		return "particles/items2_fx/satanic_buff.vpcf"
	end,
	GetEffectAttachType = function()
		return PATTACH_ABSORIGIN_FOLLOW
	end,
	GetTexture = function(self)
		return self.icon
	end
})

function modifier_item_satanic_lua_buff:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	if(not IsServer()) then
		self.icon = self.ability:GetAbilityTextureName()
	else
		self:OnRefresh()
		self:SetHasCustomTransmitterData(true)
	end
end
LinkLuaModifier("modifier_item_satanic_lua", "items/item_satanic", LUA_MODIFIER_MOTION_NONE, modifier_item_satanic_lua)
LinkLuaModifier("modifier_item_satanic_lua_buff", "items/item_satanic", LUA_MODIFIER_MOTION_NONE, modifier_item_satanic_lua_buff)
