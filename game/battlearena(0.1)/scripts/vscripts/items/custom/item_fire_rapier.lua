require('items/generic_datadriven_item')

require('items/custom/item_base_rapier')

item_fire_rapier = class(item_base_rapier)


function item_fire_rapier:GetIntrinsicModifierName()
	return "modifier_item_item_fire_rapier"
end

function item_fire_rapier:ApplyItemContainerEffects(itemContainer)
	itemContainer:SetRenderColor(255, 69, 0)
end

function item_fire_rapier:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_item_item_fire_rapier_buff" , {duration = self:GetSpecialValueFor("buff_duration") })
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_sven/sven_spell_gods_strength.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:ReleaseParticleIndex(particle)
	EmitSoundOn("Hero_EmberSpirit.FireRemnant.Cast", caster)
end

modifier_item_item_fire_rapier = class(modifier_item_base_rapier)

function modifier_item_item_fire_rapier:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK
	}
end
	
function modifier_item_item_fire_rapier:GetEffectName()
	return "particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf"
end

function modifier_item_item_fire_rapier:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_item_fire_rapier:OnOwnerHaveMoreThanOneRapierType(owner, item)
	GameRules:SendCustomMessage("#Game_notification_fire_rapier_request_message1",0,0)
	self:DropRapier(owner, item)
end

function modifier_item_item_fire_rapier:OnOwnerHaveInsufficientStats(owner, item, insufficientStats)
	GameRules:SendCustomMessage("#Game_notification_fire_rapier_request_message",0,0)	
	GameRules:SendCustomMessage("<font color='#FFD700'>MISSING ATTRIBUTES: </font><font color='#FF4500'>".. insufficientStats .."</font>",0,0)
	self:DropRapier(owner, item)
end

function modifier_item_item_fire_rapier:OnRapierAddedToInventory()
	self.parent = self:GetParent()
	self.item = self:GetAbility()
	self.procChance = self.item:GetSpecialValueFor("proc_chance")
	self.damagePct = self.item:GetSpecialValueFor("dmg_perc") / 100
	self.debuffDuration = self.item:GetSpecialValueFor("debuff_duration")
	self.fireRapierSplitShotTargetsCap = self.item:GetSpecialValueFor("ranged_split_shot")
	self.fireRapierSplitShotDamagePct = self.item:GetSpecialValueFor("ranged_split_shot_dmg_pct") - 100
	self.fireRapierBonusAttackRange = self.item:GetSpecialValueFor("ranged_split_shot_attack_range")
end

function modifier_item_item_fire_rapier:OnAttackLanded(kv)
	if(kv.attacker ~= self.parent or self.parent:IsIllusion()) then
		return
	end
	if(kv.attacker:GetAttackCapability() == DOTA_UNIT_CAP_MELEE_ATTACK) then
		DoCleaveAttack(
			self.parent, 
			kv.target, 
			self.item, 
			self.damagePct * kv.original_damage, 
			100, 
			500, 
			500, 
			"particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave_gods_strength_crit.vpcf"
		)
	end
	if(RollPseudoRandom(self.procChance, self.item) == false) then
		return
	end
	kv.target:AddNewModifier(self.parent, self.item, "modifier_item_item_fire_rapier_debuff" , {duration = self.debuffDuration})
end

function modifier_item_item_fire_rapier:OnAttack(kv)
	if(kv.attacker ~= self.parent) then
		return
	end
	if(kv.no_attack_cooldown == true) then
		return
	end
	if(kv.attacker:GetAttackCapability() == DOTA_UNIT_CAP_MELEE_ATTACK) then
		return
	end
	local enemies = FindUnitsInRadius(
		self.parent:GetTeamNumber(),
		self.parent:GetAbsOrigin(),
		nil,
		self.parent:Script_GetAttackRange() + self.fireRapierBonusAttackRange,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE,
		FIND_ANY_ORDER,
		false
	)
	local modifier = self.parent:AddNewModifier(self.parent, self.item, "modifier_item_item_fire_rapier_caster_split_shot" , {duration = -1})
	modifier:SetStackCount(self.fireRapierSplitShotDamagePct)
	local damagedEnemies = 0
	for _, enemy in pairs(enemies) do
		if (enemy ~= kv.target) then
			self.parent:PerformAttack(enemy, false, false, true, false, true, false, false)
			damagedEnemies = damagedEnemies + 1
			if (damagedEnemies >= self.fireRapierSplitShotTargetsCap) then
				break
			end
		end
	end
	self.parent:RemoveModifierByName("modifier_item_item_fire_rapier_caster_split_shot")
