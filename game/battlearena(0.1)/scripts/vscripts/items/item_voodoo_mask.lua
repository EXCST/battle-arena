require('items/generic_datadriven_item')

item_voodoo_mask_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_voodoo_mask_custom"
    end
})

modifier_item_voodoo_mask_custom = class({
    IsHidden  = function() 
        return true 
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
	DeclareFunctions = function() 
        return 
        {
            MODIFIER_EVENT_ON_TAKEDAMAGE
	    }
    end
})

function modifier_item_voodoo_mask_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_voodoo_mask_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.spellLifestealFlat = self.ability:GetSpecialValueFor("spell_lifesteal_flat")
end

function modifier_item_voodoo_mask_custom:OnTakeDamage(kv)
    if(kv.attacker ~= self.parent or kv.unit == self.parent) then
        return
    end
    if(self.ability:IsCooldownReady() == false) then
        return
    end
    if(kv.inflictor == nil) then
        return
    end
    self.parent:PerformSpellLifesteal(kv.unit, kv.inflictor, self.spellLifestealFlat)
    self.ability:UseResources(true, false, true, true)
end

LinkLuaModifier("modifier_item_voodoo_mask_custom", "items/item_voodoo_mask", LUA_MODIFIER_MOTION_NONE, modifier_item_voodoo_mask_custom)