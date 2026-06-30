
lone_druid_spirit_bear_resist = class({
	GetIntrinsicModifierName = function()
		return "modifier_lone_druid_spirit_bear_resist"
	end
})

modifier_lone_druid_spirit_bear_resist = class({
	IsHidden = function() 
		return true 
	end,
	IsPurgable = function()
		 return false
	end,
	RemoveOnDeath = function() 
		return false 
	end,
    GetAttributes = function()
        return MODIFIER_ATTRIBUTE_PERMANENT
    end,
	DeclareFunctions = function() 
		return 
		{
			MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
		} 
	end,
	GetModifierMagicalResistanceBonus = function(self)
		return self.magicResist
	end,
	GetModifierStatusResistanceStacking = function(self)
		return self.statusResist
	end
})

function modifier_lone_druid_spirit_bear_resist:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
	self:SetHasCustomTransmitterData(true)
end

function modifier_lone_druid_spirit_bear_resist:OnRefresh()
	if(self.ability:IsNull()) then
		return
	end
	self.statusResist = self.ability:GetSpecialValueFor("status_resist")
	self.magicResist = self.ability:GetSpecialValueFor("magic_resist")
end

function modifier_lone_druid_spirit_bear_resist:AddCustomTransmitterData()
    return 
	{
        statusResist = self.statusResist,
        magicResist = self.magicResist
    }
end

function modifier_lone_druid_spirit_bear_resist:HandleCustomTransmitterData(data)
    self.statusResist = data.statusResist
    self.magicResist = data.magicResist
end


LinkLuaModifier("modifier_lone_druid_spirit_bear_resist", "abilities/heroes/hero_lone_druid/spirit_bear_resist", LUA_MODIFIER_MOTION_NONE, modifier_lone_druid_spirit_bear_resist)
