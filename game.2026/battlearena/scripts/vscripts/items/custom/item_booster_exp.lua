
item_booster_exp_1 = class({})
item_booster_exp_2 = item_booster_exp_1
item_booster_exp_3 = item_booster_exp_1
item_booster_gold_1 = item_booster_exp_1
item_booster_gold_2 = item_booster_exp_1
item_booster_gold_3 = item_booster_exp_1

function item_booster_exp_1:OnSpellStart()
    if (not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    if (caster:IsRealHero() == false) then
        return
    end
    local expPerTick = self:GetSpecialValueFor("exp_per_tick")
    local goldPerTick = self:GetSpecialValueFor("gold_per_tick")
    if (expPerTick > 0) then
        self:ApplyStackOfModifier(caster, "modifier_item_booster_exp", expPerTick)
    end
    if (goldPerTick > 0) then
        self:ApplyStackOfModifier(caster, "modifier_item_booster_gold", goldPerTick)
    end
    EmitSoundOn("DOTA_Item.ClarityPotion.Activate", caster)
    self:SpendCharge()
end

function item_booster_exp_1:ApplyStackOfModifier(caster, modifierName, stacks)
    if (not IsServer()) then
        return
    end
    local modifier = caster:FindModifierByName(modifierName)
    if (modifier) then
        modifier:SetStackCount(modifier:GetStackCount() + stacks)
    else
        modifier = caster:AddNewModifier(
                caster,
                self,
                modifierName,
                {
                    duration = -1
                }
        )
        modifier:SetStackCount(stacks)
    end
end

modifier_item_booster_exp = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsDebuff = function()
        return false
    end,
    RemoveOnDeath = function()
        return false
    end,
    GetAttributes = function()
        return MODIFIER_ATTRIBUTE_PERMANENT
    end,
    GetTexture = function()
        return "turbomode_bonus"
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_TOOLTIP
        }
    end
})

function modifier_item_booster_exp:OnCreated()
    if (not IsServer()) then
        return
    end
    self.parent = self:GetParent()
    self:StartIntervalThink(1)
end

function modifier_item_booster_exp:OnIntervalThink()
    if (not IsServer()) then
        return
    end
    local stacks = self:GetStackCount()
    self.parent:AddExperience(stacks, DOTA_ModifyXP_Unspecified, false, false)
end

function modifier_item_booster_exp:OnTooltip()
    return self:GetStackCount()
end

modifier_item_booster_gold = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsDebuff = function()
        return false
    end,
    RemoveOnDeath = function()
        return false
    end,
    GetAttributes = function()
        return MODIFIER_ATTRIBUTE_PERMANENT
    end,
    GetTexture = function()
        return "alchemist_goblins_greed"
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_TOOLTIP
        }
    end
})

function modifier_item_booster_gold:OnCreated()
    if (not IsServer()) then
        return
    end
    self.parent = self:GetParent()
    self:StartIntervalThink(1)
end

function modifier_item_booster_gold:OnIntervalThink()
    if (not IsServer()) then
        return
    end
    local stacks = self:GetStackCount()
    self.parent:ModifyGoldFiltered(stacks, true, DOTA_ModifyGold_GameTick)
end

function modifier_item_booster_gold:OnTooltip()
    return self:GetStackCount()
end


LinkLuaModifier("modifier_item_booster_exp", "items/custom/item_booster_exp", LUA_MODIFIER_MOTION_NONE, modifier_item_booster_exp)
LinkLuaModifier("modifier_item_booster_gold", "items/custom/item_booster_exp", LUA_MODIFIER_MOTION_NONE, modifier_item_booster_gold)
