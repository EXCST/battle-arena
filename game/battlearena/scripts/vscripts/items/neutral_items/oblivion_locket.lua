item_oblivion_locket_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_oblivion_locket_custom_aura"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("aura_radius")
    end
})

modifier_item_oblivion_locket_custom_aura = class({
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
        return "modifier_item_oblivion_locket_custom_aura_buff"
    end,
    GetAuraDuration = function()
        return 0
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_oblivion_locket_custom_aura:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	self.targetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
	self.targetFlags = DOTA_UNIT_TARGET_FLAG_NONE
    self.enemyAura = self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_oblivion_locket_custom_aura_enemy", {duration = -1})
end

function modifier_item_oblivion_locket_custom_aura:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.radius = self.ability:GetCastRange()
end

function modifier_item_oblivion_locket_custom_aura:OnDestroy()
    if(not IsServer()) then
        return
    end
    if(self.enemyAura) then
        self.enemyAura:Destroy()
    end
end

modifier_item_oblivion_locket_custom_aura_buff = class({
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
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
        }
    end,
    GetModifierConstantHealthRegen = function(self)
        return self.bonusHealthRegeneration
    end
})

function modifier_item_oblivion_locket_custom_aura_buff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_oblivion_locket_custom_aura_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealthRegeneration = self.ability:GetSpecialValueFor("aura_health_regen_allies")
end

modifier_item_oblivion_locket_custom_aura_enemy = class({
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
        return "modifier_item_oblivion_locket_custom_aura_enemy_debuff"
    end,
    GetAuraDuration = function()
        return 0
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_oblivion_locket_custom_aura_enemy:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	self.targetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
	self.targetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_item_oblivion_locket_custom_aura_enemy:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.radius = self.ability:GetCastRange()
end

modifier_item_oblivion_locket_custom_aura_enemy_debuff = class({
    IsHidden = function() 
        return false 
    end,
    IsDebuff = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        }
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end
})

function modifier_item_oblivion_locket_custom_aura_enemy_debuff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_oblivion_locket_custom_aura_enemy_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusArmor = self.ability:GetSpecialValueFor("aura_disarmor_enemies") * -1
end


LinkLuaModifier("modifier_item_oblivion_locket_custom_aura", "items/neutral_items/oblivion_locket", LUA_MODIFIER_MOTION_NONE, modifier_item_oblivion_locket_custom_aura)
LinkLuaModifier("modifier_item_oblivion_locket_custom_aura_buff", "items/neutral_items/oblivion_locket", LUA_MODIFIER_MOTION_NONE, modifier_item_oblivion_locket_custom_aura_buff)
LinkLuaModifier("modifier_item_oblivion_locket_custom_aura_enemy", "items/neutral_items/oblivion_locket", LUA_MODIFIER_MOTION_NONE, modifier_item_oblivion_locket_custom_aura_enemy)
LinkLuaModifier("modifier_item_oblivion_locket_custom_aura_enemy_debuff", "items/neutral_items/oblivion_locket", LUA_MODIFIER_MOTION_NONE, modifier_item_oblivion_locket_custom_aura_enemy_debuff)
