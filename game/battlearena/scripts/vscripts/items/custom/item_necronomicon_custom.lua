require('items/generic_datadriven_item')

item_necronomicon_custom = class({
	GetIntrinsicModifierName = function() return "modifier_item_necronomicon_custom" end
})

modifier_item_necronomicon_custom = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
	} end,
	GetModifierBonusStats_Strength = function(self) return self.bonus_str end,
	GetModifierBonusStats_Agility = function(self) return self.bonus_agi end,
	GetModifierBonusStats_Intellect = function(self) return self.bonus_int end,
	GetModifierConstantManaRegen = function(self) return self.bonus_mp_regen end
})

function modifier_item_necronomicon_custom:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_item_necronomicon_custom:OnRefresh()
	if not self.ability then return end
	self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
	self.bonus_agi = self.ability:GetSpecialValueFor("bonus_agi")
	self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
	self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
end

item_necronomicon_custom_1 = class(item_necronomicon_custom)
item_necronomicon_custom_2 = class(item_necronomicon_custom)
item_necronomicon_custom_3 = class(item_necronomicon_custom)

item_necronomicon_tank_1 = class(item_necronomicon_custom)
item_necronomicon_tank_2 = class(item_necronomicon_custom)
item_necronomicon_tank_3 = class(item_necronomicon_custom)

item_necronomicon_warrior_1 = class(item_necronomicon_custom)
item_necronomicon_warrior_2 = class(item_necronomicon_custom)
item_necronomicon_warrior_3 = class(item_necronomicon_custom)

item_necronomicon_warrior_tank_1 = class(item_necronomicon_custom)
item_necronomicon_warrior_tank_2 = class(item_necronomicon_custom)
item_necronomicon_warrior_tank_3 = class(item_necronomicon_custom)

item_necronomicon_archer_1 = class(item_necronomicon_custom)
item_necronomicon_archer_2 = class(item_necronomicon_custom)
item_necronomicon_archer_3 = class(item_necronomicon_custom)

item_necronomicon_mage_1 = class(item_necronomicon_custom)
item_necronomicon_mage_2 = class(item_necronomicon_custom)
item_necronomicon_mage_3 = class(item_necronomicon_custom)

item_necronomicon_mage_archer_1 = class(item_necronomicon_custom)
item_necronomicon_mage_archer_2 = class(item_necronomicon_custom)
item_necronomicon_mage_archer_3 = class(item_necronomicon_custom)

