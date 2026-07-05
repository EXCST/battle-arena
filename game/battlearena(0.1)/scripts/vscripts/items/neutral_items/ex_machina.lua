item_ex_machina_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_ex_machina_custom"
    end,
    IsRefreshable = function()
        return false
    end
})

function item_ex_machina_custom:Precache(context)
    PrecacheResource("particle", "particles/items2_fx/refresher.vpcf", context)
end

function item_ex_machina_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    EmitSoundOn("RefresherCore.Activate", caster)
   
    local nFXIndex = ParticleManager:CreateParticle("particles/items2_fx/refresher.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControlEnt(nFXIndex, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetOrigin(), true)
    ParticleManager:ReleaseParticleIndex(nFXIndex, 2)

    for i=0, DOTA_ITEM_MAX-1, 1 do
        local current_item = caster:GetItemInSlot(i)
        if current_item ~= nil and current_item:IsRefreshable() then
            current_item:EndCooldown()
        end
    end
end

modifier_item_ex_machina_custom = class({
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
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        }
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_ex_machina_custom:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_ex_machina_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
end

LinkLuaModifier("modifier_item_ex_machina_custom", "items/neutral_items/ex_machina", LUA_MODIFIER_MOTION_NONE, modifier_item_ex_machina_custom)