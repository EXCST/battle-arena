require('items/generic_datadriven_item')

item_refresher_orb = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_refresher_orb"
    end
})

function item_refresher_orb:Precache(context)
    PrecacheResource("particle", "particles/items2_fx/refresher.vpcf", context)
end

function item_refresher_orb:GetCooldown(iLevel)
    local caster = self:GetCaster()
    local baseCooldown = self.BaseClass.GetCooldown(self, iLevel)
    return baseCooldown / caster:GetCooldownReduction()
end

function item_refresher_orb:IsRefreshable()
    return false
end

function item_refresher_orb:OnSpellStart()
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

item_refresher_orb_1 = class(item_refresher_orb)
item_refresher_orb_2 = class(item_refresher_orb)

modifier_item_refresher_orb = class({
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
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
        }
    end
})

function modifier_item_refresher_orb:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_refresher_orb:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_mana = self.ability:GetSpecialValueFor("bonus_mana")
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
end

function modifier_item_refresher_orb:GetModifierExtraManaBonus()
    return self.bonus_mana
end

function modifier_item_refresher_orb:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_refresher_orb:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_refresher_orb:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

LinkLuaModifier("modifier_item_refresher_orb", "items/item_refresher_orb", LUA_MODIFIER_MOTION_NONE, modifier_item_refresher_orb)

