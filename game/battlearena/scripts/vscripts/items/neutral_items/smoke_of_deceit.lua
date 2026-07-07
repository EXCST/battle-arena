item_smoke_of_deceit_custom = class({})

function item_smoke_of_deceit_custom:Precache(context)
    PrecacheResource("particle", "particles/items_fx/arcane_boots.vpcf", context)
    PrecacheResource("particle", "particles/items_fx/arcane_boots_recipient.vpcf", context)
end

function item_smoke_of_deceit_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_item_smoke_of_deceit_custom_buff", {duration = self:GetSpecialValueFor("duration")})
    EmitSoundOn("Item.SmokeOfDeceit.Cast", caster)
end

modifier_item_smoke_of_deceit_custom_buff = class({
    IsHidden = function() 
        return false 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return true
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
        }
    end,
    CheckState = function()
        return {
            [MODIFIER_STATE_INVISIBLE] = true
        }
    end,
    GetModifierInvisibilityLevel = function()
        return 1
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_smoke_of_deceit_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    end
end

function modifier_item_smoke_of_deceit_custom_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusMovespeedPct = self.ability:GetSpecialValueFor("bonus_movement_speed")
end

LinkLuaModifier("modifier_item_smoke_of_deceit_custom_buff", "items/neutral_items/smoke_of_deceit", LUA_MODIFIER_MOTION_NONE, modifier_item_smoke_of_deceit_custom_buff)