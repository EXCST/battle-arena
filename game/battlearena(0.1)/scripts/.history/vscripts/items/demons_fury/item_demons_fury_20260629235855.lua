require('items/generic_datadriven_item')

LinkLuaModifier ("modifier_item_demons_fury", "items/demons_fury/item_demons_fury", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier ("modifier_item_desolator_datadriven_corruption", "items/demons_fury/item_demons_fury", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_burning_book_disarmor",   "items/burning_book/modifiers/modifier_burning_book_disarmor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_demons_fury_maim",   "items/demons_fury/modifiers/modifier_item_demons_fury_maim", LUA_MODIFIER_MOTION_NONE)

item_demons_fury = item_demons_fury or class({})

function item_demons_fury:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local castPosition = self:GetCursorPosition()
    GridNav:DestroyTreesAroundPoint(castPosition, self:GetSpecialValueFor("woodcutter_radius"), false)
end

function item_demons_fury:GetIntrinsicModifierName ()
    return "modifier_item_demons_fury"
end

modifier_item_demons_fury = modifier_item_demons_fury or class({})

-- Dummy Init to avoid nil errors (splash handled manually)
function modifier_item_demons_fury:Init(splashMult, splashRadius)
    -- No operation needed; kept for compatibility
end

function modifier_item_demons_fury:IsHidden()
    return true
end

function modifier_item_demons_fury:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_demons_fury:OnCreated(kv)
    local ability = self:GetAbility()

    if not ability then return end

    self.bonusDamage = ability:GetSpecialValueFor("bonus_damage")
    self.bonusInt    = ability:GetSpecialValueFor("bonus_int")
    self.bonusStr    = ability:GetSpecialValueFor("bonus_str")
    self.bonusAgi    = ability:GetSpecialValueFor("bonus_agi")
    self.bonusAs     = ability:GetSpecialValueFor("bonus_as")
    self.bonusMs     = ability:GetSpecialValueFor("bonus_ms")
    self.bonusHpReg  = ability:GetSpecialValueFor("bonus_hp_regen")
    self.bonusResist = ability:GetSpecialValueFor("bonus_status_resist")

    if not IsServer() then return end

    local splashDamage = ability:GetSpecialValueFor("splash_pct") / 100
    local splashRadius = ability:GetSpecialValueFor("splash_radius")

    self:Init(splashDamage, splashRadius)

    self.maimChance       = ability:GetSpecialValueFor("maim_chance")
    self.maimDuration     = ability:GetSpecialValueFor("maim_duration")
    self.maimDamage       = ability:GetSpecialValueFor("maim_damage")
    self.disarmorDuration = ability:GetSpecialValueFor("disarmor_duration")

    self.stream = CreateUniformRandomStream( GameRules:GetGameTime() )
end

modifier_item_demons_fury.OnRefresh = modifier_item_demons_fury.OnCreated

function modifier_item_demons_fury:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    }

    return funcs
end

function modifier_item_demons_fury:GetModifierPreAttack_BonusDamage()
    return self.bonusDamage
end

function modifier_item_demons_fury:GetModifierBonusStats_Strength()
    return self.bonusStr
end

function modifier_item_demons_fury:GetModifierBonusStats_Agility()
    return self.bonusAgi
end

function modifier_item_demons_fury:GetModifierAttackSpeedBonus_Constant()
    return self.bonusAs
end

function modifier_item_demons_fury:GetModifierMoveSpeedBonus_Percentage( params )
    return self.bonusMs
end

function modifier_item_demons_fury:GetModifierConstantHealthRegen()
    return self.bonusHpReg
end

function modifier_item_demons_fury:GetModifierStatusResistanceStacking(params)
    return self.bonusResist
end

function modifier_item_demons_fury:OnAttackLanded(keys)
    if not IsServer() then
        return
    end
    if keys.attacker ~= self:GetParent() or keys.target:IsBuilding() or keys.target:IsOther() or not keys.target:IsAlive() then
        return
    end
    local cleave_pct = self:GetParent():IsRangedAttacker() and self:GetAbility():GetSpecialValueFor("0") or self:GetAbility():GetSpecialValueFor("splash_pct")
    local cleave_damage = keys.damage * (cleave_pct / 100)
    if self:GetParent():IsIllusion() then
        cleave_damage = 0
    end
    local parent = keys.attacker
    local target = keys.target
    if parent:HasItemInInventory("item_burning_book") then
        return end
    target:RemoveModifierByName("modifier_burning_book_disarmor")
    target:AddNewModifier(self:GetAbility():GetCaster(), self:GetAbility(), "modifier_item_desolator_datadriven_corruption", {duration = 5})
    -- Maim on hit
    if self.stream:RollPercentage(self.maimChance) then
        target:AddNewModifier(self:GetAbility():GetCaster(), self:GetAbility(), "modifier_item_demons_fury_maim", {duration = self.maimDuration})
        ApplyDamage({victim = target, attacker = parent, damage = self.maimDamage, damage_type = DAMAGE_TYPE_PHYSICAL, ability = self:GetAbility()})
    end
    local enemies = FindUnitsInRadius(self:GetParent():GetTeamNumber(), target:GetAbsOrigin(), nil, self:GetAbility():GetSpecialValueFor("splash_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, FIND_ANY_ORDER, false)
    for _, enemy in pairs(enemies) do
        if enemy ~= target then
            local damageTable = {
                                victim = enemy,
                                attacker = self:GetParent(),
                                damage = cleave_damage,
                                damage_type = DAMAGE_TYPE_PURE,
                                damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, --Optional.
                                ability = nil, --Optional.
                                }
            ApplyDamage(damageTable)
        end
    end
    local pfx = ParticleManager:CreateParticle("particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave_gods_strength.vpcf", PATTACH_ABSORIGIN, keys.attacker)
    ParticleManager:ReleaseParticleIndex(pfx)
end

if modifier_item_desolator_datadriven_corruption == nil then modifier_item_desolator_datadriven_corruption = class({}) end

function modifier_item_desolator_datadriven_corruption:IsHidden()
    return false
end

function modifier_item_desolator_datadriven_corruption:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }

    return funcs
end

function modifier_item_desolator_datadriven_corruption:GetModifierPhysicalArmorBonus( params )
    return self:GetAbility():GetSpecialValueFor("disarmor")
end

function item_demons_fury:GetAbilityTextureName()
return "custom/demons_fury"
end