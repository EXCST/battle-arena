modifier_generic_datadriven_item = modifier_generic_datadriven_item or class({})

function modifier_generic_datadriven_item:IsHidden() return true end
function modifier_generic_datadriven_item:IsPurgable() return false end
function modifier_generic_datadriven_item:DestroyOnExpire() return false end
function modifier_generic_datadriven_item:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end

local STAT_MAP = {
    bonus_damage          = "MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE",
    bonus_dmg             = "MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE",
    damage                = "MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE",
    bonus_armor           = "MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS",
    armor                 = "MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS",
    bonus_strength        = "MODIFIER_PROPERTY_STATS_STRENGTH_BONUS",
    bonus_str             = "MODIFIER_PROPERTY_STATS_STRENGTH_BONUS",
    bonus_agility         = "MODIFIER_PROPERTY_STATS_AGILITY_BONUS",
    bonus_agi             = "MODIFIER_PROPERTY_STATS_AGILITY_BONUS",
    bonus_intellect       = "MODIFIER_PROPERTY_STATS_INTELLECT_BONUS",
    bonus_int             = "MODIFIER_PROPERTY_STATS_INTELLECT_BONUS",
    bonus_intelligence    = "MODIFIER_PROPERTY_STATS_INTELLECT_BONUS",
    bonus_attack_speed    = "MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT",
    bonus_as              = "MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT",
    bonus_aspeed          = "MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT",
    bonus_attackspeed     = "MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT",
    attack_speed          = "MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT",
    bonus_health          = "MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS",
    bonus_hp              = "MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS",
    health                = "MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS",
    bonus_health_regen    = "MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT",
    bonus_hp_regen        = "MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT",
    bonus_hpregen         = "MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT",
    bonus_hpreg           = "MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT",
    bonus_regen           = "MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT",
    bonus_mana            = "MODIFIER_PROPERTY_EXTRA_MANA_BONUS",
    mana                  = "MODIFIER_PROPERTY_EXTRA_MANA_BONUS",
    bonus_mana_regen      = "MODIFIER_PROPERTY_MANA_REGEN_CONSTANT",
    bonus_manaregen       = "MODIFIER_PROPERTY_MANA_REGEN_CONSTANT",
    bonus_mpreg           = "MODIFIER_PROPERTY_MANA_REGEN_CONSTANT",
    bonus_magic_resist    = "MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS",
    bonus_magic_resistance = "MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS",
    bonus_magical_armor   = "MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS",
    bonus_magresist       = "MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS",
    bonus_spell_resist    = "MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS",
    bonus_move_speed      = "MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT",
    bonus_movement_speed  = "MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT",
    bonus_movement        = "MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT",
    bonus_speed           = "MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT",
    bonus_ms              = "MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT",
    bonus_movespeed       = "MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT",
    bonus_move_speed_pct  = "MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE",
    bonus_mvspd_pct       = "MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE",
    bonus_movement_speed_pct = "MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE",
    bonus_evasion         = "MODIFIER_PROPERTY_EVASION_CONSTANT",
    bonus_spell_amp       = "MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE",
    bonus_spellamp        = "MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE",
    spell_amp             = "MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE",
    spell_amplify         = "MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE",
    bonus_spell_damage    = "MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE",
    bonus_attack_range    = "MODIFIER_PROPERTY_ATTACK_RANGE_BONUS",
    attack_range_bonus    = "MODIFIER_PROPERTY_ATTACK_RANGE_BONUS",
    attack_range          = "MODIFIER_PROPERTY_ATTACK_RANGE_BONUS",
    bonus_lifesteal       = "MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE",
    spell_lifesteal       = "MODIFIER_PROPERTY_SPELL_LIFESTEAL_BONUS",
    spell_lifesteal_amp   = "MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE",
    lifesteal_percent     = "MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE",
    attack_lifesteal      = "MODIFIER_PROPERTY_ATTACK_LIFESTEAL_BONUS",
    bonus_cooldown        = "MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE",
    cooldown_reduce       = "MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE",
    status_resist         = "MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING",
    status_resistance     = "MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING",
    bonus_status_resist   = "MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING",
    bonus_slow_resist     = "MODIFIER_PROPERTY_SLOW_RESISTANCE",
    bonus_day_vision      = "MODIFIER_PROPERTY_BONUS_DAY_VISION",
    bonus_night_vision    = "MODIFIER_PROPERTY_BONUS_NIGHT_VISION",
    bonus_cast_range      = "MODIFIER_PROPERTY_CAST_RANGE_BONUS",
    bonus_gold            = "MODIFIER_PROPERTY_BASEGOLD_BONUS",
    bonus_gpm             = "MODIFIER_PROPERTY_BASEGOLD_BONUS",
    damage_return         = "MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BONUS_CLEAVE",
    bonus_primary_stat    = "MODIFIER_PROPERTY_STATS_STRENGTH_BONUS",
    bonus_secondary_stat  = "MODIFIER_PROPERTY_STATS_AGILITY_BONUS",
    bonus_stat            = "MODIFIER_PROPERTY_STATS_STRENGTH_BONUS",
    bonus_attack          = "MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE",
    damage_bonus          = "MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE",
}

