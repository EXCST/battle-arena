require('items/generic_datadriven_item')


require('items/custom/item_base_rapier')


item_nature_rapier = class(item_base_rapier)

function item_nature_rapier:GetIntrinsicModifierName()
	return "modifier_item_nature_rapier"
end

function item_nature_rapier:GetCastRange(vLocation, hTarget)
    if(not IsServer()) then
        return self:GetSpecialValueFor("cast_range")
    end
    local caster = self:GetCaster()
    if(caster:GetModifierStackCount(self:GetIntrinsicModifierName(), caster) == 1) then
        return 999999
    end
    return self:GetSpecialValueFor("cast_range")
end

function item_nature_rapier:ApplyItemContainerEffects(itemContainer)
	itemContainer:SetRenderColor(0, 255, 0)
end

function item_nature_rapier:CastFilterResultTarget(target)
    if(not IsServer()) then
        return UF_SUCCESS
    end
    local caster = self:GetCaster()
    if(target:IsBoss() == true) then
        return UF_FAIL_CUSTOM
    end
    local playerOwnerID = target:GetMainControllingPlayer()
    local casterOwnerID = caster:GetPlayerOwnerID()
    local isTargetOwnerEqualToCaster = (playerOwnerID == casterOwnerID)
    if(target:IsControllableByAnyPlayer() == true and isTargetOwnerEqualToCaster == false) then
        return UF_FAIL_CUSTOM
    end
    if(caster:GetLevel() < (target:GetLevel() * self:GetSpecialValueFor("creep_lvl_multiplier")) and isTargetOwnerEqualToCaster == false) then
        return UF_FAIL_CUSTOM
    end
    if(target:IsCanBeDominated() == false and caster ~= target) then
        return UF_FAIL_OTHER
    end
    if(target:IsEliteCreep() == true) then
        return UF_FAIL_OTHER
    end
    if(target:IsRealHero() and caster ~= target) then
        return UF_FAIL_HERO
    end
    return UnitFilter(target, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), caster:GetTeamNumber())
end

function item_nature_rapier:GetCustomCastErrorTarget(target)
    if(not IsServer()) then
        return "?"
    end
    local caster = self:GetCaster()
    if(target:IsBoss() == true) then
        return "wisp_infest_error_is_boss"
    end
    if(target:IsControllableByAnyPlayer() == true and target:GetMainControllingPlayer() ~= caster:GetPlayerOwnerID()) then
        return "wisp_infest_error_is_not_controllable"
    end
    if(caster:GetLevel() < (target:GetLevel() * self:GetSpecialValueFor("creep_lvl_multiplier"))) then
        return "wisp_infest_error_need_lvl"
    end
end

function item_nature_rapier:OnOpenEventsCastOrder(ability, orderType, orderTargetEntIndex)
    if(not orderTargetEntIndex or type(orderTargetEntIndex) ~= "number") then
        return
    end
    local caster = self:GetCaster()
    local target = EntIndexToHScript(orderTargetEntIndex)
    if(target.GetMainControllingPlayer and target:GetMainControllingPlayer() == caster:GetPlayerOwnerID()) then
        caster:SetModifierStackCount(self:GetIntrinsicModifierName(), caster, 1)
    else
        caster:SetModifierStackCount(self:GetIntrinsicModifierName(), caster, 0)
    end
end

