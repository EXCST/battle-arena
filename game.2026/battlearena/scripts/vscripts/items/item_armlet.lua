require('items/generic_datadriven_item')

-- Copyright (C) 2018  The Dota IMBA Development Team
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Editors:
--

--	Author		 -	d2imba
--	DateCreated	 -	24.05.2015	<-- Shits' ancient yo
--	Date Updated -	05.03.2017
--	Converted to Lua by zimberzimber

-----------------------------------------------------------------------------------------------------------
--	Item Definition
-----------------------------------------------------------------------------------------------------------
if item_imba_armlet == nil then item_imba_armlet = class({}) end

function item_imba_armlet:GetAbilityTextureName()
	return "custom/imba_armlet"
end

function item_imba_armlet:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_NO_TARGET end

function item_imba_armlet:GetIntrinsicModifierName()
	return "modifier_imba_armlet_basic" end

function item_imba_armlet:OnSpellStart()
	if IsServer() then

		-- Grant or remove the appropriate modifiers
		local caster = self:GetCaster()

		-- If the caster has a toggle prevention, prevent toggling
		if caster:HasModifier("modifier_imba_armlet_toggle_prevention") then
			return nil
		end

		-- Prevent abusers from spamming Armlets.
		caster:AddNewModifier(caster, self, "modifier_imba_armlet_toggle_prevention", {duration = 0.05})

		if caster:HasModifier("modifier_imba_armlet_unholy_strength") then
			caster:EmitSound("DOTA_Item.Armlet.Activate")
			caster:RemoveModifierByName("modifier_imba_armlet_unholy_strength")
		else
			caster:EmitSound("DOTA_Item.Armlet.DeActivate")
			caster:AddNewModifier(caster, self, "modifier_imba_armlet_unholy_strength", {})
		end
	end
end

function item_imba_armlet:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_imba_armlet_unholy_strength") then
		return "custom/imba_armlet_active" end

	return "custom/imba_armlet"
end

-----------------------------------------------------------------------------------------------------------
--	Basic modifier definition
-----------------------------------------------------------------------------------------------------------
if modifier_imba_armlet_basic == nil then modifier_imba_armlet_basic = class({}) end

function modifier_imba_armlet_basic:IsHidden() 
	return true 
end

function modifier_imba_armlet_basic:IsDebuff() 
	return false 
end

function modifier_imba_armlet_basic:IsPurgable() 
	return false 
end

function modifier_imba_armlet_basic:GetAttributes() 
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end

function modifier_imba_armlet_basic:DeclareFunctions()
	return {	
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
	}
end

function modifier_imba_armlet_basic:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_dmg") 
end
 
function modifier_imba_armlet_basic:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor") 
end

function modifier_imba_armlet_basic:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_str") 
end
 
function modifier_imba_armlet_basic:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_agi") 
end
 
function modifier_imba_armlet_basic:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int") 
end

function modifier_imba_armlet_basic:GetModifierStatusResistanceStacking()
	return self:GetAbility():GetSpecialValueFor("status_resist") 
end
-----------------------------------------------------------------------------------------------------------
--	Unholy Strength modifier dummy effect definition
-----------------------------------------------------------------------------------------------------------
if modifier_imba_armlet_unholy_strength_visual_effect == nil then modifier_imba_armlet_unholy_strength_visual_effect = class({}) end
function modifier_imba_armlet_unholy_strength_visual_effect:IsHidden() return false end
function modifier_imba_armlet_unholy_strength_visual_effect:IsDebuff() return false end
function modifier_imba_armlet_unholy_strength_visual_effect:IsPurgable() return false end
function modifier_imba_armlet_unholy_strength_visual_effect:AllowIllusionDuplicate() return true end -- Allow illusions to carry this particle modifier


