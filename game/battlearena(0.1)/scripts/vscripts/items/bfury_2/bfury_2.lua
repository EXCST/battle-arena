LinkLuaModifier ("modifier_item_bfury_2", "items/bfury_2/bfury_2", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_burning_book_disarmor",   "items/burning_book/modifiers/modifier_burning_book_disarmor", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bfury_2_maim",       "items/bfury_2/modifier_bfury_2_maim", LUA_MODIFIER_MOTION_NONE)

item_bfury_2 = item_bfury_2 or class({})

function item_bfury_2:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local castPosition = self:GetCursorPosition()
    GridNav:DestroyTreesAroundPoint(castPosition, self:GetSpecialValueFor("woodcutter_radius"), false)
end

function item_bfury_2:GetIntrinsicModifierName ()
    return "modifier_item_bfury_2"
end

modifier_item_bfury_2 = modifier_item_bfury_2 or class({})

function modifier_item_bfury_2:IsHidden()
    return true
end

function modifier_item_bfury_2:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_bfury_2:OnCreated(kv)
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
    self.bonusManaReg = ability:GetSpecialValueFor("mp_regen")

    if not IsServer() then return end

    local splashDamage = ability:GetSpecialValueFor("splash_pct") / 100
    local splashRadius = ability:GetSpecialValueFor("splash_radius")

    self.maimChance       = ability:GetSpecialValueFor("maim_chance")
    self.maimDuration     = ability:GetSpecialValueFor("maim_duration")

    self.stream = CreateUniformRandomStream( GameRules:GetGameTime() )
end

modifier_item_bfury_2.OnRefresh = modifier_item_bfury_2.OnCreated

function modifier_item_bfury_2:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    }

    return funcs
end

function modifier_item_bfury_2:GetModifierConstantManaRegen()
    return self.bonusManaReg
end

function modifier_item_bfury_2:GetModifierPreAttack_BonusDamage()
    return self.bonusDamage
end

function modifier_item_bfury_2:GetModifierBonusStats_Strength()
    return self.bonusStr
end

function modifier_item_bfury_2:GetModifierBonusStats_Agility()
    return self.bonusAgi
end

function modifier_item_bfury_2:GetModifierAttackSpeedBonus_Constant()
    return self.bonusAs
end

function modifier_item_bfury_2:GetModifierMoveSpeedBonus_Percentage( params )
    return self.bonusMs
end

function modifier_item_bfury_2:GetModifierConstantHealthRegen()
    return self.bonusHpReg
end

function modifier_item_bfury_2:GetModifierStatusResistanceStacking(params)
    return self.bonusResist
end

function modifier_item_bfury_2:OnAttackLanded(keys)
    if not IsServer() then
        return
    end

    if keys.attacker ~= self:GetParent() or keys.target:IsBuilding() or keys.target:IsOther() or not keys.target:IsAlive() or self:GetParent():IsRangedAttacker()  then
        return
    end

    local cleave_pct = self:GetParent():IsRangedAttacker() and self:GetAbility():GetSpecialValueFor("0") or self:GetAbility():GetSpecialValueFor("splash_pct")
    local cleave_damage = keys.damage * (cleave_pct / 100)
    if self:GetParent():IsIllusion() then
        cleave_damage = 0
    end
    local parent = keys.attacker
    local target = keys.target
    local enemies = FindUnitsInRadius(self:GetParent():GetTeamNumber(), target:GetAbsOrigin(), nil, self:GetAbility():GetSpecialValueFor("splash_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, FIND_ANY_ORDER, false)
    for _, enemy in pairs(enemies) do
        if enemy ~= target then
            if enemy:IsCreep() then
                local damageTable_creep = {
                                victim = enemy,
                                attacker = self:GetParent(),
                                damage = cleave_damage * 3,
                                damage_type = DAMAGE_TYPE_PHYSICAL,
                                damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, --Optional.
                                ability = nil, --Optional.
                                }
                ApplyDamage(damageTable_creep)
        else    
            local damageTable = {
                                victim = enemy,
                                attacker = self:GetParent(),
                                damage = cleave_damage,
                                damage_type = DAMAGE_TYPE_PHYSICAL,
                                damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, --Optional.
                                ability = nil, --Optional.
                                }
            ApplyDamage(damageTable)
        end
      end

    if self.stream:RollPercentage( self.maimChance ) then
        target:AddNewModifier(parent, ability, "modifier_bfury_2_maim", { duration = self.maimDuration })
    end

    end
    local pfx = ParticleManager:CreateParticle("particles/econ/items/sven/sven_ti7_sword/sven_ti7_sword_spell_great_cleave_b.vpcf", PATTACH_ABSORIGIN, keys.attacker)
    ParticleManager:ReleaseParticleIndex(pfx)
end

function item_bfury_2:GetTexture()
return "../items/custom/bfury_2"
end