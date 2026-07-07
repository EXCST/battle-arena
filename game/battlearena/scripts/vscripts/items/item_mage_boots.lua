require('items/generic_datadriven_item')


item_mage_boots = class({
    GetIntrinsicModifierName = function() return "modifier_item_mage_boots" end
})
function item_mage_boots:OnSpellStart()
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_item_mage_boots_active", {duration = self:GetSpecialValueFor("duration")})
    local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_keeper_of_the_light/keeper_chakra_magic.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControl(pfx, 0, self:GetCaster():GetAbsOrigin())
    ParticleManager:SetParticleControl(pfx, 1, self:GetCaster():GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(pfx)
    EmitSoundOn("Hero_KeeperOfTheLight.ChakraMagic.Target", self:GetCaster())
end

modifier_item_mage_boots = class({
    IsHidden = function() return true end,
    IsItem = function() return true end,
    IsPurgable = function() return false end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT_UNIQUE,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
    } end,
    GetModifierMoveSpeedBonus_Constant_Unique = function(self) return self.bonus_ms end,
    GetModifierBonusStats_Intellect = function(self) return self.bonus_int end
})

function modifier_item_mage_boots:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self.bonus_ms = self:GetAbility():GetSpecialValueFor("bonus_ms")
    self.bonus_int = self:GetAbility():GetSpecialValueFor("bonus_int")
    self:OnRefresh()
end

function modifier_item_mage_boots:OnRefresh()
    if self.ability:GetLevel() == 3 then
        self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_boots_of_travel", nil)
    elseif self.ability:GetLevel() > 3 then
        self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_boots_of_travel_2", nil)
    end
end

function modifier_item_mage_boots:OnDestroy()
    if self.ability:GetLevel() == 3 then
        self.parent:RemoveModifierByName("modifier_item_boots_of_travel")
    elseif self.ability:GetLevel() > 3 then
        self.parent:RemoveModifierByName("modifier_item_boots_of_travel_2")
    end
end
modifier_item_mage_boots_active = class({
    IsHidden = function() return false end,
    IsPurgable = function() return true end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
    } end,
    GetModifierSpellAmplify_Percentage = function(self) return self.spell_amp end
})

function modifier_item_mage_boots_active:OnCreated()
    self.spell_amp = self:GetAbility():GetSpecialValueFor("spell_amp")
end

item_mage_boots_1 = class(item_mage_boots)
item_mage_boots_2 = class(item_mage_boots)
item_mage_boots_3 = class(item_mage_boots)
item_mage_boots_4 = class(item_mage_boots)


LinkLuaModifier("modifier_item_mage_boots", "items/item_mage_boots", 0, modifier_item_mage_boots)
LinkLuaModifier("modifier_item_mage_boots_active", "items/item_mage_boots", 0, modifier_item_mage_boots_active)
