modifier_item_lightning_flash = class({})

function modifier_item_lightning_flash:IsHidden() return true end
function modifier_item_lightning_flash:IsPurgable() return false end
function modifier_item_lightning_flash:DestroyOnExpire() return false end
function modifier_item_lightning_flash:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_lightning_flash:OnCreated(kv)
    local ability = self:GetAbility()
    if not ability then return end
    self.bonus_damage         = ability:GetSpecialValueFor("bonus_damage")
    self.bonus_armor          = ability:GetSpecialValueFor("bonus_armor")
    self.bonus_all_stats      = ability:GetSpecialValueFor("bonus_all_stats")
    self.bonus_attack_speed   = ability:GetSpecialValueFor("bonus_attack_speed")
    self.bonus_movement_speed = ability:GetSpecialValueFor("bonus_movement_speed")
end

modifier_item_lightning_flash.OnRefresh = modifier_item_lightning_flash.OnCreated

function modifier_item_lightning_flash:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    }
end

function modifier_item_lightning_flash:GetModifierPreAttack_BonusDamage() return self.bonus_damage or 0 end
function modifier_item_lightning_flash:GetModifierPhysicalArmorBonus() return self.bonus_armor or 0 end
function modifier_item_lightning_flash:GetModifierBonusStats_Strength() return self.bonus_all_stats or 0 end
function modifier_item_lightning_flash:GetModifierBonusStats_Agility() return self.bonus_all_stats or 0 end
function modifier_item_lightning_flash:GetModifierBonusStats_Intellect() return self.bonus_all_stats or 0 end
function modifier_item_lightning_flash:GetModifierAttackSpeedBonus_Constant() return self.bonus_attack_speed or 0 end
function modifier_item_lightning_flash:GetModifierMoveSpeedBonus_Constant() return self.bonus_movement_speed or 0 end