function item_nature_rapier:OnSpellStart()
	if(not IsServer()) then
		return
	end
    self._controlledUnits = self._controlledUnits or {}
    local caster = self:GetCaster()
    local casterTeam = caster:GetTeamNumber()
    local target = self:GetCursorTarget()
    local position = target:GetAbsOrigin()
    local targetName = target:GetUnitName()
    local targetTeam = target:GetTeamNumber()
    -- Teleport all fuckers to caster on self cast
    if(caster == target) then
        local allies = FindUnitsInRadius(
            casterTeam, 
            Vector(0, 0, 0), 
            nil, 
            FIND_UNITS_EVERYWHERE, 
            DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
            DOTA_UNIT_TARGET_ALL, 
            DOTA_UNIT_TARGET_FLAG_NONE, 
            FIND_ANY_ORDER, 
            false
        )
        ArrayRemove(allies, function(t, i, j)
            local unit = t[i]
            return unit:GetOwner() == caster and unit ~= caster and unit:HasMovementCapability() == true
        end)
        if(#allies == 0) then
			PlayerResource:SendCustomErrorMessageToPlayer(caster:GetPlayerOwnerID(), "DOTA_Tooltip_ability_item_nature_rapier_error_you_must_have_at_least_one_unit")
            self:RefundManaCost()
            self:EndCooldown()
            return
        end
        for _, unit in pairs(allies) do
            self:TeleportUnitToCaster(unit, caster)
        end
        return
    end
    -- Teleport controlled unit to caster
    if(target:IsControllableByAnyPlayer() == true) then
        self:TeleportUnitToCaster(target, caster)
        return
    end
    if(#self._controlledUnits >= self:GetSpecialValueFor("max_units")) then
        local isUnitRemoved = false
        ArrayRemove(self._controlledUnits, function(t, i, j)
            if(isUnitRemoved == false) then
                isUnitRemoved = true
                if(t[i]:IsNull() == false) then
                    t[i]:Kill(nil,nil)
                    local position = t[i]:GetAbsOrigin()
                    local particle = ParticleManager:CreateParticle(
                        "particles/custom/items/nature_rapier/teleport_cast.vpcf", 
                        PATTACH_CUSTOMORIGIN, 
                        nil
                    )
                    ParticleManager:SetParticleControl(particle, 1, position)
                    ParticleManager:SetParticleControl(particle, 2, position)
                    ParticleManager:ReleaseParticleIndex(particle)
                end
                return false
            end
            return true
        end)
    end
    local dominatedCreep = target:Dominate(caster)
    dominatedCreep:AddNewModifier(caster, nil, "modifier_invulnerable", {duration = 0.1})
    local particle = ParticleManager:CreateParticle(
        "particles/custom/items/nature_rapier/enchant/enchantdeath.vpcf", 
        PATTACH_ABSORIGIN, 
        dominatedCreep
    )
    ParticleManager:SetParticleControl(particle, 1, dominatedCreep:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)
    EmitSoundOn("NatureRapier.Cast", dominatedCreep)
    table.insert(self._controlledUnits, dominatedCreep)
end

function item_nature_rapier:TeleportUnitToCaster(target, caster)
    local targetPosition = target:GetAbsOrigin()
    local particle = ParticleManager:CreateParticle(
        "particles/custom/items/nature_rapier/teleport_cast.vpcf", 
        PATTACH_CUSTOMORIGIN, 
        nil
    )
    ParticleManager:SetParticleControl(particle, 1, targetPosition)
    ParticleManager:SetParticleControl(particle, 2, targetPosition)
    ParticleManager:ReleaseParticleIndex(particle)
    FindClearSpaceForUnit(target, caster:GetAbsOrigin(), true)
    targetPosition = target:GetAbsOrigin()
    local particle = ParticleManager:CreateParticle(
        "particles/custom/items/nature_rapier/teleport_cast.vpcf", 
        PATTACH_CUSTOMORIGIN, 
        nil
    )
    ParticleManager:SetParticleControl(particle, 1, targetPosition)
    ParticleManager:SetParticleControl(particle, 2, targetPosition)
    ParticleManager:ReleaseParticleIndex(particle)
    EmitSoundOn("NatureRapier.Cast", target)
    target:Stop()
end

modifier_item_nature_rapier = class(modifier_item_base_rapier)

function modifier_item_nature_rapier:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_EVENT_ON_DEATH
	}
end

function modifier_item_nature_rapier:CheckState()
	return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
	}
end

function modifier_item_nature_rapier:GetEffectName()
	return "particles/custom/items/nature_rapier/effect_lvl3.vpcf"
end

function modifier_item_nature_rapier:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_nature_rapier:OnOwnerHaveMoreThanOneRapierType(owner, item)
	GameRules:SendCustomMessage("#Game_notification_nature_rapier_request_message1",0,0)
	self:DropRapier(owner, item)
end

function modifier_item_nature_rapier:OnOwnerHaveInsufficientStats(owner, item, insufficientStats)
	GameRules:SendCustomMessage("#Game_notification_nature_rapier_request_message",0,0)	
	GameRules:SendCustomMessage("<font color='#24a73c'>MISSING ATTRIBUTES: </font><font color='#FF4500'>".. insufficientStats .."</font>",0,0)
	self:DropRapier(owner, item)
end

function modifier_item_nature_rapier:OnRapierAddedToInventory()
	self.parent = self:GetParent()
    local rapierAbility = self:GetAbility()
    local rapierKV = rapierAbility:GetAbilityKeyValues()
    self.creepsIgnoreList = rapierKV["IgnoreList"] or {}
end

function modifier_item_nature_rapier:IsAura() 
    return true
end

function modifier_item_nature_rapier:GetAuraRadius() 
    return FIND_UNITS_EVERYWHERE 
end

function modifier_item_nature_rapier:GetAuraSearchTeam() 
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY 
end

