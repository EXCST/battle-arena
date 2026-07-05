require('items/generic_datadriven_item')


item_cursed_urn = class({
	GetIntrinsicModifierName = function() return 
		"modifier_cursed_urn" 
	end,
	IsRequireBossForCharges = function()
		return true
	end,
	GetBuffParticle = function()
		return "particles/items4_fx/spirit_vessel_heal.vpcf"
	end,
	GetDebuffParticle = function()
		return "particles/items4_fx/spirit_vessel_damage.vpcf"
	end,
	GetCastParticle = function()
		return "particles/items4_fx/spirit_vessel_cast.vpcf"
	end
})

function item_cursed_urn:Precache(context)
	PrecacheResource("particle", self:GetBuffParticle(), context)
	PrecacheResource("particle", self:GetDebuffParticle(), context)
	PrecacheResource("particle", self:GetCastParticle(), context)
end

function item_cursed_urn:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local isTargetAlly = (target:GetTeam() == self:GetCaster():GetTeamNumber())
	target:AddNewModifier(
		caster, 
		self, 
		isTargetAlly == true and "modifier_cursed_urn_buff" or "modifier_cursed_urn_debuff",
		{
			duration = self:GetSpecialValueFor("duration")
		}
	)
	local pfx = ParticleManager:CreateParticle(self:GetCastParticle(), PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlEnt(pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
	ParticleManager:SetParticleControlEnt(pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
	ParticleManager:ReleaseParticleIndex(pfx)
	EmitSoundOn("DOTA_Item.UrnOfShadows.Activate", target)
	self:SpendCharge()
end

modifier_cursed_urn = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	IsPermanent = function() return true end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	} end,
	IsAuraActiveOnDeath = function()
        return false
    end,
    GetAuraRadius = function(self)
        return self.radius
    end,
    GetAuraSearchFlags = function(self)
        return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
    end,
    GetAuraSearchTeam = function(self)
        return DOTA_UNIT_TARGET_TEAM_ENEMY
    end,
    IsAura = function()
        return true
    end,
    GetAuraSearchType = function(self)
        return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    end,
    GetModifierAura = function()
        return "modifier_cursed_urn_kill_checker"
    end,
    GetAuraDuration = function()
        return 0
    end,
	IsRequireBossForCharges = function()
		return true
	end,
	GetAttributes = function()
		return MODIFIER_ATTRIBUTE_MULTIPLE
	end,
	GetModifierBonusStats_Strength = function(self)
		return self.bonusStr
	end,
	GetModifierBonusStats_Agility = function(self)
		return self.bonusAgi
	end,
	GetModifierBonusStats_Intellect = function(self)
		return self.bonusInt
	end
})

function modifier_cursed_urn:OnCreated()
	self.ability = self:GetAbility()
	self.radius = self.ability:GetSpecialValueFor("kill_radius")
	self.killsForCharge = self.ability:GetSpecialValueFor("kills_for_charge")
	self.maxCharges = self.ability:GetSpecialValueFor("max_charges")
	self.chargesPerKills = self.ability:GetSpecialValueFor("charges_for_kill")
	self.bonusStr = self.ability:GetSpecialValueFor("strength")
	self.bonusAgi = self.ability:GetSpecialValueFor("agility")
	self.bonusInt = self.ability:GetSpecialValueFor("intellect")
	self.currentKills = 0
end

function modifier_cursed_urn:CheckChargesForKills()
	self.currentKills = self.currentKills + 1
	if(self.currentKills >= self.killsForCharge) then
		self.ability:SetCurrentCharges(math.min(self.ability:GetCurrentCharges() + self.chargesPerKills, self.maxCharges))
		self.currentKills = 0
	end
end

modifier_cursed_urn_kill_checker = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_EVENT_ON_DEATH
	} end,
})

function modifier_cursed_urn_kill_checker:OnCreated()
	if(not IsServer()) then
		return
	end
	self.ability = self:GetAbility()
	if(not self.ability) then
		self:Destroy()
		return
	end
	self.parent = self:GetParent()
	self.auraModifier = self:GetAuraOwner():FindModifierByName("modifier_cursed_urn")
	if(not self.auraModifier) then
		self:Destroy()
	end
