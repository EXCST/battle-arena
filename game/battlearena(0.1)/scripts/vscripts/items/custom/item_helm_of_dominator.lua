require('items/generic_datadriven_item')


item_helm_of_dominator_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_helm_of_dominator_custom"
    end
})

function item_helm_of_dominator_custom:CastFilterResultTarget(target)
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
    if(target:GetLevel() > self:GetSpecialValueFor("dominate_creep_lvl")) then
		return "wisp_infest_error_need_lvl"
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

function item_helm_of_dominator_custom:GetCustomCastErrorTarget(target)
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
    if(target:GetLevel() > self:GetSpecialValueFor("dominate_creep_lvl")) then
		return "wisp_infest_error_need_lvl"
	end
end

function item_helm_of_dominator_custom:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()

    if caster:HasModifier("modifier_item_helm_of_dominator_custom_aura_buff") then
	    if #caster:FindModifierByNameAndCaster("modifier_item_helm_of_dominator_custom_aura_buff", caster).dominator_controlled_unit == 1 then
	    	caster:FindModifierByNameAndCaster("modifier_item_helm_of_dominator_custom_aura_buff", caster).dominator_controlled_unit[1]:Kill(nil,nil)
	    	table.remove(caster:FindModifierByNameAndCaster("modifier_item_helm_of_dominator_custom_aura_buff", caster).dominator_controlled_unit, 1)
	    end
    end
	local unit = target:Dominate(self:GetCaster())
    if caster:HasModifier("modifier_item_helm_of_dominator_custom_aura_buff") then
	    table.insert(caster:FindModifierByNameAndCaster("modifier_item_helm_of_dominator_custom_aura_buff", caster).dominator_controlled_unit, unit)
    end
end

modifier_item_helm_of_dominator_custom = class({
    IsHidden = function() return true end,
	IsPurgable = function() return false end,
	IsPermanent = function() return true end,
	DeclareFunctions = function() return {
    	MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    	MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    	MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
	
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } end,
    GetModifierBonusStats_Strength = function(self) return self.bonusStr end,
	GetModifierBonusStats_Agility = function(self) return self.bonusAgi end,
	GetModifierBonusStats_Intellect = function(self) return self.bonusInt end,
	GetModifierConstantManaRegen = function(self) return self.bonus_mp_regen end,
    GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end
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
	self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
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
    IsHidden = function() return true end,
    IsPurgable = function() return false end,
    IsPurgeException = function() return false end,
    IsDebuff = function() return false end,
    GetAuraRadius = function() return FIND_UNITS_EVERYWHERE end,
    GetAuraSearchFlags = function() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end,
    GetAuraSearchTeam = function() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end,
    IsAura = function() return true end,
    GetAuraSearchType = function() return DOTA_UNIT_TARGET_ALL end,
    GetModifierAura = function() return "modifier_item_helm_of_dominator_custom_aura_buff" end,
    GetAuraDuration = function() return 0.5 end,
    IsAuraActiveOnDeath = function() return true end
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
    IsHidden = function() return false end,
    IsPurgable = function() return false end,
    IsPurgeException = function() return false end,
    IsDebuff = function() return false end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH_PERCENTAGE,
        MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
        MODIFIER_PROPERTY_ROSHDEF_BASE_ATTACK_BONUS_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_TOOLTIP
	
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } end,
    GetModifierBaseAttack_BonusDamagePercentage = function(self) return self.bonus_base_dmg_pct end,
})

-- HandleCustomTransmitterData called before OnCreated. No idea how and even why
function modifier_item_helm_of_dominator_custom_aura_buff:OnCreated()
    self.tooltipIndex = 0
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    if(not IsServer()) then
        return
    end
    self.parent = self:GetParent()
    self.auraOwner = self:GetAuraOwner()
    self.parentHealthPercent = self.parentHealthPercent or self.parent:GetHealthPercent() / 100
    self.bonusMaxHealthPctValueForSummonsWithCustomBaseHealth = self.bonusMaxHealthPctValueForSummonsWithCustomBaseHealth or 0
    self.bonusMaxHealthPctForSummonsWithCustomBaseHealth = self.bonusMaxHealthPctForSummonsWithCustomBaseHealth or 0
    self:SetHasCustomTransmitterData(true)
    self:OnRefresh()
    self.dominator_controlled_unit = {}