function modifier_item_nature_rapier:GetAuraSearchType() 
    return DOTA_UNIT_TARGET_ALL
end

function modifier_item_nature_rapier:GetAuraSearchFlags() 
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE 
end

function modifier_item_nature_rapier:GetModifierAura() 
    return "modifier_item_nature_rapier_summon" 
end

function modifier_item_nature_rapier:GetAuraEntityReject(npc)
    if(npc:GetOwner() == self.parent) then
        if(npc:IsBuilding() == true) then
            return true
        end
        if((self.creepsIgnoreList and tonumber(self.creepsIgnoreList[npc:GetUnitName()]) == 1) 
        or npc._vulkanTskGovnoEbanoe
        or npc:IsIllusion()) then
            return true
        end
        return false
    end
    return true
end

function modifier_item_nature_rapier:IsAuraActiveOnDeath()
    return true
end

modifier_item_nature_rapier_summon = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    IsDebuff = function()
        return false
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_BASE_ATTACK_TIME_CONSTANT,
			MODIFIER_PROPERTY_ROSHDEF_BASE_ATTACK_TIME_MIN,
--            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_ROSHDEF_BASE_ATTACK_BONUS_DAMAGE_PERCENTAGE,
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_TOOLTIP,
			MODIFIER_EVENT_ON_TAKEDAMAGE
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    GetModifierConstantHealthRegen = function(self)
        return self.bonusHealthRegeneration
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end,
    GetModifierBonusBaseAttackTimeConstant = function(self)
        return self.bonusBAT
    end,
	GetModifierBaseAttackTimeMin = function(self)
		return self.agiToBatMin
	end,
--    GetModifierPreAttack_BonusDamage = function(self)
--        return self.bonusDamage
--    end,
    GetModifierBaseAttack_BonusDamagePercentage = function(self)
        return self.bonusDamage
    end,
    GetModifierSpellAmplify_Percentage = function(self)
        return self.bonusSpellAmp
    end
})

-- HandleCustomTransmitterData called before OnCreated. No idea how and even why
function modifier_item_nature_rapier_summon:OnCreated()
    self.tooltipIndex = 0
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self.parent = self:GetParent()
    self.auraOwner = self:GetAuraOwner()
    self.bonusMaxHpPct = self.bonusMaxHpPct or 0
    self.bonusHealthRegeneration = self.bonusHealthRegeneration or 0
    self.bonusBAT = self.bonusBAT or 0
    self.bonusArmor = self.bonusArmor or 0
    self.bonusDamage = self.bonusDamage or 0
    self.bonusSpellAmp = self.bonusSpellAmp or 0
    self.parentHealthPercent = self.parentHealthPercent or self.parent:GetHealthPercent() / 100
    self.bonusMaxHealthPctValueForSummonsWithCustomBaseHealth = self.bonusMaxHealthPctValueForSummonsWithCustomBaseHealth or 0
    self.bonusMaxHealthPctForSummonsWithCustomBaseHealth = self.bonusMaxHealthPctForSummonsWithCustomBaseHealth or 0
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self:SetHasCustomTransmitterData(true)
    self:StartIntervalThink(0.05)
end

function modifier_item_nature_rapier_summon:OnRefresh()
    self.auraOwner = self:GetAuraOwner() or self.auraOwner
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.strToMaxHpPct = self.ability:GetSpecialValueFor("str_to_max_hp_pct")
    self.strToHpReg = self.ability:GetSpecialValueFor("str_to_hp_reg")
    self.agiToBat = self.ability:GetSpecialValueFor("agi_to_bat")
    self.agiToBatMin = self.ability:GetSpecialValueFor("agi_to_bat_min")
    self.agiToArmor = self.ability:GetSpecialValueFor("agi_to_armor")
    self.intToBonusDmg = self.ability:GetSpecialValueFor("int_to_bonus_dmg")
    self.intToSpellAmp = self.ability:GetSpecialValueFor("int_to_spell_amp")
    self.tickInterval = self.ability:GetSpecialValueFor("tick_interval")
    self.ownerAttackDamageToHealignPct = self.ability:GetSpecialValueFor("owner_attack_damage_to_healing_pct") / 100
    self.summonsAttackDamageToHealingPct = self.ability:GetSpecialValueFor("summons_attack_damage_to_healing_pct") / 100
    self.healingAuraRadiusSqr = self.ability:GetSpecialValueFor("healing_radius") ^ 2
    if(not IsServer()) then
        return
    end
    local rapierAbility = self.ability
    self.bonusStatsMultiplier = self.ability:GetSpecialValueFor("summons_stats_multiplier")
    if(not rapierAbility) then
        return
    end
    local rapierKV = rapierAbility:GetAbilityKeyValues()
    if(rapierKV["BonusStatsMultipliersPercent"]) then
        self.bonusStatsMultiplier = tonumber(rapierKV["BonusStatsMultipliersPercent"][self.parent:GetUnitName()]) or self.bonusStatsMultiplier
    end
    self.bonusStatsMultiplier = self.bonusStatsMultiplier / 100