end

function modifier_cursed_urn_kill_checker:OnDeath(keys)
	if(keys.unit ~= self.parent) then
		return
	end
	if(self.ability:IsRequireBossForCharges() == true and keys.unit:IsBoss() == false) then
		return
	end
	self.auraModifier:CheckChargesForKills()
end

modifier_cursed_urn_buff = class({
	IsHidden = function() return false end,
	IsPurgable = function() return true end,
	GetEffectName = function(self) 
		return self.ability:GetBuffParticle() 
	end,
	GetEffectAttachType = function() 
		return PATTACH_ABSORIGIN_FOLLOW 
	end,
})

function modifier_cursed_urn_buff:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	if(not IsServer()) then
		return
	end
	self.heal_per_sec = self.ability:GetSpecialValueFor("heal_per_sec")
	self.heal_per_sec_pct = self.ability:GetSpecialValueFor("heal_per_sec_pct") / 100
	self.interval = self.ability:GetSpecialValueFor("interval")
	self:StartIntervalThink(self.interval)
end

function modifier_cursed_urn_buff:OnIntervalThink()
	self.heal = ((self.parent:GetMaxHealth() * self.heal_per_sec_pct) + self.heal_per_sec ) * self.interval
	self.heal = self.parent:Heal(self.heal, self.ability, DOTA_HEAL_TYPE_HEALING)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self.parent, self.heal, nil)
end

modifier_cursed_urn_debuff = class({
	IsPurgable = function() return true end,
	GetEffectName = function(self) return self.ability:GetDebuffParticle() end,
	GetEffectAttachType = function() return PATTACH_ABSORIGIN_FOLLOW end,
})

function modifier_cursed_urn_debuff:OnCreated()
	self.ability = self:GetAbility()
	if(not IsServer()) then
		return
	end
	self.damage_per_sec = self.ability:GetSpecialValueFor("damage_per_sec")
	self.damage_per_sec_pct = self.ability:GetSpecialValueFor("damage_per_sec_pct") / 100
	self.interval = self.ability:GetSpecialValueFor("interval")
	self:StartIntervalThink(self.interval)
end

function modifier_cursed_urn_debuff:OnIntervalThink()
	local damageOnTick = (self.damage_per_sec * (self:GetCaster():GetSpellAmplification(false) + 1)) + ((self:GetParent():GetHealthPercent() * self:GetParent():GetMaxHealth() / 100) * self.damage_per_sec_pct)
	damageOnTick = damageOnTick * self.interval
	ApplyDamage({
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		ability = self:GetAbility(),
		damage = damageOnTick,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
	})
end

item_rd_urn_of_shadows = class(item_cursed_urn)

function item_rd_urn_of_shadows:IsRequireBossForCharges()
	return false
end

function item_rd_urn_of_shadows:GetBuffParticle()
	return "particles/items2_fx/urn_of_shadows_heal.vpcf"
end

function item_rd_urn_of_shadows:GetDebuffParticle()
	return "particles/items2_fx/urn_of_shadows_damage.vpcf"
end

function item_rd_urn_of_shadows:GetCastParticle()
	return "particles/items2_fx/urn_of_shadows.vpcf"
end


LinkLuaModifier("modifier_cursed_urn", "items/custom/item_cursed_urn", LUA_MODIFIER_MOTION_NONE, modifier_cursed_urn)
LinkLuaModifier("modifier_cursed_urn_buff", "items/custom/item_cursed_urn", LUA_MODIFIER_MOTION_NONE, modifier_cursed_urn_buff)
LinkLuaModifier("modifier_cursed_urn_debuff", "items/custom/item_cursed_urn", LUA_MODIFIER_MOTION_NONE, modifier_cursed_urn_debuff)
LinkLuaModifier("modifier_cursed_urn_kill_checker", "items/custom/item_cursed_urn", LUA_MODIFIER_MOTION_NONE, modifier_cursed_urn_kill_checker)
