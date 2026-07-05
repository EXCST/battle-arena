require('items/generic_datadriven_item')

item_spiked_shield = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_spiked_shield"
    end
})

item_spiked_shield_1 = class(item_spiked_shield)
item_spiked_shield_2 = class(item_spiked_shield)
item_spiked_shield_3 = class(item_spiked_shield)
item_spiked_shield_4 = class(item_spiked_shield)
item_spiked_shield_5 = class(item_spiked_shield)
item_spiked_shield_6 = class(item_spiked_shield)

modifier_item_spiked_shield = class({
    IsHidden                = function(self) return true end,
    DeclareFunctions       = function(self) return
         {
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
            MODIFIER_EVENT_ON_ATTACK_LANDED
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    GetModifierBonusHealth = function(self) return self.bonus_health end,
    GetModifierConstantHealthRegen = function(self) return self.bonus_hp_regen end
})

function modifier_item_spiked_shield:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_spiked_shield:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_hp_regen = self.ability:GetSpecialValueFor("bonus_hp_regen")

    self.return_damage = self.ability:GetSpecialValueFor("return_damage")
    self.return_damage_pct = self.ability:GetSpecialValueFor("return_damage_pct")
    if(not IsServer()) then
        return
    end
    self.damageTable = self.damageTable or {
        attacker = self.parent,
        victim = nil,
        damage = 0,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_REFLECTION,
        ability = self.ability
    }
end

function modifier_item_spiked_shield:OnAttackLanded(kv)
    if(kv.target ~= self.parent) then
        return
    end
    if(kv.attacker:GetTeam() == kv.target:GetTeam()) then
        return
    end
    self.damageTable.victim = kv.attacker
    self.damageTable.damage = self.return_damage + kv.original_damage * self.return_damage_pct/100
    ApplyDamage(self.damageTable)
end

LinkLuaModifier("modifier_item_spiked_shield", "items/item_spiked_shield", LUA_MODIFIER_MOTION_NONE, modifier_item_spiked_shield)