end

function modifier_item_nature_rapier_summon:OnTooltip()
    local result = 0
    if(self.tooltipIndex == 0) then
        if(self:IsUsingSummonsCustomBaseHealth() == true) then
            result = self.bonusMaxHealthPctForSummonsWithCustomBaseHealth
        else
            result = self.bonusMaxHpPct
        end
    end
    if(self.tooltipIndex == 1) then
        result = self.bonusBAT
    end
    if(self.tooltipIndex == 2) then
        result = self.bonusStatsMultiplier * 100
    end
    self.tooltipIndex = self.tooltipIndex + 1
    if(self.tooltipIndex > 2) then
        self.tooltipIndex = 0
    end
    return result
end

function modifier_item_nature_rapier_summon:OnIntervalThink()
    if(not self.auraOwner.GetStrength) then
        return 
    end
    local propertiesRequireUpdate = 0
    local precision = 0.01
    local str = self.auraOwner:GetStrength(true)
    local agi = self.auraOwner:GetAgility(true)
    local int = self.auraOwner:GetPrimaryStatValue()
    local customSummonBaseHealth = self.parent:GetSummonBaseMaxHealth()
    local isSummonUsingCustomBaseMaxHealth = (customSummonBaseHealth ~= nil)
    if(isSummonUsingCustomBaseMaxHealth == true) then
        local bonusPercent = (str * self.strToMaxHpPct * self.bonusStatsMultiplier)
        local newBonusMaxHpPctValue = customSummonBaseHealth * (bonusPercent / 100)
        if(math.abs(newBonusMaxHpPctValue - self.bonusMaxHealthPctValueForSummonsWithCustomBaseHealth) > precision) then
            propertiesRequireUpdate = propertiesRequireUpdate + 1
        end
        self.bonusMaxHpPct = 0
        self.bonusMaxHealthPctValueForSummonsWithCustomBaseHealth = newBonusMaxHpPctValue
        self.bonusMaxHealthPctForSummonsWithCustomBaseHealth = bonusPercent
    else
        local newBonusMaxHpPct = str * self.strToMaxHpPct * self.bonusStatsMultiplier
        if(math.abs(newBonusMaxHpPct - self.bonusMaxHpPct) > precision) then
            propertiesRequireUpdate = propertiesRequireUpdate + 1
        end
        self.bonusMaxHpPct = newBonusMaxHpPct
        self.bonusMaxHealthPctValueForSummonsWithCustomBaseHealth = 0
        self.bonusMaxHealthPctForSummonsWithCustomBaseHealth = 0
    end
    self:SetIsUsingSummonsCustomBaseHealth(isSummonUsingCustomBaseMaxHealth)
    local newBonusHealthRegeneration = str * self.strToHpReg * self.bonusStatsMultiplier
    if(math.abs(newBonusHealthRegeneration - self.bonusHealthRegeneration) > precision) then
        propertiesRequireUpdate = propertiesRequireUpdate + 1
    end
    self.bonusHealthRegeneration = newBonusHealthRegeneration
    local newBonusBAT = ((agi * self.agiToBat) * self.bonusStatsMultiplier) * -1
    if(math.abs(newBonusBAT - self.bonusBAT) > precision) then
        propertiesRequireUpdate = propertiesRequireUpdate + 1
    end
    self.bonusBAT = newBonusBAT
    local newBonusArmor = agi * self.agiToArmor * self.bonusStatsMultiplier
    if(math.abs(newBonusArmor - self.bonusArmor) > precision) then
        propertiesRequireUpdate = propertiesRequireUpdate + 1
    end
    self.bonusArmor = newBonusArmor
    local newBonusDamage = int * self.intToBonusDmg * self.bonusStatsMultiplier
    if(math.abs(newBonusDamage - self.bonusDamage) > precision) then
        propertiesRequireUpdate = propertiesRequireUpdate + 1
    end
    self.bonusDamage = newBonusDamage
    local newBonusSpellAmp = int * self.intToSpellAmp * self.bonusStatsMultiplier
    if(math.abs(newBonusSpellAmp - self.bonusSpellAmp) > precision) then
        propertiesRequireUpdate = propertiesRequireUpdate + 1
    end
    self.bonusSpellAmp = newBonusSpellAmp
    -- Send all shit to client
    if(propertiesRequireUpdate > 0 or not self._isFirstTick) then
        self:SendBuffRefreshToClients()
        self.parent:CalculateGenericBonuses()
    end
    if(not self._isFirstTick) then
        self.parent:SetHealth(self.parent:GetMaxHealth() * self.parentHealthPercent)
        self:StartIntervalThink(self.tickInterval)
        self._isFirstTick = true
    end
