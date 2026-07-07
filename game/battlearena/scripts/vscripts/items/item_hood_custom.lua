require('items/generic_datadriven_item')


item_hood_custom = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_hood_custom"
	end
})

item_hood_custom_1 = class(item_hood_custom)
item_hood_custom_2 = class(item_hood_custom)
item_hood_custom_3 = class(item_hood_custom)

item_duran_cloak_1 = class(item_hood_custom)
item_duran_cloak_2 = class(item_hood_custom)
item_duran_cloak_3 = class(item_hood_custom)

item_arcanum_cape_1 = class(item_hood_custom)
item_arcanum_cape_2 = class(item_hood_custom)
item_arcanum_cape_3 = class(item_hood_custom)

modifier_item_hood_custom = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	IsPurgeException = function() return false end,
	RemoveOnDeath = function() return false end,
	DeclareFunctions = function()
		return
		{
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
            MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
	end,
    GetModifierBonusHealth = function(self)
        return self.bonus_health
    end,
    GetModifierConstantHealthRegen = function(self)
        return self.bonus_hp_regen
    end,
})

function modifier_item_hood_custom:GetModifierMagicalResistanceBonus()
	return self:GetStackCount() == 1 and self.bonusSpellResistance or self.night_magic_resist_pct
end


function modifier_item_hood_custom:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
	if(not IsServer()) then
		return
	end
	self:OnIntervalThink()
	self:StartIntervalThink(1)
end

function modifier_item_hood_custom:OnIntervalThink()
	if not IsServer() then return end
	if GameRules:IsDaytime() then
		self:SetStackCount(1)
	else
		self:SetStackCount(0)
	end
end

function modifier_item_hood_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability) then
        return
    end

    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_hp_regen = self.ability:GetSpecialValueFor("bonus_hp_regen")

    self.bonusSpellResistance = self.ability:GetSpecialValueFor("magic_resist_pct")
	self.night_magic_resist_pct = self.ability:GetSpecialValueFor("night_magic_resist_pct")

	if(not IsServer()) then
		return
	end
end

function modifier_item_hood_custom:AddCustomTransmitterData()
    return
    {
        bonusSpellResistance = self.bonusSpellResistance,
        night_magic_resist_pct = self.night_magic_resist_pct
    }
end

function modifier_item_hood_custom:HandleCustomTransmitterData(data)
    self.bonusSpellResistance = data.bonusSpellResistance
    self.night_magic_resist_pct = data.night_magic_resist_pct
end

LinkLuaModifier("modifier_item_hood_custom", "items/item_hood_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_hood_custom)