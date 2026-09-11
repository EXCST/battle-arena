
item_skull_of_midas = class({})


function item_skull_of_midas:OnSpellStart()
	local caster = self:GetCaster()
	local gold_bonus = self:GetSpecialValueFor("gold_bonus")

	caster:ModifyGoldFiltered(gold_bonus, false, DOTA_ModifyGold_GameTick)

	EmitGlobalSound("LakadMatatag")
end

item_skull_of_midas = class(item_skull_of_midas)
item_skull_of_midas_1 = class(item_skull_of_midas)	