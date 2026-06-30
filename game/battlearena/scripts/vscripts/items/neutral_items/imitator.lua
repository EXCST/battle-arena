item_imitator = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_imitator"
    end
})

function item_imitator:Precache(context)
    PrecacheResource("particle", "particles/custom/items/imitator/status_effect/status_effect_imitator.vpcf", context)
    PrecacheResource("particle", "particles/custom/items/imitator/effect.vpcf", context)
end

function item_imitator:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    if(caster:IsRealHero() == false) then
        PlayerResource:SendCustomErrorMessageToPlayer(caster:GetPlayerOwnerID(), "dota_hud_error_cant_cast_on_other")
        self:EndCooldown()
        self:RefundManaCost()
        return
    end
    local illusionDuration = self:GetSpecialValueFor("duration")
    local illusions = CreateIllusions(
		caster, 
		caster, 
		{
			outgoing_damage 			= 0,
			incoming_damage				= 0,
			bounty_base					= caster:GetLevel() * 2,
			bounty_growth				= nil,
			outgoing_damage_structure	= nil,
			outgoing_damage_roshan		= nil,
			duration					= illusionDuration
		},
		1,
		72, 
		false, 
		true
	)
    for _, illusion in pairs(illusions) do
        illusion:AddNewModifier(caster, self, "modifier_item_imitator_buff", {duration = illusionDuration})
    end
	EmitSoundOn("Item.IllusionstsCape.Activate", caster)
end

modifier_item_imitator = class({
    IsHidden = function() 
        return true 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_ROSHDEF_STATS_INTELLECT_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
        }
    end,
    GetModifierBonusStats_Intellect_Percentage = function(self)
        return self.bonusIntPct
    end,
    GetModifierSpellAmplify_Percentage = function(self)
        return self.bonusSpellAmplification
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_imitator:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_imitator:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusIntPct = self.ability:GetSpecialValueFor("bonus_intellect_pct")
    self.bonusSpellAmplification = self.ability:GetSpecialValueFor("bonus_spell_amp")
end

modifier_item_imitator_buff = class({
    IsHidden = function() 
        return true 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
            MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
            MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
            MODIFIER_EVENT_ON_ORDER,
            MODIFIER_EVENT_ON_SPENT_MANA,
            MODIFIER_EVENT_ON_DEATH
        }
    end,
    CheckState = function()
        return {
            [MODIFIER_STATE_INVULNERABLE] = true,
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_NO_HEALTH_BAR] = true,
            [MODIFIER_STATE_DISARMED] = true,
            [MODIFIER_STATE_UNSELECTABLE] = true
        }
    end,
    GetStatusEffectName = function()
        return "particles/custom/items/imitator/status_effect/status_effect_imitator.vpcf"
    end,
    StatusEffectPriority = function()
        return 999999
    end,
    GetModifierTotalDamageOutgoing_Percentage = function(self)
        return self.bonusTotalDamageOutgoing
    end,
    GetModifierIncomingDamage_Percentage = function(self)
        return -999999
    end,
})

function modifier_item_imitator_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self.caster = self.ability:GetCaster()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    for i = 0, self.caster:GetAbilityCount() - 1, 1 do
        local ability = self.caster:GetAbilityByIndex(i)
        if(ability) then
            local illusionAbility = self.parent:FindAbilityByName(ability:GetAbilityName())
            if(ability:GetToggleState() and illusionAbility) then
                illusionAbility:ToggleAbility()
                if(illusionAbility:GetToggleState() == false) then
                    illusionAbility:ToggleAbility()
                end
            end
            if(ability:GetAutoCastState() and illusionAbility) then
                illusionAbility:ToggleAutoCast()
                if(illusionAbility:GetAutoCastState() == false) then
                    illusionAbility:ToggleAutoCast()
                end
            end
        end
    end
    self:LoadForbiddenItems()
    self:FixChannelForIllusion()
    self:CreateTimerParticle()
    self:OnIntervalThink()
    self:StartIntervalThink(1)
end

function modifier_item_imitator_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonusTotalDamageOutgoing = self.ability:GetSpecialValueFor("illusion_outgoing_damage_pct") - 100
    self.castDelay = self.ability:GetSpecialValueFor("illusion_cast_delay")