end

function modifier_item_item_fire_rapier:OnProcessCleave(kv)
	if(kv.inflictor ~= self.item) then
		return
	end
	self.parent:EmitSound("Hero_PhantomAssassin.CoupDeGrace")
end

modifier_item_item_fire_rapier_debuff = class({
	IsHidden = function()
		return false
	end,
	IsPurgable = function()
		return true
	end,
	IsDebuff = function()
		return true
	end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
		}
	end,
	GetTexture = function(self)
		return self.icon
	end
})

function modifier_item_item_fire_rapier_debuff:OnCreated()
	self.armorReductionPerStack = 0
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self:OnRefresh()
	if(not IsServer()) then
		self.icon = self.ability:GetAbilityTextureName()
	end
end

function modifier_item_item_fire_rapier_debuff:OnRefresh()
	self.ability = self:GetAbility() or self.ability
    if(not self.ability) then
        return
    end
	self.armorReductionPerStack = self.ability:GetSpecialValueFor("armor_penalty")
	if(not IsServer()) then
		return
	end
	self:IncrementStackCount()
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_burn_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
    self:AddParticle(particle, false, false, 1, false, false)
	Timers:CreateTimer(self:GetDuration(), function()
        if(self and not self:IsNull()) then
            ParticleManager:DestroyParticle(particle, false)
            ParticleManager:ReleaseParticleIndex(particle)
            self:DecrementStackCount()
        end
	end, self)
end

function modifier_item_item_fire_rapier_debuff:GetModifierPhysicalArmorBonus()
	return self:GetStackCount() * self.armorReductionPerStack
end

modifier_item_item_fire_rapier_buff = class({
	IsHidden = function()
		return false
	end,
	IsPurgable = function()
		return true
	end,
	IsDebuff = function()
		return false
	end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
			MODIFIER_PROPERTY_IGNORE_PHYSICAL_ARMOR
		}
	end,
	GetModifierBaseDamageOutgoing_Percentage = function(self)
		return self:GetAbility():GetSpecialValueFor("buff_dmg")
	end,
	GetModifierIgnorePhysicalArmor = function()
		return 1
	end
})

function modifier_item_item_fire_rapier_buff:GetStatusEffectName()
	return "particles/status_fx/status_effect_gods_strength.vpcf"
end

function modifier_item_item_fire_rapier_buff:StatusEffectPriority()
	return 5
end

modifier_item_item_fire_rapier_caster_split_shot = class({
	IsHidden = function()
		return true
	end,
	IsPurgable = function()
		return false
	end,
	IsDebuff = function()
		return false
	end,
	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
		}
	end,
	GetModifierBaseDamageOutgoing_Percentage = function(self)
		return self:GetStackCount()
	end
})

item_fire_rapier_1 = class(item_fire_rapier)
item_fire_rapier_2 = class(item_fire_rapier)
item_fire_rapier_3 = class(item_fire_rapier)
item_fire_rapier_4 = class(item_fire_rapier)

LinkLuaModifier("modifier_item_item_fire_rapier", "items/custom/item_fire_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_item_fire_rapier)
LinkLuaModifier("modifier_item_item_fire_rapier_buff", "items/custom/item_fire_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_item_fire_rapier_buff)
LinkLuaModifier("modifier_item_item_fire_rapier_debuff", "items/custom/item_fire_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_item_fire_rapier_debuff)
LinkLuaModifier("modifier_item_item_fire_rapier_caster_split_shot", "items/custom/item_fire_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_item_fire_rapier_caster_split_shot)
