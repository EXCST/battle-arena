require("items/custom/item_base_with_optional_unit_target")


item_meal_base = class(item_base_with_optional_unit_target)

function item_meal_base:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget() or caster
	local healing = self:GetSpecialValueFor("heal")
	if(target == Spawn:GetRoshan())  then
		local modifier = target:AddNewModifier(caster, self, "modifier_item_meal_bonus", {duration = -1})
		if(modifier) then
			modifier:AddMealBonus(healing * (self:GetSpecialValueFor("roshan_bonus_pct_multiplier") / 100))
		end
		target:CalculateGenericBonuses()
	end
	healing = target:Heal(healing, self, DOTA_HEAL_TYPE_HEALING)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, healing, nil)
	EmitSoundOn("ItemMeal.Cast", target)
	self:SpendCharge()
end

modifier_item_meal_bonus = class({
	IsHidden = function(self)
        return true
    end,
    IsPurgable = function()
        return false
    end,
	RemoveOnDeath = function()
		return false
	end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
	end,
	GetModifierBonusHealth = function(self)
		return self.bonusMaxHealth
	end
})

function modifier_item_meal_bonus:OnCreated()
	if(not IsServer()) then
		return
	end
	self.bonusMaxHealth = 0
	self:SetHasCustomTransmitterData(true)
end

function modifier_item_meal_bonus:OnRefresh()
	if(not IsServer()) then
		return
	end
	self:SendBuffRefreshToClients()
end

function modifier_item_meal_bonus:AddMealBonus(bonus)
	self.bonusMaxHealth = self.bonusMaxHealth + (tonumber(bonus) or 0)
	self:ForceRefresh()
end

function modifier_item_meal_bonus:AddCustomTransmitterData()
    return
    {
        bonusMaxHealth = self.bonusMaxHealth
    }
end

function modifier_item_meal_bonus:HandleCustomTransmitterData(data)
    self.bonusMaxHealth = data.bonusMaxHealth
end

item_banana = class(item_meal_base)
item_meat = class(item_meal_base)
item_fish = class(item_meal_base)


LinkLuaModifier("modifier_item_meal_bonus", "items/custom/item_meal", LUA_MODIFIER_MOTION_NONE, modifier_item_meal_bonus)
