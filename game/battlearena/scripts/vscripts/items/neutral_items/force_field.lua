item_force_field_custom = class({
    GetCastRange = function(self)
        return self:GetSpecialValueFor("bonus_aoe_radius")
    end,
    GetIntrinsicModifierName = function()
        return "modifier_item_force_field_custom_aura"
    end
})

function item_force_field_custom:Precache(context)
    PrecacheResource("particle", "particles/items5_fx/force_field.vpcf", context)
end

function item_force_field_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local buffDuration = self:GetSpecialValueFor("duration")
    local allies = FindUnitsInRadius(
        caster:GetTeamNumber(), 
        caster:GetAbsOrigin(), 
        nil, 
        self:GetCastRange(), 
        self:GetAbilityTargetTeam(), 
        self:GetAbilityTargetType(), 
        self:GetAbilityTargetFlags(), 
        FIND_ANY_ORDER, 
        false
    )
    for _, ally in pairs(allies) do
        ally:AddNewModifier(caster, self, "modifier_item_force_field_custom_buff", {duration = buffDuration})
    end
    EmitSoundOn("Item.ArcanistArmor.Cast", caster)
end

modifier_item_force_field_custom_aura = class({
    IsHidden = function() 
        return true 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        }
    end,
    GetModifierMagicalResistanceBonus = function(self)
        return self.bonusSpellResistance
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end,
    IsAuraActiveOnDeath = function()
        return false
    end,
    GetAuraRadius = function(self)
        return self.radius
    end,
    GetAuraSearchFlags = function(self)
        return self.targetFlags
    end,
    GetAuraSearchTeam = function(self)
        return self.targetTeam
    end,
    IsAura = function()
        return true
    end,
    GetAuraSearchType = function(self)
        return self.targetType
    end,
    GetModifierAura = function()
        return "modifier_item_force_field_custom_aura_buff"
    end,
    GetAuraDuration = function()
        return 0
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_force_field_custom_aura:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
end

function modifier_item_force_field_custom_aura:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusSpellResistance = self.ability:GetSpecialValueFor("self_mres")
    self.bonusArmor = self.ability:GetSpecialValueFor("self_armor")
    self.radius = self.ability:GetCastRange()
end

function modifier_item_force_field_custom_aura:GetAuraEntityReject(npc)
    return npc == self.parent
end

modifier_item_force_field_custom_aura_buff = class({
    IsHidden = function() 
        return false 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        }
    end,
    GetModifierMagicalResistanceBonus = function(self)
        return self.bonusSpellResistance
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end
})

function modifier_item_force_field_custom_aura_buff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_force_field_custom_aura_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusArmor = self.ability:GetSpecialValueFor("bonus_aoe_armor")
    self.bonusSpellResistance = self.ability:GetSpecialValueFor("bonus_aoe_mres")
end

modifier_item_force_field_custom_buff = class({
    IsHidden = function() 
        return false 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_EVENT_ON_TAKEDAMAGE,
            MODIFIER_PROPERTY_TOOLTIP
        }
    end,
    OnTooltip = function(self)
        return self.reflectionPct * 100
    end,
    GetEffectName = function()
        return "particles/items5_fx/force_field.vpcf"
    end,
    GetEffectAttachType = function()
        return PATTACH_OVERHEAD_FOLLOW
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_force_field_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.damageTable = {
		victim = nil,
		attacker = self.parent,
		damage = 0,
		damage_type = nil,
		ability = self.ability,
		damage_flags = DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
	}
end

function modifier_item_force_field_custom_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.reflectionPct = self.ability:GetSpecialValueFor("active_reflection_pct") / 100
end

function modifier_item_force_field_custom_buff:OnTakeDamage(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    if(bit.band(kv.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION) then
        return
    end
    if(kv.attacker:GetTeamNumber() == self.parent:GetTeamNumber()) then
        return
    end
    self.damageTable.victim = kv.attacker
    self.damageTable.damage = kv.original_damage * self.reflectionPct
    self.damageTable.damage_type = kv.damage_type
    ApplyDamage(self.damageTable)
end

LinkLuaModifier("modifier_item_force_field_custom_aura", "items/neutral_items/force_field", LUA_MODIFIER_MOTION_NONE, modifier_item_force_field_custom_aura)
LinkLuaModifier("modifier_item_force_field_custom_aura_buff", "items/neutral_items/force_field", LUA_MODIFIER_MOTION_NONE, modifier_item_force_field_custom_aura_buff)
LinkLuaModifier("modifier_item_force_field_custom_buff", "items/neutral_items/force_field", LUA_MODIFIER_MOTION_NONE, modifier_item_force_field_custom_buff)