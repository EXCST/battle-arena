require('items/generic_datadriven_item')


item_holy_locket_base = class({
	GetIntrinsicModifierName = function() return "modifier_item_holy_locket_custom" end
})

modifier_item_holy_locket_custom = class({
	IsHidden = function() 
		return true 
	end,
	IsPurgeable = function() 
		return false 
	end,
	IsPurgeException = function()
		return false
	end,
	RemoveOnDeath = function()
		return false
	end,
	DeclareFunctions = function() 
		return 
		{
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
			MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
			MODIFIER_PROPERTY_EXTRA_MANA_BONUS
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } 
	end,
	GetModifierExtraManaBonus = function(self)
		return self.bonusMana
	end,
	GetAttributes = function()
		return MODIFIER_ATTRIBUTE_MULTIPLE
	end
})

function modifier_item_holy_locket_custom:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()
	if(not IsServer()) then
		return
	end
	self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_holy_locket_custom_unique", {duration = -1})
end

function modifier_item_holy_locket_custom:OnRefresh()
	self.ability = self:GetAbility() or self.ability
	if(not self.ability) then
		return
	end
	self.bonusHealth = self.ability:GetSpecialValueFor("health")
	self.bonusMana = self.ability:GetSpecialValueFor("mana")
end

function modifier_item_holy_locket_custom:GetModifierBonusHealth()
	return self.bonusHealth
end

function modifier_item_holy_locket_custom:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return self.bonusMana
	end
	return 0
end

function modifier_item_holy_locket_custom:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return 0
	end
	return self.bonusMana
end

function modifier_item_holy_locket_custom:OnDestroy()
	if(not IsServer()) then
		return
	end
	if(self.parent:HasModifier("modifier_item_holy_locket_custom") == false) then
		self.parent:RemoveModifierByName("modifier_item_holy_locket_custom_unique")
	end
end

modifier_item_holy_locket_custom_unique = class({
	IsHidden = function() 
		return true 
	end,
	IsPurgeable = function() 
		return false 
	end,
	IsPurgeException = function()
		return false
	end,
	RemoveOnDeath = function()
		return false
	end,
	DeclareFunctions = function() 
		return 
		{
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } 
	end
})

function modifier_item_holy_locket_custom_unique:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self:OnRefresh()
end

function modifier_item_holy_locket_custom_unique:OnRefresh()
	self.ability = self:GetAbility() or self.ability
	if(not self.ability) then
		return
	end
	self.bonusHealingOutgoing = self.ability:GetSpecialValueFor("healing_amp")
	self.bonusHealthRegenerationPct = self.bonusHealingOutgoing
end

function modifier_item_holy_locket_custom_unique:GetModifierHealCaused_Percentage() 
	if(self.parent:HasModifier("modifier_item_water_rapier")) then
		return 0
	end
	return self.bonusHealingOutgoing 
end

function modifier_item_holy_locket_custom_unique:GetModifierHPRegenAmplify_Percentage() 
	if(self.parent:HasModifier("modifier_item_water_rapier")) then
		return 0
	end
	return self.bonusHealthRegenerationPct 
end

item_rd_holy_locket = class(item_holy_locket_base)


item_staff_of_nature = class(item_holy_locket_base)

function item_staff_of_nature:Precache(context)
	PrecacheResource("particle", "particles/custom/items/staff_of_nature/staff_of_nature_ground.vpcf", context)
	PrecacheResource("particle", "particles/custom/items/staff_of_nature/staff_of_nature_buff.vpcf", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_enchantress.vsndevts", context)
end

function item_staff_of_nature:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function item_staff_of_nature:OnSpellStart()
	if (not IsServer()) then 
		return 
	end
	local caster = self:GetCaster()
	CreateModifierThinker(
		caster, 
		self, 
		"modifier_item_staff_of_nature_thinker", 
		{
			duration = self:GetSpecialValueFor("duration")
		}, 
		self:GetCursorPosition(), 
		caster:GetTeamNumber(), 
		false
	)
end

modifier_item_staff_of_nature_thinker = class({
	IsHidden = function() 
		return true 
	end,
	IsPurgable = function() 
		return false 
	end,
	IsAura = function() 
		return true 
	end,
	GetAuraSearchTeam = function(self) 
		return self.team 
	end,
	GetAuraSearchType = function(self) 
		return self.type 
	end,
	GetAuraSearchFlags = function(self) 
		return self.flags 
	end,
	GetAuraRadius = function(self) 
		return self.radius 
	end,
	GetModifierAura = function() 
		return "modifier_item_staff_of_nature_thinker_buff" 
	end
})

function modifier_item_staff_of_nature_thinker:OnCreated()
	if(not IsServer()) then
		return
	end
	self.thinker = self:GetParent()
	self.ability = self:GetAbility()
	self.radius = self.ability:GetSpecialValueFor("radius")
	self.team = self.ability:GetAbilityTargetTeam()
	self.type = self.ability:GetAbilityTargetType()
	self.flags = self.ability:GetAbilityTargetFlags()
	local pfx = ParticleManager:CreateParticle("particles/custom/items/staff_of_nature/staff_of_nature_ground.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(pfx, 0, self.thinker:GetAbsOrigin())
	ParticleManager:SetParticleControl(pfx, 11, Vector(self.radius, 0, 0))
	self:AddParticle(pfx, false, false, -1, false, false)
	EmitSoundOn("Hero_Enchantress.NaturesAttendantsCast", self.thinker)
end

function modifier_item_staff_of_nature_thinker:OnDestroy()
	if(not IsServer()) then
		return
	end
	StopSoundOn("Hero_Enchantress.NaturesAttendantsCast", self.thinker)
	UTIL_Remove(self.thinker)
end

modifier_item_staff_of_nature_thinker_buff = class({
	IsHidden = function() 
		return false 
	end,
	IsPurgable = function() 
		return false 
	end,
	GetTexture = function(self) 
		return self.buffIcon
	end,
	DeclareFunctions = function() 
		return 
		{
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } 
	end,
	GetModifierConstantHealthRegen = function(self) 
		return self.bonusHealthRegeneration 
	end,
	GetModifierConstantManaRegen = function(self) 
		return self.bonusManaRegeneration 
	end,
	GetEffectName = function()
		return "particles/custom/items/staff_of_nature/staff_of_nature_buff.vpcf"
	end
})

function modifier_item_staff_of_nature_thinker_buff:OnCreated()
	self.ability = self:GetAbility()
	if(not self.ability) then
		self:Destroy()
		return
	end
	if(not IsServer()) then
		self.buffIcon = self.ability:GetAbilityTextureName()
	end
	self.bonusHealthRegeneration = self.ability:GetSpecialValueFor("hp_regen")
	self.bonusManaRegeneration = self.ability:GetSpecialValueFor("mana_regen")
end


LinkLuaModifier("modifier_item_holy_locket_custom", "items/custom/item_holy_locket", LUA_MODIFIER_MOTION_NONE, modifier_item_holy_locket_custom)
LinkLuaModifier("modifier_item_holy_locket_custom_unique", "items/custom/item_holy_locket", LUA_MODIFIER_MOTION_NONE, modifier_item_holy_locket_custom_unique)
LinkLuaModifier("modifier_item_staff_of_nature_thinker", "items/custom/item_holy_locket", LUA_MODIFIER_MOTION_NONE, modifier_item_staff_of_nature_thinker)
LinkLuaModifier("modifier_item_staff_of_nature_thinker_buff", "items/custom/item_holy_locket", LUA_MODIFIER_MOTION_NONE, modifier_item_staff_of_nature_thinker_buff)
