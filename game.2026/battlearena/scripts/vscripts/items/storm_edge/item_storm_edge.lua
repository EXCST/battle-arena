require('items/generic_datadriven_item')

item_storm_edge = class({})
LinkLuaModifier("modifier_item_storm_edge", "items/storm_edge/item_storm_edge", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_storm_edge_active", "items/storm_edge/item_storm_edge", LUA_MODIFIER_MOTION_NONE)
function item_storm_edge:GetIntrinsicModifierName() return "modifier_item_storm_edge" end

function item_storm_edge:OnSpellStart()
    local target = self:GetCursorTarget()
    local caster = self:GetCaster()

    ProjectileManager:CreateTrackingProjectile({
        Ability = self,
        Source = caster,
        EffectName = "particles/units/heroes/hero_visage/visage_soul_assumption_bolt.vpcf",
        Target = target,
        iMoveSpeed = self:GetSpecialValueFor("proj_ms"),
        bDodgeable = true,
    })

    EmitSoundOn("DOTA_Item.UrnOfShadows.Activate", caster)
end

function item_storm_edge:OnProjectileHit(target, pos)
    if not IsServer() then return end
    if not target or target:TriggerSpellAbsorb(self) or target:TriggerSpellReflect( self ) then return true end
    if target:IsMagicImmune() then return true end
    
    target:AddNewModifier( self:GetCaster(), self, "modifier_item_storm_edge_active", {duration=self:GetSpecialValueFor("duration")})
    return true
end

--====================================================================================================================

modifier_item_storm_edge = class({})
function modifier_item_storm_edge:IsHidden() return true end
function modifier_item_storm_edge:IsPermanent() return true end
function modifier_item_storm_edge:OnCreated()
    self.health_regen = self:GetAbility():GetSpecialValueFor("health_regen")
    self.mana_regen = self:GetAbility():GetSpecialValueFor("mana_regen")
    self.mana = self:GetAbility():GetSpecialValueFor("mana")
    self.armour = self:GetAbility():GetSpecialValueFor("armour")
end
function modifier_item_storm_edge:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end

function modifier_item_storm_edge:GetModifierConstantHealthRegen() return self.health_regen end
function modifier_item_storm_edge:GetModifierConstantManaRegen() return self.mana_regen end
function modifier_item_storm_edge:GetModifierExtraManaBonus() return self.mana end
function modifier_item_storm_edge:GetModifierPhysicalArmorBonus() return self.armour end

--====================================================================================================================

modifier_item_storm_edge_active = class({})
function modifier_item_storm_edge_active:IsPurgable() return true end
function modifier_item_storm_edge_active:IsDebuff() return true end
function modifier_item_storm_edge_active:GetTexture() return "custom/storm_edge" end
function modifier_item_storm_edge_active:GetStatusEffectName() return "particles/items3_fx/status_effect_mage_slayer_debuff.vpcf" end 
function modifier_item_storm_edge_active:OnCreated() self.reduction = -1*self:GetAbility():GetSpecialValueFor("reduction") end
function modifier_item_storm_edge_active:CheckState() return {[MODIFIER_STATE_PASSIVES_DISABLED] = true} end
function modifier_item_storm_edge_active:DeclareFunctions() return {MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING} end
function modifier_item_storm_edge_active:GetModifierStatusResistanceStacking() return self.reduction end