local ALL_STATS_KEYS = {"bonus_all_stats", "all_stats", "bonus_stats", "bonus_all"}
local STAT_PROPS = {
    "MODIFIER_PROPERTY_STATS_STRENGTH_BONUS",
    "MODIFIER_PROPERTY_STATS_AGILITY_BONUS",
    "MODIFIER_PROPERTY_STATS_INTELLECT_BONUS",
}

function modifier_generic_datadriven_item:DeclareFunctions()
    local funcs = {}
    local ability = self:GetAbility()
    if not ability then return funcs end

    for key, prop in pairs(STAT_MAP) do
        local val = ability:GetSpecialValueFor(key)
        if val and val ~= 0 then
            local exists = false
            for _, f in ipairs(funcs) do
                if f == prop then exists = true; break end
            end
            if not exists then
                table.insert(funcs, prop)
            end
        end
    end

    for _, key in ipairs(ALL_STATS_KEYS) do
        local val = ability:GetSpecialValueFor(key)
        if val and val ~= 0 then
            for _, prop in ipairs(STAT_PROPS) do
                local exists = false
                for _, f in ipairs(funcs) do
                    if f == prop then exists = true; break end
                end
                if not exists then
                    table.insert(funcs, prop)
                end
            end
            break
        end
    end

    return funcs
end

function modifier_generic_datadriven_item:OnCreated(kv)
    self:OnRefresh(kv)
end

function modifier_generic_datadriven_item:OnRefresh(kv)
    local ability = self:GetAbility()
    if not ability then return end

    self.stats = {}
    for key, prop in pairs(STAT_MAP) do
        local val = ability:GetSpecialValueFor(key)
        if val and val ~= 0 then
            if not self.stats[prop] then self.stats[prop] = 0 end
            self.stats[prop] = self.stats[prop] + val
        end
    end

    for _, key in ipairs(ALL_STATS_KEYS) do
        local val = ability:GetSpecialValueFor(key)
        if val and val ~= 0 then
            self.stats["MODIFIER_PROPERTY_STATS_STRENGTH_BONUS"] = (self.stats["MODIFIER_PROPERTY_STATS_STRENGTH_BONUS"] or 0) + val
            self.stats["MODIFIER_PROPERTY_STATS_AGILITY_BONUS"] = (self.stats["MODIFIER_PROPERTY_STATS_AGILITY_BONUS"] or 0) + val
            self.stats["MODIFIER_PROPERTY_STATS_INTELLECT_BONUS"] = (self.stats["MODIFIER_PROPERTY_STATS_INTELLECT_BONUS"] or 0) + val
            break
        end
    end
end