function UseNecronomicon(self, caster, units)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local spawn_point = caster:GetAbsOrigin() + caster:GetForwardVector() * 180
	local summon_duration = self:GetSpecialValueFor("duration")
	caster[string.sub(self:GetAbilityName(), 0, string.len(self:GetAbilityName()) - 2)] = caster[string.sub(self:GetAbilityName(), 0, string.len(self:GetAbilityName()) - 2)] or {}
	local summons = caster[string.sub(self:GetAbilityName(), 0, string.len(self:GetAbilityName()) - 2)]
	if summons[1] ~= nil then
		for _, unit in pairs(summons) do
			--unit:Kill(nil,nil)
		end
	end
	if string.find(self:GetAbilityName(), "item_necronomicon_custom") then
		for _, unit in pairs(units) do
			local baseDamage = string.find(unit, "warrior") and self:GetSpecialValueFor("warrior_damage") or self:GetSpecialValueFor("archer_damage")
			local basePhysicalArmor = string.find(unit, "warrior") and self:GetSpecialValueFor("warrior_armor") or self:GetSpecialValueFor("archer_armor")
			local baseMaxHealth = string.find(unit, "warrior") and self:GetSpecialValueFor("warrior_hp") or self:GetSpecialValueFor("archer_hp")
			local baseAttackTime = string.find(unit, "warrior") and self:GetSpecialValueFor("warrior_BAT") or self:GetSpecialValueFor("archer_BAT")
			local summon = CreateSummon(
				caster,
				unit,
				spawn_point,
				summon_duration,
				baseDamage,
				basePhysicalArmor,
				baseMaxHealth,
				baseAttackTime
			)
			table.insert(summons, summon)
			if summon:HasAbility("necronomicon_warrior_cleave") then
				summon:RemoveAbility("necronomicon_warrior_cleave")
			end
			if summon:HasAbility("creature_split_shot") then
				summon:RemoveAbility("creature_split_shot")
			end
			--summon:SetLevel(self:GetLevel())
			for i = 0, 5 do
				local ability = summon:GetAbilityByIndex(i)
				if ability then
					ability:SetLevel(self:GetLevel())
				end
			end
			local particle = ParticleManager:CreateParticle("particles/items_fx/necronomicon_spawn.vpcf", PATTACH_ABSORIGIN, summon)
            ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle, 2)
			--[[local new_model_scale = self:GetSpecialValueFor("model_scale")
			if not (new_model_scale == nil) then
				summon:SetModelScale(self:GetSpecialValueFor("model_scale"))
			end]]
		end
	else
		for _, unit in pairs(units) do
			local summon = CreateSummon(
				caster,
				unit,
				spawn_point,
				summon_duration,
				self:GetSpecialValueFor("summon_damage"),
				self:GetSpecialValueFor("summon_armor"),
				self:GetSpecialValueFor("summon_hp"),
				self:GetSpecialValueFor("summon_BAT")
			)
			table.insert(summons, summon)
			--summon:SetLevel(self:GetLevel())
			for i = 0, 5 do
				local ability = summon:GetAbilityByIndex(i)
				if ability then
					ability:SetLevel(self:GetLevel())
				end
			end
			local particle = ParticleManager:CreateParticle("particles/items_fx/necronomicon_spawn.vpcf", PATTACH_ABSORIGIN, summon)
            ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle, 2)
			--[[local new_model_scale = self:GetSpecialValueFor("model_scale")
			if not (new_model_scale == nil) then
				summon:SetModelScale(self:GetSpecialValueFor("model_scale"))
			end]]
		end
	end
	GridNav:DestroyTreesAroundPoint(spawn_point, 180, false, caster)
	EmitSoundOn("Item.Necronomicon.Cast", caster)
end

function item_necronomicon_custom_1:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_warrior_1", "npc_roshdef_necronomicon_archer_1"})
end
function item_necronomicon_custom_2:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_warrior_1", "npc_roshdef_necronomicon_archer_1"})
end
function item_necronomicon_custom_3:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_warrior_1", "npc_roshdef_necronomicon_archer_1"})
end

function item_necronomicon_tank_1:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_tank"})
end
function item_necronomicon_tank_2:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_tank"})
end
function item_necronomicon_tank_3:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_tank"})
end

function item_necronomicon_warrior_tank_1:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_warrior_tank"})
end
function item_necronomicon_warrior_tank_2:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_warrior_tank"})
end
function item_necronomicon_warrior_tank_3:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_warrior_tank"})
end

function item_necronomicon_warrior_1:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_warrior_2"})
end
function item_necronomicon_warrior_2:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_warrior_2"})
end
function item_necronomicon_warrior_3:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_warrior_2"})
end


function item_necronomicon_archer_1:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_archer_2"})
end
function item_necronomicon_archer_2:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_archer_2"})
end
function item_necronomicon_archer_3:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_archer_2"})
end

function item_necronomicon_mage_1:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_mage"})
end
function item_necronomicon_mage_2:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_mage"})
end
function item_necronomicon_mage_3:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_mage"})
end

function item_necronomicon_mage_archer_1:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_mage_archer"})
end
function item_necronomicon_mage_archer_2:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_mage_archer"})
end
function item_necronomicon_mage_archer_3:OnSpellStart()
	UseNecronomicon(self, self:GetCaster(), {"npc_roshdef_necronomicon_mage_archer"})
end

LinkLuaModifier("modifier_item_necronomicon_custom", "items/custom/item_necronomicon_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_necronomicon_custom)