end

function modifier_item_nature_rapier_summon:OnTakeDamage(kv)
    if(kv.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK) then
        return
    end
    if(kv.attacker == self.auraOwner) then
        local distance = CalculateDistanceSqr(self.auraOwner, self.parent)
        if(distance <= self.healingAuraRadiusSqr) then
            self.parent:Heal(kv.damage * self.ownerAttackDamageToHealignPct, self.ability, DOTA_HEAL_TYPE_HEALING)
        end
    end
    if(kv.attacker == self.parent) then
        local distance = CalculateDistanceSqr(self.auraOwner, self.parent)
        if(distance <= self.healingAuraRadiusSqr) then
            self.auraOwner:Heal(kv.damage * self.summonsAttackDamageToHealingPct, self.ability, DOTA_HEAL_TYPE_HEALING)
        end
    end
end

function modifier_item_nature_rapier_summon:SetIsUsingSummonsCustomBaseHealth(state)
    if(state ~= true and state ~= false) then
        Debug_PrintError("Attempt to call modifier_item_nature_rapier_summon:SetIsUsingSummonsCustomBaseHealth with invalid state argument. Boolean expected, got "..tostring(state).." ("..type(state)..")")
        return
    end
    self._isUsingSummonsCustomBaseHealth = state == true and 1 or 0
end

function modifier_item_nature_rapier_summon:IsUsingSummonsCustomBaseHealth()
    return (self._isUsingSummonsCustomBaseHealth == 1) or false
end

function modifier_item_nature_rapier_summon:GetModifierBonusHealthPercentage()
    if(self:IsUsingSummonsCustomBaseHealth() == true) then
        return 0
    end
    return self.bonusMaxHpPct
end

function modifier_item_nature_rapier_summon:GetModifierBonusHealth()
    if(self:IsUsingSummonsCustomBaseHealth() == false) then
        return 0
    end
	return self.bonusMaxHealthPctValueForSummonsWithCustomBaseHealth
end

function modifier_item_nature_rapier_summon:AddCustomTransmitterData()
    return
    {
        bonusMaxHpPct = self.bonusMaxHpPct,
        bonusHealthRegeneration = self.bonusHealthRegeneration,
        bonusBAT = self.bonusBAT,
        bonusArmor = self.bonusArmor,
        bonusDamage = self.bonusDamage,
        bonusSpellAmp = self.bonusSpellAmp,
        bonusStatsMultiplier = self.bonusStatsMultiplier,
        _isUsingSummonsCustomBaseHealth = self:IsUsingSummonsCustomBaseHealth(),
        bonusMaxHealthPctForSummonsWithCustomBaseHealth = self.bonusMaxHealthPctForSummonsWithCustomBaseHealth
    }
end

function modifier_item_nature_rapier_summon:HandleCustomTransmitterData(data)
    for k,v in pairs(data) do
        self[k] = v
    end
end

if(IsServer() and not _G._initItemNatureRapier) then
    OpenEvents:RegisterEventHandler(
        OPEN_EVENT_ON_PLAYER_ORDER, 
        function(params)
            if(params.entindex_ability > 0) then
                local ability = EntIndexToHScript(params.entindex_ability)
                if(ability and ability:IsNull() == false and ability.GetAbilityName and ability:GetAbilityName() == "item_nature_rapier") then
                    ability:OnOpenEventsCastOrder(ability, params.order_type, params.entindex_target)
                end
            end
        end
    )
    _G._initItemNatureRapier = true
end


item_nature_rapier_1 = class(item_nature_rapier)
item_nature_rapier_2 = class(item_nature_rapier)
item_nature_rapier_3 = class(item_nature_rapier)
item_nature_rapier_4 = class(item_nature_rapier)

LinkLuaModifier("modifier_item_nature_rapier", "items/custom/item_nature_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_nature_rapier)
LinkLuaModifier("modifier_item_nature_rapier_summon", "items/custom/item_nature_rapier", LUA_MODIFIER_MOTION_NONE, modifier_item_nature_rapier_summon)
