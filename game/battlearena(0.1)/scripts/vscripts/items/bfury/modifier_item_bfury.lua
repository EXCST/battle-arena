modifier_item_bfury = modifier_item_bfury or class({})

function modifier_item_bfury:IsHidden() return true end
function modifier_item_bfury:IsPurgable() return false end
function modifier_item_bfury:DestroyOnExpire() return false end
function modifier_item_bfury:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_bfury:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function modifier_item_bfury:OnCreated(kv)
    self:OnRefresh(kv)
end

function modifier_item_bfury:OnRefresh(kv)
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.bonus_hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.cleave_pct = ability:GetSpecialValueFor("cleave_damage_percent")
    self.cleave_start = ability:GetSpecialValueFor("cleave_starting_width")
    self.cleave_end = ability:GetSpecialValueFor("cleave_ending_width")
    self.cleave_dist = ability:GetSpecialValueFor("cleave_distance")
    self.quelling_bonus = ability:GetSpecialValueFor("quelling_bonus")
    self.quelling_bonus_ranged = ability:GetSpecialValueFor("quelling_bonus_ranged")
end

function modifier_item_bfury:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage or 0
end

function modifier_item_bfury:GetModifierConstantHealthRegen()
    return self.bonus_hp_regen or 0
end

function modifier_item_bfury:GetModifierConstantManaRegen()
    return self.bonus_mana_regen or 0
end

function modifier_item_bfury:OnAttackLanded(keys)
    if not IsServer() then return end
    if keys.attacker ~= self:GetParent() then return end
    if keys.target:IsBuilding() or keys.target:IsOther() or not keys.target:IsAlive() then return end

    local parent = self:GetParent()
    local target = keys.target
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end

    local bonus_damage = 0
    if target:IsCreep() then
        bonus_damage = keys.damage * (self.quelling_bonus / 100)
        if parent:IsRangedAttacker() then
            bonus_damage = keys.damage * (self.quelling_bonus_ranged / 100)
        end
    end

    local cleave_damage = (keys.damage + bonus_damage) * (self.cleave_pct / 100)
    if parent:IsIllusion() then return end

    local enemies = FindUnitsInRadius(
        parent:GetTeamNumber(),
        target:GetAbsOrigin(),
        nil,
        self.cleave_end,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        if enemy ~= target and enemy:IsAlive() and not enemy:IsMagicImmune() then
            ApplyDamage({
                victim = enemy,
                attacker = parent,
                damage = cleave_damage,
                damage_type = DAMAGE_TYPE_PHYSICAL,
                damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL,
                ability = ability,
            })
        end
    end

    local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(pfx, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControlForward(pfx, 2, (target:GetAbsOrigin() - parent:GetAbsOrigin()):Normalized())
    ParticleManager:ReleaseParticleIndex(pfx)
end