end

function modifier_item_helm_of_dominator_custom_aura_buff:OnDestroy()
    if(not IsServer()) then
        return
    end
    if #self.dominator_controlled_unit > 0 then
        self.dominator_controlled_unit[1]:Kill(nil,nil)
    end
    self.dominator_controlled_unit = nil
end

function modifier_item_helm_of_dominator_custom_aura_buff:OnRefresh()
    self.auraOwner = self:GetAuraOwner() or self.auraOwner
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonusMaxHpPct = self.ability:GetSpecialValueFor("bonus_base_hp_pct")
    self.bonus_base_dmg_pct = self.ability:GetSpecialValueFor("bonus_base_dmg_pct")
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
    self.bonusMaxHpPct = self.bonusMaxHpPct * self.bonusStatsMultiplier
    self:OnIntervalThink()
end

function modifier_item_helm_of_dominator_custom_aura_buff:OnIntervalThink()
    local customSummonBaseHealth = self.parent:GetSummonBaseMaxHealth()
    local isSummonUsingCustomBaseMaxHealth = (customSummonBaseHealth ~= nil)
    if(isSummonUsingCustomBaseMaxHealth == true) then
        self.bonusMaxHealthPctValueForSummonsWithCustomBaseHealth = (customSummonBaseHealth * (1 + (self.bonusMaxHpPct / 100))) - customSummonBaseHealth
        self.bonusMaxHealthPctForSummonsWithCustomBaseHealth = self.bonusMaxHpPct
    else
        self.bonusMaxHealthPctValueForSummonsWithCustomBaseHealth = 0
        self.bonusMaxHealthPctForSummonsWithCustomBaseHealth = self.bonusMaxHpPct
    end
    self:SetIsUsingSummonsCustomBaseHealth(isSummonUsingCustomBaseMaxHealth)
    if(not self._isFirstTick) then
        self.parent:SetHealth(self.parent:GetMaxHealth() * self.parentHealthPercent)
        self:SendBuffRefreshToClients()
        self.parent:CalculateGenericBonuses()
        self._isFirstTick = true
    end
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
        result = self.bonusStatsMultiplier * 100
    end
    self.tooltipIndex = self.tooltipIndex + 1
    if(self.tooltipIndex > 1) then
        self.tooltipIndex = 0
    end
    return result
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
    return self.bonusMaxHealthPctForSummonsWithCustomBaseHealth
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
        bonus_base_dmg_pct = self.bonus_base_dmg_pct,
        bonusStatsMultiplier = self.bonusStatsMultiplier,
        _isUsingSummonsCustomBaseHealth = self:IsUsingSummonsCustomBaseHealth(),
        bonusMaxHealthPctForSummonsWithCustomBaseHealth = self.bonusMaxHealthPctForSummonsWithCustomBaseHealth,
        bonusMaxHealthPctValueForSummonsWithCustomBaseHealth = self.bonusMaxHealthPctValueForSummonsWithCustomBaseHealth
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

item_rd_dominator_attack_1 = class(item_helm_of_dominator_custom)
item_rd_dominator_attack_2 = class(item_helm_of_dominator_custom)
item_rd_dominator_attack_3 = class(item_helm_of_dominator_custom)

item_rd_dominator_defense_1 = class(item_helm_of_dominator_custom)
item_rd_dominator_defense_2 = class(item_helm_of_dominator_custom)
item_rd_dominator_defense_3 = class(item_helm_of_dominator_custom)

LinkLuaModifier("modifier_item_helm_of_dominator_custom", "items/custom/item_helm_of_dominator", LUA_MODIFIER_MOTION_NONE, modifier_item_helm_of_dominator_custom)
LinkLuaModifier("modifier_item_helm_of_dominator_custom_aura", "items/custom/item_helm_of_dominator", LUA_MODIFIER_MOTION_NONE, modifier_item_helm_of_dominator_custom_aura)
LinkLuaModifier("modifier_item_helm_of_dominator_custom_aura_buff", "items/custom/item_helm_of_dominator", LUA_MODIFIER_MOTION_NONE, modifier_item_helm_of_dominator_custom_aura_buff)