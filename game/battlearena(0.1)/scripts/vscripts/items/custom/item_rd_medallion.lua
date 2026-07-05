require('items/generic_datadriven_item')


rd_medallion = class({
	GetIntrinsicModifierName = function() 
		return "modifier_rd_medallion" 
	end,
	GetBuffParticle = function()
		return "particles/items2_fx/medallion_of_courage_friend.vpcf"
	end,
	GetDebuffParticle = function()
		return "particles/items2_fx/medallion_of_courage.vpcf"
	end
})

function rd_medallion:Precache(context)
	PrecacheResource("particle", self:GetBuffParticle(), context)
	PrecacheResource("particle", self:GetDebuffParticle(), context)
end

function rd_medallion:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if target:GetTeam() == caster:GetTeam() then
		target:AddNewModifier(caster, self, "modifier_rd_medallion_buff", {duration = self:GetSpecialValueFor("duration")})
	else
		target:AddNewModifier(caster, self, "modifier_rd_medallion_debuff", {duration = self:GetSpecialValueFor("duration")})
	end
	caster:AddNewModifier(caster, self, "modifier_rd_medallion_caster_debuff", {duration = self:GetSpecialValueFor("duration")})
	target:EmitSound("DOTA_Item.MedallionOfCourage.Activate")
end

modifier_rd_medallion = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	IsPermanent = function() return true end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_PERCENTAGE,
        } end
})

function modifier_rd_medallion:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("armor")
end

function modifier_rd_medallion:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attack_speed")
end

function modifier_rd_medallion:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movement_speed_pct")
end

function modifier_rd_medallion:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("strength")
end

function modifier_rd_medallion:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("attack_damage")
end

modifier_rd_medallion_buff = class({
	IsPurgable = function() return true end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ROSHDEF_EVASION_CONSTANT
	
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_PERCENTAGE,
        } end,
	IsDebuff = function()
		return false
	end,
	GetModifierPhysicalArmorBonus = function(self) return self.armor_bonus end,
	GetModifierAttackSpeed_Percentage = function(self) return self.as_bonus_pct end,
	GetModifierMoveSpeedBonus_Percentage = function(self) return self.ms_bonus_pct end,
	GetModifierEvasion_Constant = function(self) return self.evasion_bonus end
})

function modifier_rd_medallion_buff:OnCreated()
	self.armor_bonus = self:GetAbility():GetSpecialValueFor("armor_bonus")
	self.as_bonus_pct = self:GetAbility():GetSpecialValueFor("as_bonus_pct")
	self.ms_bonus_pct = self:GetAbility():GetSpecialValueFor("ms_bonus_pct")
	self.evasion_bonus = self:GetAbility():GetSpecialValueFor("evasion_bonus") or 0
	if(not IsServer()) then
		return
	end
	local particle = ParticleManager:CreateParticle(self:GetAbility():GetBuffParticle(), PATTACH_OVERHEAD_FOLLOW, self:GetParent())
	self:AddParticle(particle, true, false, 1, false, true)
end


modifier_rd_medallion_debuff = class({
	IsPurgable = function() return true end,
	CheckState = function(self) return {
		[MODIFIER_STATE_DISARMED] = self.isDisarm
	} end,
	IsDebuff = function()
		return true
	end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ROSHDEF_EVASION_CONSTANT
	
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_PERCENTAGE,
        } end,
	GetModifierPhysicalArmorBonus = function(self) return -self.armor_bonus end,
	GetModifierAttackSpeed_Percentage = function(self) return -self.as_bonus_pct end,
	GetModifierMoveSpeedBonus_Percentage = function(self) return -self.ms_bonus_pct end,
	GetModifierEvasion_Constant = function(self) return -self.evasion_decrease end
})

function modifier_rd_medallion_debuff:OnCreated()
	self.armor_bonus = self:GetAbility():GetSpecialValueFor("armor_bonus")
	self.as_bonus_pct = self:GetAbility():GetSpecialValueFor("as_bonus_pct")
	self.ms_bonus_pct = self:GetAbility():GetSpecialValueFor("ms_bonus_pct")
	self.evasion_decrease = self:GetAbility():GetSpecialValueFor("evasion_decrease") or 0
	if(not IsServer()) then
		return
	end
	local particle = ParticleManager:CreateParticle(self:GetAbility():GetDebuffParticle(), PATTACH_OVERHEAD_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(particle, 1, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
	self:AddParticle(particle, true, false, 1, false, true)
	if(self:GetAbility():GetSpecialValueFor("has_disarm") == 1) then
		local particle = ParticleManager:CreateParticle("particles/items2_fx/heavens_halberd.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		self:AddParticle(particle, false, false, 1, false, true)
		self.isDisarm = true
	else
		self.isDisarm = false
	end
end


modifier_rd_medallion_caster_debuff = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	IsDebuff = function()
		return true
	end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ROSHDEF_EVASION_CONSTANT
	
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_PERCENTAGE,
        } end,
	GetModifierPhysicalArmorBonus = function(self) return -self.armor_bonus end,
	GetModifierAttackSpeed_Percentage = function(self) return -self.as_bonus_pct end,
	GetModifierMoveSpeedBonus_Percentage = function(self) return -self.ms_bonus_pct end,
	GetModifierEvasion_Constant = function(self) return -self.evasion_decrease end
})

function modifier_rd_medallion_caster_debuff:OnCreated()
	self.armor_bonus = self:GetAbility():GetSpecialValueFor("armor_bonus")
	self.as_bonus_pct = self:GetAbility():GetSpecialValueFor("as_bonus_pct")
	self.ms_bonus_pct = self:GetAbility():GetSpecialValueFor("ms_bonus_pct")
	self.evasion_decrease = self:GetAbility():GetSpecialValueFor("evasion_decrease") or 0
	if(not IsServer()) then
		return
	end
	local particle = ParticleManager:CreateParticle(self:GetAbility():GetDebuffParticle(), PATTACH_OVERHEAD_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(particle, 1, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
	self:AddParticle(particle, true, false, 1, false, true)
end

item_medallion = class(rd_medallion)
item_rd_solar_crest = class(rd_medallion)

function item_rd_solar_crest:GetBuffParticle()
	return "particles/items3_fx/star_emblem_friend.vpcf"
end

function item_rd_solar_crest:GetDebuffParticle()
	return "particles/items3_fx/star_emblem.vpcf"
end


LinkLuaModifier("modifier_rd_medallion", "items/custom/item_rd_medallion", LUA_MODIFIER_MOTION_NONE, modifier_rd_medallion)
LinkLuaModifier("modifier_rd_medallion_buff", "items/custom/item_rd_medallion", LUA_MODIFIER_MOTION_NONE, modifier_rd_medallion_buff)
LinkLuaModifier("modifier_rd_medallion_debuff", "items/custom/item_rd_medallion", LUA_MODIFIER_MOTION_NONE, modifier_rd_medallion_debuff)
LinkLuaModifier("modifier_rd_medallion_caster_debuff", "items/custom/item_rd_medallion", LUA_MODIFIER_MOTION_NONE, modifier_rd_medallion_caster_debuff)
