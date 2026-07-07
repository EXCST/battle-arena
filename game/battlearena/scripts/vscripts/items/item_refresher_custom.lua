require('items/generic_datadriven_item')

item_refresher_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_refresher_custom"
    end
})

function item_refresher_custom:Precache(context)
    PrecacheResource("particle", "particles/items2_fx/refresher.vpcf", context)
end

function item_refresher_custom:GetCooldown(iLevel)
    local caster = self:GetCaster()
    local baseCooldown = self.BaseClass.GetCooldown(self, iLevel)
    return baseCooldown / caster:GetCooldownReduction()
end

function item_refresher_custom:IsRefreshable()
    return false
end

function item_refresher_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    EmitSoundOn("RefresherCore.Activate", caster)
   
    local nFXIndex = ParticleManager:CreateParticle("particles/items2_fx/refresher.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControlEnt(nFXIndex, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetOrigin(), true)
    ParticleManager:ReleaseParticleIndex(nFXIndex, 2)

    for i=0, DOTA_MAX_ABILITIES-1, 1 do  
        local current_ability = caster:GetAbilityByIndex(i)
        if current_ability ~= nil then
            if current_ability:IsRefreshable() then 
                current_ability:RefreshCharges()
                current_ability:EndCooldown()
            end
        end
    end
    for i=0, DOTA_ITEM_MAX-1, 1 do
        local current_item = caster:GetItemInSlot(i)
        if current_item ~= nil and current_item:IsRefreshable() then
            current_item:EndCooldown()
        end
    end
end

item_refresher_custom_1 = class(item_refresher_custom)
item_refresher_custom_2 = class(item_refresher_custom)
item_refresher_custom_3 = class(item_refresher_custom)

item_potaro_1 = class(item_refresher_custom)
item_potaro_2 = class(item_refresher_custom)
item_potaro_3 = class(item_refresher_custom)

modifier_item_refresher_custom = class({
    IsHidden = function() 
        return true 
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
	GetAttributes = function() 
        return MODIFIER_ATTRIBUTE_MULTIPLE 
    end,
	DeclareFunctions = function() 
        return 
        {
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
        }
    end
})

function modifier_item_refresher_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_refresher_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_mana = self.ability:GetSpecialValueFor("bonus_mana")
    self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
end

function modifier_item_refresher_custom:GetModifierExtraManaBonus()
    return self.bonus_mana
end

function modifier_item_refresher_custom:GetModifierConstantManaRegen()
    return self.bonus_mp_regen
end

LinkLuaModifier("modifier_item_refresher_custom", "items/item_refresher_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_refresher_custom)

