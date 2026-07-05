modifier_item_death_shield = class({})

function modifier_item_death_shield:IsHidden() return true end
function modifier_item_death_shield:IsPurgable() return false end
function modifier_item_death_shield:DestroyOnExpire() return false end
function modifier_item_death_shield:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_death_shield:OnCreated(kv)
    local ability = self:GetAbility()
    if not ability then return end
    self.bonus_health    = ability:GetSpecialValueFor("bonus_health")
    self.bonus_hpregen   = ability:GetSpecialValueFor("bonus_hpregen")
    self.block_damage    = ability:GetSpecialValueFor("block_damage")
    self.bonus_armor     = ability:GetSpecialValueFor("bonus_armor")
end

modifier_item_death_shield.OnRefresh = modifier_item_death_shield.OnCreated

function modifier_item_death_shield:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function modifier_item_death_shield:GetModifierExtraHealthBonus() return self.bonus_health or 0 end
function modifier_item_death_shield:GetModifierConstantHealthRegen() return self.bonus_hpregen or 0 end
function modifier_item_death_shield:GetModifierPhysical_ConstantBlock() return self.block_damage or 0 end
function modifier_item_death_shield:GetModifierPhysicalArmorBonus() return self.bonus_armor or 0 end
