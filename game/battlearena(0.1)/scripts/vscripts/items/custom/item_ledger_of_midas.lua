require('items/generic_datadriven_item')


item_ledger_of_midas = class({})


function item_ledger_of_midas:GetIntrinsicModifierName()
	return "modifier_item_ledger_of_midas"
end

modifier_item_ledger_of_midas = class({
	IsHidden 				= function(self) return true end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } 
	end,
})


function modifier_item_ledger_of_midas:OnCreated()
	if IsServer() and self:GetParent():IsRealHero() then
		local interval = self:GetAbility():GetSpecialValueFor("interval")
		self:StartIntervalThink(interval)
	end
end

function modifier_item_ledger_of_midas:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local tick_gold = ability:GetSpecialValueFor("tick_gold")
	if caster:IsRealHero() then
		caster:ModifyGoldFiltered(tick_gold, false, DOTA_ModifyGold_GameTick)
	end
end

function modifier_item_ledger_of_midas:GetModifierBonusHealth()
	return self:GetAbility():GetSpecialValueFor("bonus_health")
end

item_ledger_of_midas_1 = class(item_ledger_of_midas)
item_ledger_of_midas_2 = class(item_ledger_of_midas)
item_ledger_of_midas_3 = class(item_ledger_of_midas)
item_ledger_of_midas_4 = class(item_ledger_of_midas)


LinkLuaModifier("modifier_item_ledger_of_midas", "items/custom/item_ledger_of_midas", LUA_MODIFIER_MOTION_NONE ,  modifier_item_ledger_of_midas)
