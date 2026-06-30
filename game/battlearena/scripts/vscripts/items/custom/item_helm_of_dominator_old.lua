require('items/generic_datadriven_item')


item_helm_of_dominator_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_helm_of_dominator_custom"
    end
})

modifier_item_helm_of_dominator_custom = class({
    IsHidden = function() 
        return true 
    end,
	IsPurgable = function() 
        return false 
    end,
	IsPermanent = function() 
        return true 
    end,
	DeclareFunctions = function() 
        return 
        {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
	    
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } 
    end,
    GetModifierBonusStats_Strength = function(self)
		return self.bonusStr
	end,
	GetModifierBonusStats_Agility = function(self)
		return self.bonusAgi
	end,
	GetModifierBonusStats_Intellect = function(self)
		return self.bonusInt
	end,
    GetAttributes = function() 
        return MODIFIER_ATTRIBUTE_MULTIPLE 
    end
})

function modifier_item_helm_of_dominator_custom:OnCreated()
    self.parent = self:GetParent()
	self.ability = self:GetAbility()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.auraModifier = self.parent:AddNewModifier(self.parent, self.ability, "modifier_item_helm_of_dominator_custom_aura", {duration = -1})
end

function modifier_item_helm_of_dominator_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
	self.bonusStr = self.ability:GetSpecialValueFor("bonus_allstats")
	self.bonusAgi = self.ability:GetSpecialValueFor("bonus_allstats")
	self.bonusInt = self.ability:GetSpecialValueFor("bonus_allstats")
end

function modifier_item_helm_of_dominator_custom:OnDestroy()
    if(not IsServer()) then
        return
    end
    if(self.parent:HasModifier("modifier_item_helm_of_dominator_custom") == false) then
        self.parent:RemoveModifierByName("modifier_item_helm_of_dominator_custom_aura")
    end
end

modifier_item_helm_of_dominator_custom_aura = class({
    IsHidden = function() 
        return true 
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
    GetAuraRadius = function()
        return FIND_UNITS_EVERYWHERE
    end,
    GetAuraSearchFlags = function()
        return DOTA_UNIT_TARGET_FLAG_INVULNERABLE 
    end,
    GetAuraSearchTeam = function()
        return DOTA_UNIT_TARGET_TEAM_FRIENDLY 
    end,
    IsAura = function()
        return true
    end,
    GetAuraSearchType = function()
        return DOTA_UNIT_TARGET_ALL
    end,
    GetModifierAura = function()
        return "modifier_item_helm_of_dominator_custom_aura_buff"
    end,
    GetAuraDuration = function()
        return 0
    end,
    IsAuraActiveOnDeath = function()
        return true
    end
})

function modifier_item_helm_of_dominator_custom_aura:OnCreated()
    self.parent = self:GetParent()
    if(not IsServer()) then
        return
    end
    local rapierAbility = self:GetAbility()
    local rapierKV = rapierAbility:GetAbilityKeyValues()
    self.creepsIgnoreList = rapierKV["IgnoreList"] or {}
end

function modifier_item_helm_of_dominator_custom_aura:GetAuraEntityReject(npc)
    if(npc:GetOwner() == self.parent) then
        if(npc:HasModifier("modifier_item_nature_rapier_summon") or npc:IsBuilding() == true) then
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

modifier_item_helm_of_dominator_custom_aura_buff = class({
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
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_TOOLTIP
        
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
    GetModifierPreAttack_BonusDamage = function(self)
        return self.bonusDamage
    end,
    GetModifierSpellAmplify_Percentage = function(self)
        return self.bonusSpellAmp
    end
})

-- HandleCustomTransmitterData called before OnCreated. No idea how and even why
function modifier_item_helm_of_dominator_custom_aura_buff:OnCreated()
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

function modifier_item_helm_of_dominator_custom_aura_buff:OnRefresh()
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

function modifier_item_helm_of_dominator_custom_aura_buff:OnTooltip()
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

function modifier_item_helm_of_dominator_custom_aura_buff:OnIntervalThink()
    if(not self.auraOwner.GetStrength) then
        return 
    end
    local propertiesRequireUpdate = 0
    local precision = 0.01
    local str = self.auraOwner:GetStrength()
    local agi = self.auraOwner:GetAgility()
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

function modifier_item_helm_of_dominator_custom_aura_buff:SetIsUsingSummonsCustomBaseHealth(state)
    if(state ~= true and state ~= false) then
        Debug_PrintError("Attempt to call modifier_item_helm_of_dominator_custom_aura_buff:SetIsUsingSummonsCustomBaseHealth with invalid state argument. Boolean expected, got "..tostring(state).." ("..type(state)..")")
        return
    end
    self._isUsingSummonsCustomBaseHealth = state == true and 1 or 0
end

function modifier_item_helm_of_dominator_custom_aura_buff:IsUsingSummonsCustomBaseHealth()
    return (self._isUsingSummonsCustomBaseHealth == 1) or false
end

function modifier_item_helm_of_dominator_custom_aura_buff:GetModifierBonusHealthPercentage()
    if(self:IsUsingSummonsCustomBaseHealth() == true) then
        return 0
    end
    return self.bonusMaxHpPct
end

function modifier_item_helm_of_dominator_custom_aura_buff:GetModifierBonusHealth()
    if(self:IsUsingSummonsCustomBaseHealth() == false) then
        return 0
    end
	return self.bonusMaxHealthPctValueForSummonsWithCustomBaseHealth
end

function modifier_item_helm_of_dominator_custom_aura_buff:AddCustomTransmitterData()
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

function modifier_item_helm_of_dominator_custom_aura_buff:HandleCustomTransmitterData(data)
    for k,v in pairs(data) do
        self[k] = v
    end
end

item_rd_dominator_1 = class(item_helm_of_dominator_custom)
item_rd_dominator_2 = class(item_helm_of_dominator_custom)
item_rd_dominator_3 = class(item_helm_of_dominator_custom)



LinkLuaModifier("modifier_item_helm_of_dominator_custom", "items/custom/item_helm_of_dominator", LUA_MODIFIER_MOTION_NONE, modifier_item_helm_of_dominator_custom)
LinkLuaModifier("modifier_item_helm_of_dominator_custom_aura", "items/custom/item_helm_of_dominator", LUA_MODIFIER_MOTION_NONE, modifier_item_helm_of_dominator_custom_aura)
LinkLuaModifier("modifier_item_helm_of_dominator_custom_aura_buff", "items/custom/item_helm_of_dominator", LUA_MODIFIER_MOTION_NONE, modifier_item_helm_of_dominator_custom_aura_buff)
