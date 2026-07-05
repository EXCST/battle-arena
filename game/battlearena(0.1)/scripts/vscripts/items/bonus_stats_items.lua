
item_bonus_stats = class({})

function item_bonus_stats:IncreaseStr()
	local caster = PlayerResource:GetSelectedHeroEntity(self:GetCaster():GetPlayerOwnerID())

	local particle = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_red.vpcf"
	local fx = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	EmitSoundOn("DOTA_Item.Refresher.Activate", caster)
	local statModifier = caster:AddNewModifier(caster, self, "modifier_item_bonus_strength", nil)
	if(statModifier) then
		statModifier:SetStackCount(statModifier:GetStackCount() + self:GetSpecialValueFor("bonus_stat"))
		statModifier:IncreaseNetworth(GetItemCost(self:GetAbilityName()))
	end
	caster:CalculateStatBonus(true)
end

function item_bonus_stats:IncreaseAgi()
	local caster = PlayerResource:GetSelectedHeroEntity(self:GetCaster():GetPlayerOwnerID())

	local particle = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_green.vpcf"
	local fx = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	EmitSoundOn("DOTA_Item.Refresher.Activate", caster)
	local statModifier = caster:AddNewModifier(caster, self, "modifier_item_bonus_agility", nil)
	if(statModifier) then
		statModifier:SetStackCount(statModifier:GetStackCount() + self:GetSpecialValueFor("bonus_stat"))
		statModifier:IncreaseNetworth(GetItemCost(self:GetAbilityName()))
	end
	caster:CalculateStatBonus(true)
end

function item_bonus_stats:IncreaseInt()
	local caster = PlayerResource:GetSelectedHeroEntity(self:GetCaster():GetPlayerOwnerID())

	local particle = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_blue.vpcf"
	local fx = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	EmitSoundOn("DOTA_Item.Refresher.Activate", caster)
	local statModifier = caster:AddNewModifier(caster, self, "modifier_item_bonus_intellect", nil)
	if(statModifier) then
		statModifier:SetStackCount(statModifier:GetStackCount() + self:GetSpecialValueFor("bonus_stat"))
		statModifier:IncreaseNetworth(GetItemCost(self:GetAbilityName()))
	end
	caster:CalculateStatBonus(true)
end

function item_bonus_stats:IncreaseStat()
	local caster = PlayerResource:GetSelectedHeroEntity(self:GetCaster():GetPlayerOwnerID())

	local particle = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_black.vpcf"
	local fx = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	EmitSoundOn("DOTA_Item.Refresher.Activate", caster)

	local modifiers = {
		"modifier_item_bonus_strength",
		"modifier_item_bonus_agility",
		"modifier_item_bonus_intellect"
	}
	local bonusStatValue = self:GetSpecialValueFor("bonus_stat")
	for _, modifier in pairs(modifiers) do
		local statModifier = caster:AddNewModifier(caster, self, modifier, nil)
		if(statModifier) then
			statModifier:SetStackCount(statModifier:GetStackCount() + self:GetSpecialValueFor("bonus_stat"))
			statModifier:IncreaseNetworth(GetItemCost(self:GetAbilityName()))
		end
	end
	caster:CalculateStatBonus(true)
end

item_bonus_stats_str = class(item_bonus_stats)
item_bonus_stats_agi = class(item_bonus_stats)
item_bonus_stats_int = class(item_bonus_stats)
item_bonus_stats_all = class(item_bonus_stats)

function item_bonus_stats_str:OnSpellStart()
	if(not IsServer()) then
		return
	end
	self:IncreaseStr()
	self:Destroy()
end

function item_bonus_stats_agi:OnSpellStart()
	if(not IsServer()) then
		return
	end
	self:IncreaseAgi()
	self:Destroy()
end

function item_bonus_stats_int:OnSpellStart()
	if(not IsServer()) then
		return
	end
	self:IncreaseInt()
	self:Destroy()
end

function item_bonus_stats_all:OnSpellStart()
	if(not IsServer()) then
		return
	end
	self:IncreaseStat()
	self:Destroy()
end

item_bonus_stats_shop_str = class(item_bonus_stats)
item_bonus_stats_shop_agi = class(item_bonus_stats)
item_bonus_stats_shop_int = class(item_bonus_stats)
item_bonus_stats_shop_all = class(item_bonus_stats)

function item_bonus_stats_shop_str:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local item_stacks = self:GetCurrentCharges()
	for i=1,item_stacks do
		self:IncreaseStr()
	end
	self:Destroy()
end