-----------------------------------------------------------------------------------------------------------
--	Unholy Strength modifier definition
-----------------------------------------------------------------------------------------------------------
if modifier_imba_armlet_unholy_strength == nil then modifier_imba_armlet_unholy_strength = class({}) end
function modifier_imba_armlet_unholy_strength:IsHidden() return true end
function modifier_imba_armlet_unholy_strength:IsDebuff() return false end
function modifier_imba_armlet_unholy_strength:IsPurgable() return false end

function modifier_imba_armlet_unholy_strength:GetEffectName()
	return "particles/items_fx/armlet.vpcf" end

function modifier_imba_armlet_unholy_strength:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW end

function modifier_imba_armlet_unholy_strength:DeclareFunctions()
	return {	MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
				MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
				MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_imba_armlet_unholy_strength:OnCreated()
	if IsServer() then


		-- Start thinking
		self:StartIntervalThink(0.1)
	end
end



function modifier_imba_armlet_unholy_strength:OnIntervalThink()
	if IsServer() then
		local parent = self:GetParent()
		local ability = self:GetAbility()

		-- If the parent no longer has the modifier (which means he no longer has an armlet), commit sudoku
		if not parent:HasModifier("modifier_imba_armlet_basic") then
			parent:RemoveModifierByName("modifier_imba_armlet_unholy_strength_visual_effect")
			self:Destroy()
			return
		end

		-- If this is an illusion, do nothing
		if not parent:IsRealHero() then return end

		
		local health_per_sec = ability:GetSpecialValueFor("health_drain")
		local health_per_sec_perc = ability:GetSpecialValueFor("health_drain_perc")/100
		local min_health_perc = ability:GetSpecialValueFor("min_health_perc")/100
		
		if parent:GetHealth() <= parent:GetMaxHealth()*min_health_perc then
			parent:RemoveModifierByName("modifier_imba_armlet_unholy_strength")
			return
		end

		-- Remove health from the owner
		parent:SetHealth(math.max( parent:GetHealth() - (health_per_sec + parent:GetMaxHealth()*health_per_sec_perc) * 0.1, 1))

		-- Calculate stacks to apply
		local unholy_stacks = math.floor((parent:GetMaxHealth() - parent:GetHealth()) / self:GetAbility():GetSpecialValueFor("health_per_stack"))

		-- Update stacks
		self:SetStackCount(unholy_stacks)
	end
end

function modifier_imba_armlet_unholy_strength:GetModifierBonusStats_Strength()			-- Static only
	return self:GetAbility():GetSpecialValueFor("bonus_str_buff")
end

function modifier_imba_armlet_unholy_strength:GetModifierPreAttack_BonusDamage()		-- Static + stacks
	return self:GetAbility():GetSpecialValueFor("bonus_dmg_buff") + self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_dmg_stack")
end

function modifier_imba_armlet_unholy_strength:GetModifierPhysicalArmorBonus()			-- Static + stacks
	return self:GetAbility():GetSpecialValueFor("bonus_armor_buff")
end


-- Toggle prevention
modifier_imba_armlet_toggle_prevention = modifier_imba_armlet_toggle_prevention or class({})

function modifier_imba_armlet_toggle_prevention:IsHidden() return true end
function modifier_imba_armlet_toggle_prevention:IsDebuff() return false end
function modifier_imba_armlet_toggle_prevention:IsPurgable() return false end

-----------------------------------------------------------------------------------------------------------
--  Item Definition
-----------------------------------------------------------------------------------------------------------
if item_imba_agility_armlet == nil then item_imba_agility_armlet = class({}) end
 
function item_imba_agility_armlet:GetAbilityTextureName()
    return "custom/imba_agility_armlet"
end
 
function item_imba_agility_armlet:GetBehavior()
    return DOTA_ABILITY_BEHAVIOR_PASSIVE end
 
function item_imba_agility_armlet:GetIntrinsicModifierName()
    return "modifier_imba_agility_armlet_basic" end
 
function item_imba_agility_armlet:GetAbilityTextureName()
    if self:GetCaster():HasModifier("modifier_imba_agility_armlet_power") then
        return "custom/imba_agility_armlet_active" end
 
    return "custom/imba_agility_armlet"
end

item_imba_armlet = class(item_imba_armlet)
item_imba_armlet_1 = class(item_imba_armlet)
item_imba_armlet_2 = class(item_imba_armlet)
item_imba_armlet_3 = class(item_imba_armlet)
item_imba_armlet_4 = class(item_imba_armlet)
-----------------------------------------------------------------------------------------------------------
--  Basic modifier definition
-----------------------------------------------------------------------------------------------------------

if modifier_imba_agility_armlet_basic == nil then modifier_imba_agility_armlet_basic = class({}) end

function modifier_imba_agility_armlet_basic:IsHidden() return false end
function modifier_imba_agility_armlet_basic:IsDebuff() return false end
function modifier_imba_agility_armlet_basic:IsPurgable() return false end

function modifier_imba_agility_armlet_basic:GetTexture()
    return "items/imba_agility_armlet"
end

function modifier_imba_agility_armlet_basic:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_imba_agility_armlet_basic:OnCreated()
    if IsServer() then
        self:SetStackCount(0)
    end
end

function modifier_imba_agility_armlet_basic:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_imba_agility_armlet_basic:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_dmg") or 0
end
 
function modifier_imba_agility_armlet_basic:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_as") or 0
end
 
function modifier_imba_agility_armlet_basic:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("bonus_str") or 0
end
 
function modifier_imba_agility_armlet_basic:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_agi") or 0
end
 
function modifier_imba_agility_armlet_basic:GetModifierBonusStats_Intellect()
    return self:GetAbility():GetSpecialValueFor("bonus_int") or 0
end

function modifier_imba_agility_armlet_basic:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movespeed_pct") or 0
end
   
function modifier_imba_agility_armlet_basic:OnAttackLanded(keys)
    if keys.attacker ~= self:GetParent() then
        return
    end
   
    if self:GetParent():HasModifier("modifier_imba_agility_armlet_power") then
        return
    end
   
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local stack_required = ability:GetSpecialValueFor("stack_required")
    local buff_duration = ability:GetSpecialValueFor("buff_duration")
   
    self:IncrementStackCount()
   
    if self:GetStackCount() == stack_required then
        self:SetStackCount(0)
        parent:AddNewModifier(parent, ability, "modifier_imba_agility_armlet_power",{duration = buff_duration})
    end   
end
-----------------------------------------------------------------------------------------------------------
--  Unholy Strength modifier definition
-----------------------------------------------------------------------------------------------------------
if modifier_imba_agility_armlet_power == nil then modifier_imba_agility_armlet_power = class({}) end
function modifier_imba_agility_armlet_power:IsHidden() return false end
function modifier_imba_agility_armlet_power:IsDebuff() return false end
function modifier_imba_agility_armlet_power:IsPurgable() return false end

function modifier_imba_agility_armlet_power:GetTexture()
	return "items/imba_agility_armlet_active"
 end
  
function modifier_imba_agility_armlet_power:GetEffectName()
    return "particles/items_fx/agility_armlet/agility_armlet.vpcf" end
 
function modifier_imba_agility_armlet_power:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW end
 
function modifier_imba_agility_armlet_power:DeclareFunctions()
    return {   
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,       }
end
 
function modifier_imba_agility_armlet_power:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_dmg_buff") end
 
function modifier_imba_agility_armlet_power:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_as_buff") end
 
function modifier_imba_agility_armlet_power:GetModifierBonusStats_Agility()
    return self:GetAbility():GetSpecialValueFor("bonus_agi_buff") end

item_imba_agility_armlet = class(item_imba_agility_armlet)
item_imba_agility_armlet_1 = class(item_imba_agility_armlet)
item_imba_agility_armlet_2 = class(item_imba_agility_armlet)
item_imba_agility_armlet_3 = class(item_imba_agility_armlet)
item_imba_agility_armlet_4 = class(item_imba_agility_armlet)
-----------------------------------------------------------------------------------------------------------
--	Item Definition
-----------------------------------------------------------------------------------------------------------
if item_imba_magic_armlet == nil then item_imba_magic_armlet = class({}) end

function item_imba_magic_armlet:GetAbilityTextureName()
	return "custom/imba_armlet"
end

function item_imba_magic_armlet:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_NO_TARGET  end

function item_imba_magic_armlet:GetIntrinsicModifierName()
	return "modifier_item_imba_magic_armlet" end

function item_imba_magic_armlet:OnSpellStart()
	if IsServer() then

		-- Grant or remove the appropriate modifiers
		local caster = self:GetCaster()

		-- If the caster has a toggle prevention, prevent toggling
		if caster:HasModifier("modifier_imba_magic_armlet_toggle_prevention") then
			return nil
		end

		-- Prevent abusers from spamming Armlets.
		caster:AddNewModifier(caster, self, "modifier_imba_magic_armlet_toggle_prevention", {duration = 0.05})

		if caster:HasModifier("modifier_imba_magic_armlet_power") then
			caster:EmitSound("DOTA_Item.Armlet.Activate")
			caster:RemoveModifierByName("modifier_imba_magic_armlet_power")
		else
			caster:EmitSound("DOTA_Item.Armlet.DeActivate")
			caster:AddNewModifier(caster, self, "modifier_imba_magic_armlet_power", {})
		end
	end
end

function item_imba_magic_armlet:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_imba_magic_armlet_power") then
		return "custom/imba_magic_armlet_active" end

	return "custom/imba_magic_armlet"
end

-----------------------------------------------------------------------------------------------------------
--	Basic modifier definition
-----------------------------------------------------------------------------------------------------------
if modifier_item_imba_magic_armlet == nil then modifier_item_imba_magic_armlet = class({}) end
function modifier_item_imba_magic_armlet:IsHidden() return true end
function modifier_item_imba_magic_armlet:IsDebuff() return false end
function modifier_item_imba_magic_armlet:IsPurgable() return false end
function modifier_item_imba_magic_armlet:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_imba_magic_armlet:DeclareFunctions()
	return {	
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_MANACOST_PERCENTAGE,		}
end

function modifier_item_imba_magic_armlet:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_dmg") end

function modifier_item_imba_magic_armlet:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_str") end
	
function modifier_item_imba_magic_armlet:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agi") end
	
function modifier_item_imba_magic_armlet:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_int") end

function modifier_item_imba_magic_armlet:GetModifierSpellAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_spell_amp") end

function modifier_item_imba_magic_armlet:GetModifierPercentageManacost()
	return self:GetAbility():GetSpecialValueFor("bonus_manacost") end


-----------------------------------------------------------------------------------------------------------
--	Unholy Strength modifier definition
-----------------------------------------------------------------------------------------------------------
if modifier_imba_magic_armlet_power == nil then modifier_imba_magic_armlet_power = class({}) end
function modifier_imba_magic_armlet_power:IsHidden() return true end
function modifier_imba_magic_armlet_power:IsDebuff() return false end
function modifier_imba_magic_armlet_power:IsPurgable() return false end

function modifier_imba_magic_armlet_power:DeclareFunctions()
	return {	MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
end

function modifier_imba_magic_armlet_power:GetEffectName()
	return "particles/custom/items_fx/magic_armlet/magic_armlet.vpcf" 
end

function modifier_imba_magic_armlet_power:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW 
end

function modifier_imba_magic_armlet_power:OnCreated()
	if IsServer() then


		self:StartIntervalThink(0.1)
	end
end


function modifier_imba_magic_armlet_power:OnIntervalThink()
	if IsServer() then
		local parent = self:GetParent()
		local ability = self:GetAbility()
		
		-- If the parent no longer has the modifier (which means he no longer has an armlet), commit sudoku
		if not parent:HasModifier("modifier_item_imba_magic_armlet") then
			self:Destroy()
			return
		end

		-- If this is an illusion, do nothing
		if not parent:IsRealHero() then return end

		-- Params
		
		local mana_per_sec = ability:GetSpecialValueFor("mana_drain")
		local mana_per_sec_perc = ability:GetSpecialValueFor("mana_drain_perc")/100
		local min_mana_perc = ability:GetSpecialValueFor("min_mana_perc")/100
		
		if parent:GetMana() <= parent:GetMaxMana()*min_mana_perc then
			parent:RemoveModifierByName("modifier_imba_magic_armlet_power")
			return
		end
		-- Remove health from the owner
		parent:SetMana(math.max( parent:GetMana() - (parent:GetMaxMana()*mana_per_sec_perc + mana_per_sec) * 0.1, 1))


	end
end

function modifier_imba_magic_armlet_power:GetModifierBonusStats_Intellect()			-- Static only
	return self:GetAbility():GetSpecialValueFor("bonus_int_buff")
end

function modifier_imba_magic_armlet_power:GetModifierPreAttack_BonusDamage()		-- Static + stacks
	return self:GetAbility():GetSpecialValueFor("bonus_dmg_buff")
end

function modifier_imba_magic_armlet_power:GetModifierSpellAmplify_Percentage()			-- Static + stacks
	return self:GetAbility():GetSpecialValueFor("bonus_spell_buff") 
end



-- Toggle prevention
modifier_imba_magic_armlet_toggle_prevention = modifier_imba_magic_armlet_toggle_prevention or class({})

function modifier_imba_magic_armlet_toggle_prevention:IsHidden() return true end
function modifier_imba_magic_armlet_toggle_prevention:IsDebuff() return false end
function modifier_imba_magic_armlet_toggle_prevention:IsPurgable() return false end

item_imba_magic_armlet = class(item_imba_magic_armlet)
item_imba_magic_armlet_1 = class(item_imba_magic_armlet)
item_imba_magic_armlet_2 = class(item_imba_magic_armlet)
item_imba_magic_armlet_3 = class(item_imba_magic_armlet)
item_imba_magic_armlet_4 = class(item_imba_magic_armlet)


LinkLuaModifier("modifier_imba_armlet_basic", "items/item_armlet", LUA_MODIFIER_MOTION_NONE, modifier_imba_armlet_basic)
LinkLuaModifier("modifier_imba_armlet_unholy_strength_visual_effect", "items/item_armlet", LUA_MODIFIER_MOTION_NONE,  modifier_imba_armlet_unholy_strength_visual_effect)
LinkLuaModifier("modifier_imba_armlet_unholy_strength", "items/item_armlet", LUA_MODIFIER_MOTION_NONE,  modifier_imba_armlet_unholy_strength)
LinkLuaModifier("modifier_imba_armlet_toggle_prevention", "items/item_armlet", LUA_MODIFIER_MOTION_NONE,  modifier_imba_armlet_toggle_prevention)
LinkLuaModifier("modifier_imba_agility_armlet_basic", "items/item_armlet", LUA_MODIFIER_MOTION_NONE,  modifier_imba_agility_armlet_basic)
LinkLuaModifier("modifier_imba_agility_armlet_power", "items/item_armlet", LUA_MODIFIER_MOTION_NONE,  modifier_imba_agility_armlet_power)
LinkLuaModifier("modifier_item_imba_magic_armlet", "items/item_armlet", LUA_MODIFIER_MOTION_NONE,  modifier_item_imba_magic_armlet)
LinkLuaModifier("modifier_imba_magic_armlet_power", "items/item_armlet", LUA_MODIFIER_MOTION_NONE,  modifier_imba_magic_armlet_power)
LinkLuaModifier("modifier_imba_magic_armlet_toggle_prevention", "items/item_armlet", LUA_MODIFIER_MOTION_NONE,  modifier_imba_magic_armlet_toggle_prevention)
