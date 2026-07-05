require("items/custom/item_base_with_optional_unit_target")

item_potion_hp = class(item_base_with_optional_unit_target)

function item_potion_hp:Precache(context)
	PrecacheResource("particle", "particles/items_fx/healing_flask.vpcf", context)
end

function item_potion_hp:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function item_potion_hp:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget() or caster
	local buff_duration = self:GetSpecialValueFor("buff_duration")
	target:AddNewModifier(caster, self, "modifier_item_potion_hp_buff", {duration = buff_duration})
	target:EmitSound("HealingSalve.Cast")	
	self:SpendCharge()
	if (self:GetCurrentCharges() < 1) then
		self:Destroy()
	end
end

item_potion_hp_1 = class(item_potion_hp)
item_potion_hp_2 = class(item_potion_hp)
item_potion_hp_3 = class(item_potion_hp)
item_potion_hp_4 = class(item_potion_hp)

item_potion_mp = class(item_base_with_optional_unit_target)

function item_potion_mp:Precache(context)
	PrecacheResource("particle", "particles/items_fx/healing_clarity.vpcf", context)
end

function item_potion_mp:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function item_potion_mp:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget() or caster
	local buff_duration = self:GetSpecialValueFor("buff_duration")
	target:AddNewModifier(caster, self, "modifier_item_potion_mp_buff", {duration = buff_duration})
	target:EmitSound("Clarity.Cast")	
	self:SpendCharge()
	if (self:GetCurrentCharges() < 1) then
		self:Destroy()
	end
end

item_potion_mp_1 = class(item_potion_mp)
item_potion_mp_2 = class(item_potion_mp)
item_potion_mp_3 = class(item_potion_mp)
item_potion_mp_4 = class(item_potion_mp)

modifier_item_potion_hp_buff = class({
	IsHidden = function() 
		return false 
	end,
	DeclareFunctions  = function() 
		return 
		{
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
		}
	end,
	GetModifierConstantHealthRegen = function(self)
		return self.bonusHealthRegeneration
	end,
	GetTexture = function(self)
		return self.buffIcon
	end,
	GetEffectName = function()
		return "particles/items_fx/healing_flask.vpcf"
	end
})

function modifier_item_potion_hp_buff:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
	if(IsClient()) then
		self.buffIcon = self.ability:GetAbilityTextureName()
	end
end

function modifier_item_potion_hp_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealthRegeneration = self.ability:GetSpecialValueFor("health_regen")
end

modifier_item_potion_mp_buff = class({
	IsHidden = function() 
		return false 
	end,
	DeclareFunctions  = function() 
		return 
		{
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
		}
	end,
	GetModifierConstantManaRegen = function(self)
		return self.bonusManaRegeneration
	end,
	GetTexture = function(self)
		return self.buffIcon
	end,
	GetEffectName = function()
		return "particles/items_fx/healing_clarity.vpcf"
	end
})

function modifier_item_potion_mp_buff:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
	if(IsClient()) then
		self.buffIcon = self.ability:GetAbilityTextureName()
	end
end

function modifier_item_potion_mp_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusManaRegeneration = self.ability:GetSpecialValueFor("mana_regen")
end

LinkLuaModifier("modifier_item_potion_hp_buff", "items/baseitems/item_potion", LUA_MODIFIER_MOTION_NONE, modifier_item_potion_hp_buff)
LinkLuaModifier("modifier_item_potion_mp_buff", "items/baseitems/item_potion", LUA_MODIFIER_MOTION_NONE, modifier_item_potion_mp_buff)