function item_bonus_stats_shop_agi:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local item_stacks = self:GetCurrentCharges()
	for i=1,item_stacks do
		self:IncreaseAgi()
	end
	self:Destroy()
end

function item_bonus_stats_shop_int:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local item_stacks = self:GetCurrentCharges()
	for i=1,item_stacks do
		self:IncreaseInt()
	end
	self:Destroy()
end

function item_bonus_stats_shop_all:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local item_stacks = self:GetCurrentCharges()
	for i=1,item_stacks do
		self:IncreaseStat()
	end
	self:Destroy()
end

item_bonus_str_10_shop = class(item_bonus_stats_shop_str)
item_bonus_agi_10_shop = class(item_bonus_stats_shop_agi)
item_bonus_int_10_shop = class(item_bonus_stats_shop_int)
item_bonus_stats_10_shop = class(item_bonus_stats_shop_all)

item_bonus_str_100_shop = class(item_bonus_stats_shop_str)
item_bonus_agi_100_shop = class(item_bonus_stats_shop_agi)
item_bonus_int_100_shop = class(item_bonus_stats_shop_int)
item_bonus_stats_50_shop = class(item_bonus_stats_shop_all)

item_bonus_str_1 = class(item_bonus_stats_str)
item_bonus_str_5 = class(item_bonus_stats_str)
item_bonus_str_10 = class(item_bonus_stats_str)
item_bonus_str_50 = class(item_bonus_stats_str)

item_bonus_agi_1 = class(item_bonus_stats_agi)
item_bonus_agi_5 = class(item_bonus_stats_agi)
item_bonus_agi_10 = class(item_bonus_stats_agi)
item_bonus_agi_50 = class(item_bonus_stats_agi)

item_bonus_int_1 = class(item_bonus_stats_int)
item_bonus_int_5 = class(item_bonus_stats_int)
item_bonus_int_10 = class(item_bonus_stats_int)
item_bonus_int_50 = class(item_bonus_stats_int)

item_bonus_stats_1 = class(item_bonus_stats_all)
item_bonus_stats_2 = class(item_bonus_stats_all)
item_bonus_stats_5 = class(item_bonus_stats_all)
item_bonus_stats_10 = class(item_bonus_stats_all)
item_bonus_stats_50 = class(item_bonus_stats_all)

item_bonus_stats_100 = class(item_bonus_stats_all)

modifier_item_bonus_strength = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	RemoveOnDeath = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS
	} end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT end,
	AllowIllusionDuplicate = function()
		return true
	end
})

function modifier_item_bonus_strength:OnCreated()
	self.value = 0
	if(not IsServer()) then
		return
	end
	self.networth = 0
	self.parent = self:GetParent()
	if(self.parent:IsIllusion()) then
		local playerHero = PlayerResource:GetSelectedHeroEntity(self.parent:GetPlayerOwnerID())
		if(playerHero) then
			local modifier = playerHero:FindModifierByName(self:GetName())
			if(modifier) then
				self:SetStackCount(modifier:GetStackCount())
				self.networth = modifier.networth
			end
		end
	end
end

function modifier_item_bonus_strength:IncreaseNetworth(price)
	self.networth = self.networth + price
end

function modifier_item_bonus_strength:GetNetworth()
	return self.networth
end

function modifier_item_bonus_strength:GetModifierBonusStats_Strength()
	return self:GetStackCount()
end

function modifier_item_bonus_strength:GetTexture()
	return "item_str_bonus"
end

modifier_item_bonus_agility = class(modifier_item_bonus_strength)

function modifier_item_bonus_agility:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS
	}
end

function modifier_item_bonus_agility:GetModifierBonusStats_Agility()
	return self:GetStackCount()
end

function modifier_item_bonus_agility:GetTexture()
	return "item_agi_bonus"
end

modifier_item_bonus_intellect = class(modifier_item_bonus_strength)

function modifier_item_bonus_intellect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
	}
end

function modifier_item_bonus_intellect:GetModifierBonusStats_Intellect()
	return self:GetStackCount()
end

function modifier_item_bonus_intellect:GetTexture()
	return "item_int_bonus"
end


LinkLuaModifier("modifier_item_bonus_strength", "items/bonus_stats_items", LUA_MODIFIER_MOTION_NONE, modifier_item_bonus_strength)
LinkLuaModifier("modifier_item_bonus_agility", "items/bonus_stats_items", LUA_MODIFIER_MOTION_NONE, modifier_item_bonus_agility)
LinkLuaModifier("modifier_item_bonus_intellect", "items/bonus_stats_items", LUA_MODIFIER_MOTION_NONE, modifier_item_bonus_intellect)
