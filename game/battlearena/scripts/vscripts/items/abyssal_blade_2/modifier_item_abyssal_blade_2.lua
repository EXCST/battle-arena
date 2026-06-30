modifier_item_abyssal_blade_2 = class({})

function modifier_item_abyssal_blade_2:IsHidden() return true end
function modifier_item_abyssal_blade_2:IsPurgable() return false end
function modifier_item_abyssal_blade_2:DestroyOnExpire() return false end
function modifier_item_abyssal_blade_2:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_abyssal_blade_2:OnCreated(kv)
    local ability = self:GetAbility()
    if not ability then return end
    self.bonus_damage       = ability:GetSpecialValueFor("bonus_damage")
    self.bonus_health       = ability:GetSpecialValueFor("bonus_health")
    self.bonus_health_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_strength     = ability:GetSpecialValueFor("bonus_strength")
    self.block_damage_melee = ability:GetSpecialValueFor("block_damage_melee")
    self.block_damage_ranged= ability:GetSpecialValueFor("block_damage_ranged")
    self.block_chance       = ability:GetSpecialValueFor("block_chance")

    if not IsServer() then return end
    if not self:GetParent():IsIllusion() then
        self:GetParent():AddNewModifier(self:GetParent(), ability, "modifier_item_abyssal_blade_2_bash", { duration = -1 })
    end
end

modifier_item_abyssal_blade_2.OnRefresh = modifier_item_abyssal_blade_2.OnCreated

function modifier_item_abyssal_blade_2:OnDestroy()
    if not IsServer() then return end
    self:GetParent():RemoveModifierByName("modifier_item_abyssal_blade_2_bash")
end

function modifier_item_abyssal_blade_2:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
    }
end

function modifier_item_abyssal_blade_2:GetModifierPreAttack_BonusDamage() return self.bonus_damage or 0 end
function modifier_item_abyssal_blade_2:GetModifierExtraHealthBonus() return self.bonus_health or 0 end
function modifier_item_abyssal_blade_2:GetModifierConstantHealthRegen() return self.bonus_health_regen or 0 end
function modifier_item_abyssal_blade_2:GetModifierBonusStats_Strength() return self.bonus_strength or 0 end

function modifier_item_abyssal_blade_2:GetModifierPhysical_ConstantBlock(params)
    if params.attacker:GetTeamNumber() == self:GetParent():GetTeamNumber() then return 0 end
    if not RollPercentage(self.block_chance or 50) then return 0 end
    local isMelee = self:GetParent():IsRanged() == false
    local block = isMelee and (self.block_damage_melee or 0) or (self.block_damage_ranged or 0)
    return block
end