end

function modifier_item_imitator_buff:LoadForbiddenItems()
    self._forbiddenItems = {}
    for _, itemName in pairs(self.ability:GetAbilityKeyValues()["ForbiddenItems"] or {}) do
        self._forbiddenItems[itemName] = true
    end
end

function modifier_item_imitator_buff:IsItemAllowedToReplicate(itemName)
    if(self._forbiddenItems[itemName]) then
        return false
    end
    return true
end

function modifier_item_imitator_buff:FixChannelForIllusion()
    self.parent.IsChanneling = function(self)
        if(self._imitatorSetIsChanneling ~= nil) then
            return self._imitatorSetIsChanneling
        end
        return false
    end
    self.parent.SetIsChanneling = function(self, state)
        if(state ~= true and state ~= false) then
            Debug_PrintError("Attempt to call CDOTA_BaseNPC:SetIsChanneling with invalid state argument. Got ", state, "(", type(state), "), expected boolean.")
            return
        end
        self._imitatorSetIsChanneling = state
    end
    self.parent.InterruptChannel = function(self)
        self:SetIsChanneling(false)
    end
end

function modifier_item_imitator_buff:CreateTimerParticle()
    self._timerParticle = ParticleManager:CreateParticle(
        "particles/custom/items/imitator/effect.vpcf", 
        PATTACH_OVERHEAD_FOLLOW, 
        self.parent
    )
    self:UpdateTimerParticle()
end

function modifier_item_imitator_buff:UpdateTimerParticle()
    if(self._timerParticle) then
        local digits = tostring(math.floor(self:GetRemainingTime() + 0.5))
        local digitsCount = #tostring(digits)
        if(digitsCount == 1) then
            ParticleManager:SetParticleControl(self._timerParticle, 1, Vector(0, 0, digits:sub(1,1)))
            ParticleManager:SetParticleControl(self._timerParticle, 11, Vector(0, 1, 0))
        end
        if(digitsCount == 2) then
            ParticleManager:SetParticleControl(self._timerParticle, 1, Vector(0, digits:sub(2,2), digits:sub(1,1)))
            ParticleManager:SetParticleControl(self._timerParticle, 11, Vector(1, 2, 0))
        end
        if(digitsCount == 3) then
            ParticleManager:SetParticleControl(self._timerParticle, 1, Vector(digits:sub(3,3), digits:sub(2,2), digits:sub(1,1)))
            ParticleManager:SetParticleControl(self._timerParticle, 11, Vector(3, 3, 0))
        end
    end
end

function modifier_item_imitator_buff:OnIntervalThink()
    self:UpdateTimerParticle()
    if(self.parent:IsChanneling() or self.parent:GetCurrentActiveAbility() ~= nil) then
        return
    end
    local pos = self.caster:GetAbsOrigin() + RandomVector(1) * RandomFloat(0, 300)
    ExecuteOrderFromTable({
        UnitIndex = self.parent:entindex(),
        OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        Position = pos
    })
end

function modifier_item_imitator_buff:OnOrder(kv)
    if(kv.unit ~= self.caster) then
        return
    end
    if(kv.order_type == DOTA_UNIT_ORDER_CAST_TOGGLE) then
        local illusionAbility = self.parent:FindAbilityByName(kv.ability:GetAbilityName())
        if(illusionAbility) then
            illusionAbility:ToggleAbility()
        end
    end
    if(kv.order_type == DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO) then
        local illusionAbility = self.parent:FindAbilityByName(kv.ability:GetAbilityName())
        if(illusionAbility) then
            illusionAbility:ToggleAutoCast()
        end
    end
end