function modifier_generic_datadriven_item:GetModifierPreAttack_BonusDamage() return self.stats and self.stats["MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE"] or 0 end
function modifier_generic_datadriven_item:GetModifierPhysicalArmorBonus() return self.stats and self.stats["MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS"] or 0 end
function modifier_generic_datadriven_item:GetModifierBonusStats_Strength() return self.stats and self.stats["MODIFIER_PROPERTY_STATS_STRENGTH_BONUS"] or 0 end
function modifier_generic_datadriven_item:GetModifierBonusStats_Agility() return self.stats and self.stats["MODIFIER_PROPERTY_STATS_AGILITY_BONUS"] or 0 end
function modifier_generic_datadriven_item:GetModifierBonusStats_Intellect() return self.stats and self.stats["MODIFIER_PROPERTY_STATS_INTELLECT_BONUS"] or 0 end
function modifier_generic_datadriven_item:GetModifierAttackSpeedBonus_Constant() return self.stats and self.stats["MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT"] or 0 end
function modifier_generic_datadriven_item:GetModifierExtraHealthBonus() return self.stats and self.stats["MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS"] or 0 end
function modifier_generic_datadriven_item:GetModifierConstantHealthRegen() return self.stats and self.stats["MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT"] or 0 end
function modifier_generic_datadriven_item:GetModifierExtraManaBonus() return self.stats and self.stats["MODIFIER_PROPERTY_EXTRA_MANA_BONUS"] or 0 end
function modifier_generic_datadriven_item:GetModifierConstantManaRegen() return self.stats and self.stats["MODIFIER_PROPERTY_MANA_REGEN_CONSTANT"] or 0 end
function modifier_generic_datadriven_item:GetModifierMagicalResistanceBonus() return self.stats and self.stats["MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS"] or 0 end
function modifier_generic_datadriven_item:GetModifierMoveSpeedBonus_Constant() return self.stats and self.stats["MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT"] or 0 end
function modifier_generic_datadriven_item:GetModifierMoveSpeedBonus_Percentage() return self.stats and self.stats["MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE"] or 0 end
function modifier_generic_datadriven_item:GetModifierEvasion_Constant() return self.stats and self.stats["MODIFIER_PROPERTY_EVASION_CONSTANT"] or 0 end
function modifier_generic_datadriven_item:GetModifierSpellAmplify_Percentage() return self.stats and self.stats["MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE"] or 0 end
function modifier_generic_datadriven_item:GetModifierAttackRangeBonus() return self.stats and self.stats["MODIFIER_PROPERTY_ATTACK_RANGE_BONUS"] or 0 end
function modifier_generic_datadriven_item:GetModifierPercentageCooldown() return self.stats and self.stats["MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE"] or 0 end
function modifier_generic_datadriven_item:GetModifierStatusResistanceStacking() return self.stats and self.stats["MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING"] or 0 end
function modifier_generic_datadriven_item:GetBonusDayVision() return self.stats and self.stats["MODIFIER_PROPERTY_BONUS_DAY_VISION"] or 0 end
function modifier_generic_datadriven_item:GetBonusNightVision() return self.stats and self.stats["MODIFIER_PROPERTY_BONUS_NIGHT_VISION"] or 0 end
function modifier_generic_datadriven_item:GetModifierCastRangeBonus() return self.stats and self.stats["MODIFIER_PROPERTY_CAST_RANGE_BONUS"] or 0 end
function modifier_generic_datadriven_item:GetModifierBaseGoldBonus() return self.stats and self.stats["MODIFIER_PROPERTY_BASEGOLD_BONUS"] or 0 end
function modifier_generic_datadriven_item:GetModifierSpellLifestealBonus() return self.stats and self.stats["MODIFIER_PROPERTY_SPELL_LIFESTEAL_BONUS"] or 0 end
function modifier_generic_datadriven_item:GetModifierSpellLifestealAmplifyPercentage() return self.stats and self.stats["MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE"] or 0 end
function modifier_generic_datadriven_item:GetModifierAttackLifestealBonus() return self.stats and self.stats["MODIFIER_PROPERTY_ATTACK_LIFESTEAL_BONUS"] or 0 end
