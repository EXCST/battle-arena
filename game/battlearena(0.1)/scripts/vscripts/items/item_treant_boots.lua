require('items/generic_datadriven_item')


item_treant_boots = class({
    GetIntrinsicModifierName = function() return "modifier_item_treant_boots" end
})

function item_treant_boots:GetAbilityTextureName()
    local name = self:GetName()
    local IsActive = self:GetCaster():HasModifier("modifier_item_treant_boots_active")
    if name == "item_treant_boots_1" then
        return IsActive and "boots/treant_boots_active_1" or "boots/treant_boots_inactive_1"
    elseif name == "item_treant_boots_2" then
        return IsActive and "boots/treant_boots_active_2" or "boots/treant_boots_inactive_2"
    elseif name == "item_treant_boots_3" then
        return IsActive and "boots/treant_boots_active_3" or "boots/treant_boots_inactive_3"
    elseif name == "item_treant_boots_4" then
        return IsActive and "boots/treant_boots_active_4" or "boots/treant_boots_inactive_4"
    end
end

function item_treant_boots:OnToggle()
    if self:GetToggleState() then
        self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_item_treant_boots_active", nil)
        self:EndCooldown()
        EmitSoundOn("Hero_DarkWillow.Brambles.CastTarget", self:GetCaster())
    else
        self:GetCaster():RemoveModifierByName("modifier_item_treant_boots_active")
        self:UseResources(false, false, false, true)
    end
end

modifier_item_treant_boots = class({
    IsHidden = function() return true end,
    IsPurgable = function() return false end,
    IsItem = function() return true end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT_UNIQUE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    } end,
    GetModifierMoveSpeedBonus_Constant_Unique = function(self) return self.ms_bonus end,
    GetModifierPhysicalArmorBonus = function(self) return self.armor_bonus end,
})

function modifier_item_treant_boots:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self.ms_bonus = self:GetAbility():GetSpecialValueFor("ms_bonus")
    self.armor_bonus = self:GetAbility():GetSpecialValueFor("armor_bonus")
    self:OnRefresh()
--    self.block = self:GetAbility():GetSpecialValueFor("block")
end

function modifier_item_treant_boots:OnRefresh()
    if self.ability:GetLevel() == 3 then
        self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_boots_of_travel", nil)
    elseif self.ability:GetLevel() > 3 then
        self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_boots_of_travel_2", nil)
    end
end

function modifier_item_treant_boots:OnDestroy()
    if self:GetCaster():HasModifier("modifier_item_treant_boots_active") then
        self:GetCaster():RemoveModifierByName("modifier_item_treant_boots_active")
    end
    if self.ability:GetLevel() == 3 then
        self.parent:RemoveModifierByName("modifier_item_boots_of_travel")
    elseif self.ability:GetLevel() > 3 then
        self.parent:RemoveModifierByName("modifier_item_boots_of_travel_2")
    end
end

modifier_item_treant_boots_active = class({
    IsPurgable = function() return false end,
    RemoveOnDeath = function() return true end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
    } end,
    CheckState = function() return {
        [MODIFIER_STATE_ROOTED] = true
    } end,
    GetModifierPhysicalArmorBonus = function(self) return self.active_armor_bonus+ self.active_armor_per_stack*self:GetStackCount() end,
    GetModifierConstantHealthRegen = function(self) return self.active_hp_regen + self.active_hp_regen_per_stack*self:GetStackCount() end,
    GetEffectName = function() return "particles/econ/items/treant_protector/treant_ti10_immortal_head/treant_ti10_immortal_overgrowth_root_small.vpcf" end,
    GetEffectAttachType = function() return PATTACH_ABSORIGIN_FOLLOW end,
    GetTexture = function(self) return self:GetAbility():GetAbilityTextureName() end
})

function modifier_item_treant_boots_active:OnCreated()
    self.parent = self:GetParent()
    self.active_hp_regen = self:GetAbility():GetSpecialValueFor("active_hp_regen")
    self.active_hp_regen_per_stack = self:GetAbility():GetSpecialValueFor("active_hp_regen_per_stack")
    self.active_armor_bonus = self:GetAbility():GetSpecialValueFor("active_armor_bonus")
    self.active_armor_per_stack = self:GetAbility():GetSpecialValueFor("active_armor_per_stack")
    self.active_max_stack = self:GetAbility():GetSpecialValueFor("active_max_stack")

    self:StartIntervalThink(1)
end

function modifier_item_treant_boots_active:OnIntervalThink()
    if(self.parent:HasModifier("modifier_item_treant_boots") == false) then
        return
    end
    
    if self:GetStackCount() < self.active_max_stack then
        self:SetStackCount(math.min(self:GetStackCount()+1, self.active_max_stack))
    end
end

item_treant_boots_1 = class(item_treant_boots)
item_treant_boots_2 = class(item_treant_boots)
item_treant_boots_3 = class(item_treant_boots)
item_treant_boots_4 = class(item_treant_boots)


LinkLuaModifier("modifier_item_treant_boots", "items/item_treant_boots", 0, modifier_item_treant_boots)
LinkLuaModifier("modifier_item_treant_boots_active", "items/item_treant_boots", 0, modifier_item_treant_boots_active)