function modifier_item_imitator_buff:OnAbilityFullyCast(kv)
    if(kv.unit ~= self.caster) then
        return
    end
    local channelTime = kv.ability:GetChannelTime()
    local isChannel = channelTime > 0
    local thisItemAbility = self.ability:GetAbilityName()
    local abilityName = kv.ability:GetAbilityName()
    local isItem = kv.ability:IsItem()
    local targetPoint = kv.ability:GetCursorPosition()
    Timers:CreateTimer(self.castDelay, function()
        if(self and self:IsNull() == false and self.parent and self.parent:IsNull() == false) then
            if(abilityName == thisItemAbility) then
                return
            end
            local ability = nil
            if(isItem) then
                if(self:IsItemAllowedToReplicate(abilityName)) then
                    ability = self.parent:FindItemInInventory(abilityName)
                end
            else
                ability = self.parent:FindAbilityByName(abilityName)
            end
            if(ability) then
                self.parent:InterruptChannel()
                local target = nil
                self.parent:SetCursorCastTarget(nil)
                if(kv.target) then
                    self.parent:SetCursorCastTarget(kv.target)
                    target = kv.target
                end
                if(targetPoint:Length2D() > 0) then
                    self.parent:SetCursorPosition(targetPoint)
                    target = targetPoint
                end
                if(target) then
                    self.parent:Stop()
                    self.parent:SetForwardVector(CalculateDirection(target, self.parent))
                end
                if(isChannel) then
                    self:BeginAbilityChannel(ability, channelTime)
                end
                if(ability:IsVectorTarget()) then
                    local illusionOwnerAbility = self.caster:FindAbilityByName(ability:GetAbilityName())
                    if(illusionOwnerAbility) then
                        local position = illusionOwnerAbility:GetVectorPosition()
                        local position2 = illusionOwnerAbility:GetVector2Position()
                        local direction = illusionOwnerAbility:GetVectorDirection()
                        ability:SetVectorPosition(position)
                        ability:SetVector2Position(position2)
                        ability:SetVectorDirection(direction)
                        ability:OnVectorCastStart(position, direction)
                    end
                end
                ability:CastAbility()
                if(ability.GetCastAnimation) then
                    local animation = ability:GetCastAnimation()
                    self.parent:StartGesture(animation)
                end
                ability:EndCooldown()
                ability:RefreshCharges()
            end
        end
    end, self)
end

function modifier_item_imitator_buff:BeginAbilityChannel(ability, channelTime)
    self.parent:SetIsChanneling(true)
    ability:SetChanneling(true)
    local currentChannelTime = 0
    local interval = 0.03
    Timers:CreateTimer(0, function()
        currentChannelTime = currentChannelTime + interval
        local isChannelEnded = currentChannelTime > channelTime
        local isInterrupt = false
        isInterrupt = isInterrupt or self.parent:IsStunned()
        isInterrupt = isInterrupt or self.parent:IsSilenced()
        isInterrupt = isInterrupt or self.parent:IsHexed()
        isInterrupt = isInterrupt or self.parent:IsFrozen()
        isInterrupt = isInterrupt or self.parent:IsNightmared()
        isInterrupt = isInterrupt or self.parent:IsCommandRestricted()
        isInterrupt = isInterrupt or self.parent:IsAlive() == false
        isInterrupt = isInterrupt or self.parent:IsChanneling() == false
        if(isChannelEnded == true or isInterrupt == true) then
            ability:OnChannelFinish(isInterrupt == true)
            ability:SetChanneling(false)
            self.parent:SetIsChanneling(false)
            return
        end
        ability:OnChannelThink(interval)
        return interval
    end)
end

function modifier_item_imitator_buff:OnSpentMana(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    self.parent:SetMana(self.parent:GetMana() + kv.cost)
end

function modifier_item_imitator_buff:OnDeath(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    local unit = Entities:First()
    while unit ~= nil do

        if(unit.GetUnitName and unit ~= self.parent and unit:GetOwnerEntity() == self.parent and unit:IsCourier() == false) then
            if(unit:HasInventory()) then
                local position = unit:GetAbsOrigin()
                for i = 0, DOTA_ITEM_MAX do
                    local itemInSlot = unit:GetItemInSlot(i)
                    if (itemInSlot and itemInSlot:IsNull() == false) then
                        unit:DropItemAtPositionImmediate(itemInSlot, position)
                    end
                end
            end
            unit:Kill(nil,nil)
            UTIL_Remove(unit)
        end
        unit = Entities:Next(unit)
    end
end

LinkLuaModifier("modifier_item_imitator", "items/neutral_items/imitator", LUA_MODIFIER_MOTION_NONE, modifier_item_imitator)
LinkLuaModifier("modifier_item_imitator_buff", "items/neutral_items/imitator", LUA_MODIFIER_MOTION_NONE, modifier_item_imitator_buff)