require('items/generic_datadriven_item')

item_midas_armlet = class({})

function item_midas_armlet:GetIntrinsicModifierName()
	return "modifier_item_midas_armlet"
end

function item_midas_armlet:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")

	caster:AddNewModifier(caster, self, "modifier_item_midas_armlet_buff", {duration = duration})
end

modifier_item_midas_armlet = class({
	IsHidden 				= function(self) return true end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_EVENT_ON_DEATH
		} 
	end,
})

function modifier_item_midas_armlet:OnDeath(data)
    local parent = self:GetParent()
	local attacker = data.attacker
	local unit = data.unit
	local flDamage = data.damage

    if attacker == parent then 
	    local ability = self:GetAbility()
		local player = PlayerResource:GetPlayer(attacker:GetPlayerID())
		local playerHero = PlayerResource:GetSelectedHeroEntity(attacker:GetPlayerID())

		local gold_per_kill = ability:GetSpecialValueFor("gold_per_kill")
		local bonus_gold_pct = (ability:GetSpecialValueFor("bonus_gold_pct")-100)/100
--		local bonus_xp = (ability:GetSpecialValueFor("bonus_xp")+100)/100

		if parent:HasModifier("modifier_item_midas_armlet_buff") then
			local gold = unit:GetGoldBounty()*bonus_gold_pct+gold_per_kill
--			local xp = unit:GetDeathXP()*bonus_xp

--			playerHero:AddExperience(xp, 0, false, true )
			playerHero:ModifyGoldFiltered(gold, false, DOTA_ModifyGold_CreepKill)
			SendOverheadEventMessage( player, OVERHEAD_ALERT_GOLD, playerHero, gold, nil )
			
			local effect = "particles/econ/items/alchemist/alchemist_midas_knuckles/alch_knuckles_lasthit_coins.vpcf"
			local particle_fx = ParticleManager:CreateParticle(effect, PATTACH_ABSORIGIN_FOLLOW, unit)
			ParticleManager:SetParticleControl(particle_fx, 0, unit:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle_fx, 1, unit:GetAbsOrigin())


			ParticleManager:ReleaseParticleIndex(particle_fx)
			unit:EmitSound("DOTA_Item.Hand_Of_Midas")
		else
			local gold = gold_per_kill

			playerHero:ModifyGoldFiltered(gold, false, DOTA_ModifyGold_CreepKill)
			SendOverheadEventMessage( player, OVERHEAD_ALERT_GOLD, playerHero, gold, nil )			
		end	
   end
end

function modifier_item_midas_armlet:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

modifier_item_midas_armlet_buff = class({
	IsHidden 				= function(self) return false end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return true end,
})

item_midas_armlet_1 = class(item_midas_armlet)
item_midas_armlet_2 = class(item_midas_armlet)
item_midas_armlet_3 = class(item_midas_armlet)
item_midas_armlet_4 = class(item_midas_armlet)


LinkLuaModifier("modifier_item_midas_armlet", "items/custom/item_midas_armlet", LUA_MODIFIER_MOTION_NONE ,  modifier_item_midas_armlet)
LinkLuaModifier("modifier_item_midas_armlet_buff", "items/custom/item_midas_armlet", LUA_MODIFIER_MOTION_NONE ,  modifier_item_midas_armlet_buff)
