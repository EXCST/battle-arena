
item_base_with_optional_unit_target = class({})

function item_base_with_optional_unit_target:Spawn()
    if(not IsServer()) then
        return
    end
    if(IsInToolsMode() == true) then
        local behaviorInKV = self:GetBehaviorInt()
        local isBehaviorValid = bit.band(behaviorInKV, DOTA_ABILITY_BEHAVIOR_OPTIONAL_UNIT_TARGET) ~= DOTA_ABILITY_BEHAVIOR_OPTIONAL_UNIT_TARGET
        isBehaviorValid = isBehaviorValid and bit.band(behaviorInKV, DOTA_ABILITY_BEHAVIOR_NO_TARGET) ~= DOTA_ABILITY_BEHAVIOR_NO_TARGET
        if(isBehaviorValid == false) then
            print("This ability must have at least next behavior to make all work: DOTA_ABILITY_BEHAVIOR_NO_TARGET | DOTA_ABILITY_BEHAVIOR_OPTIONAL_UNIT_TARGET")
            Debug_PrintError("Attempt to use item_base_with_optional_unit_target for "..tostring(self:GetAbilityName()).." with unsupported behavior. Fix this or change base class.")
        end
    end
    self:_SetBehavior(self:_GetBehaviorForNoTargetState())
end

function item_base_with_optional_unit_target:_GetBehaviorForUnitTargetState()
    return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
end

function item_base_with_optional_unit_target:_GetBehaviorForNoTargetState()
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
end

function item_base_with_optional_unit_target:GetBehavior()
    if(IsServer()) then
        return self._behavior
    end
    return self.BaseClass.GetBehavior(self)
end

function item_base_with_optional_unit_target:_SetBehavior(value)
    self._behavior = value
end

function item_base_with_optional_unit_target:_IsItemWithOptionalUnitTarget()
    return true
end

function item_base_with_optional_unit_target:OnOpenEventsCastOrder(orderType, orderTargetEntIndex)
    if(orderType == DOTA_UNIT_ORDER_CAST_TARGET) then
        self:_SetBehavior(self:_GetBehaviorForUnitTargetState())
        local caster = self:GetCaster()
        caster:AddNewModifier(caster, self, "modifier_item_base_with_optional_unit_target_tracker", {duration = -1})
    end
end

modifier_item_base_with_optional_unit_target_tracker = class({
    IsHidden = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    IsDebuff = function()
        return true -- = true + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + caster = target let bypass invulnerable flag and apply modifier
    end,
	DeclareFunctions = function()
		return {
           MODIFIER_EVENT_ON_ORDER
		}
	end,
    GetAttributes = function()
        return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
    end
})

function modifier_item_base_with_optional_unit_target_tracker:OnCreated()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
end

function modifier_item_base_with_optional_unit_target_tracker:OnOrder(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    if(kv.order_type == DOTA_UNIT_ORDER_CAST_TARGET) then
        self:Destroy()
        return
    end
    if(kv.order_type ~= DOTA_UNIT_ORDER_CAST_TARGET) then
        self:Destroy()
        return
    end
end

function modifier_item_base_with_optional_unit_target_tracker:OnDestroy()
    if(not IsServer()) then
        return
    end
    if(self.ability and self.ability:IsNull() == false) then
        self.ability:_SetBehavior(self.ability:_GetBehaviorForNoTargetState())
    end
end

if(IsServer() and not _G.initItemBaseWithOptionalUnitTarget) then
    OpenEvents:RegisterEventHandler(
        OPEN_EVENT_ON_PLAYER_ORDER, 
        function(params)
            if(params.entindex_ability > 0) then
                local ability = EntIndexToHScript(params.entindex_ability)
                if(ability and ability._IsItemWithOptionalUnitTarget and ability._IsItemWithOptionalUnitTarget() == true) then
                    ability:OnOpenEventsCastOrder(params.order_type, params.entindex_target)
                end
            end
        end
    )
    _G.initItemBaseWithOptionalUnitTarget = true
end


LinkLuaModifier("modifier_item_base_with_optional_unit_target_tracker", "items/custom/item_base_with_optional_unit_target", LUA_MODIFIER_MOTION_NONE, modifier_item_base_with_optional_unit_target_tracker)
