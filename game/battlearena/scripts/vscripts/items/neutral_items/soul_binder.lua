item_soul_binder = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_soul_binder"
    end
})

function item_soul_binder:Precache(context)
    PrecacheResource("particle", "particles/custom/items/soul_binder/tether.vpcf", context)
end

function item_soul_binder:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    if(caster == target) then
        self:ClearBindedSouls()
        return
    end
    local modifier = self:GetModifier()
    modifier:SetBindedSouls(caster, target)
    EmitSoundOn("Item.SoulBinder.Cast", target)
    self:EndCooldown()
end

function item_soul_binder:SetModifier(value)
    self._modifier = value
end

function item_soul_binder:GetModifier()
    return self._modifier
end

function item_soul_binder:ClearBindedSouls()
    self._modifier:ClearBindedSouls()
end

modifier_item_soul_binder = class({
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
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
        }
    end,
    GetModifierConstantHealthRegen = function(self)
        return self.bonusHealthRegeneration
    end,
    GetModifierConstantManaRegen = function(self)
        return self.bonusManaRegeneration
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_soul_binder:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.ability:SetModifier(self)
end

function modifier_item_soul_binder:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealthRegeneration = self.ability:GetSpecialValueFor("bonus_hp_regen")
    self.bonusManaRegeneration = self.ability:GetSpecialValueFor("bonus_mp_regen")
end

function modifier_item_soul_binder:OnDestroy()
    if(not IsServer()) then
        return
    end
    self:ClearBindedSouls()
end

function modifier_item_soul_binder:ClearBindedSouls()
    local isThereIsAtLeastOneSoul = false
    if(self._sourceModifier and self._sourceModifier:IsNull() == false) then
        self._sourceModifier:Destroy()
        isThereIsAtLeastOneSoul = isThereIsAtLeastOneSoul or true
    end
    self._sourceModifier = nil
    if(self._targetModifier and self._targetModifier:IsNull() == false) then
        self._targetModifier:Destroy()
        isThereIsAtLeastOneSoul = isThereIsAtLeastOneSoul or true
    end
    self._targetModifier = nil
    if(isThereIsAtLeastOneSoul) then
        self.ability:UseResources(true, false, true, true)
    end
end

function modifier_item_soul_binder:SetBindedSouls(source, target)
    self:ClearBindedSouls()
    self._targetModifier = target:AddNewModifier(source, self.ability, "modifier_item_soul_binder_buff", {duration = -1})
    self._sourceModifier = source:AddNewModifier(source, self.ability, "modifier_item_soul_binder_buff", {duration = -1})
    if(self._sourceModifier and self._targetModifier) then
        self._sourceModifier:SetTargetModifier(self._targetModifier)
    end
end

modifier_item_soul_binder_buff = class({
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
        return false
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_EVENT_ROSHDEF_ON_HEAL_RECEIVED,
            MODIFIER_EVENT_ON_MANA_GAINED,
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
        }
    end
})

function modifier_item_soul_binder_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.damageTable = {
		victim = self.ability:GetCaster(),
		attacker = self.parent,
		damage = 0,
		damage_type = DAMAGE_TYPE_PHYSICAL,
		ability = self.ability,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS 
        + DOTA_DAMAGE_FLAG_REFLECTION 
        + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION 
        + DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY
        + DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
	}
    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_item_soul_binder_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonusHealthTransferPct = self.ability:GetSpecialValueFor("hp_transfer_pct") / 100
    self.bonusManaTransferPct = self.ability:GetSpecialValueFor("mp_transfer_pct") / 100
    self.bonusDamageTransferPct = self.ability:GetSpecialValueFor("dmg_transfer_increase_pct") / 100
    self.maxRange = self.ability:GetSpecialValueFor("max_range") ^ 2
end

function modifier_item_soul_binder_buff:OnIntervalThink()
    local targetModifier = self:GetTargetModifier()
    if(targetModifier == nil) then
        return
    end
    self:CreateParticle()
    local target = self:GetTarget()
    if(not target or target:IsNull() == true or target:IsAlive() == false) then
        self.ability:ClearBindedSouls()
        return
    end
    if(CalculateDistanceSqr(self.parent, target) > self.maxRange) then
        self.ability:ClearBindedSouls()
    end
end

function modifier_item_soul_binder_buff:OnDestroy()
    if(not IsServer()) then
        return
    end
    self.ability:ClearBindedSouls()
    StopSoundEvent("Item.SoulBinder.Loop", self.parent)
    EmitSoundOn("Item.SoulBinder.End", self.parent)
end

function modifier_item_soul_binder_buff:CreateParticle()
    if(self._particle) then
        return
    end
    local target = self:GetTarget()
    if(not target) then
        return
    end
    local particle = ParticleManager:CreateParticle(
        "particles/custom/items/soul_binder/tether.vpcf",
        PATTACH_CUSTOMORIGIN,
        nil
    )
    ParticleManager:SetParticleControlEnt(particle, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    self:AddParticle(particle, false, false, 1, false, false)
    self._particle = particle
end

function modifier_item_soul_binder_buff:GetTargetModifier()
    if(self._targetModifier and self._targetModifier:IsNull() == false) then
        return self._targetModifier
    end
    return nil
end

function modifier_item_soul_binder_buff:SetTargetModifier(modifier)
    self._targetModifier = modifier
    self._target = self._targetModifier:GetParent()
    StartSoundEvent("Item.SoulBinder.Loop", self.parent)
end

function modifier_item_soul_binder_buff:GetTarget()
    return self._target
end

function modifier_item_soul_binder_buff:GetModifierIncomingDamage_Percentage(kv)
    local targetModifier = self:GetTargetModifier()
    if(targetModifier == nil) then
        return
    end
    local healthAfterDamage = self.parent:GetHealth() - kv.damage
    if(healthAfterDamage < 1) then
        self.damageTable.damage_type = kv.damage_type
        self.damageTable.damage = kv.damage * self.bonusDamageTransferPct
        ApplyDamage(self.damageTable)
        return -999999
    end
    return 0
end

function modifier_item_soul_binder_buff:OnHealReceived(kv)
    if(kv.target ~= self.parent) then
        return
    end
    local targetModifier = self:GetTargetModifier()
    if(targetModifier == nil) then
        return
    end
    targetModifier:TransferHeal(self.parent, kv.healing * self.bonusHealthTransferPct)
end

function modifier_item_soul_binder_buff:TransferHeal(source, heal)
    self.parent:Heal(heal, source, DOTA_HEAL_TYPE_HEALING)
end

function modifier_item_soul_binder_buff:OnManaGained(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    local targetModifier = self:GetTargetModifier()
    if(targetModifier == nil) then
        return
    end
    targetModifier:TransferMana(self.parent, kv.gain * self.bonusManaTransferPct)
end

function modifier_item_soul_binder_buff:TransferMana(source, mana)
    self.parent:GiveMana(mana)
end

LinkLuaModifier("modifier_item_soul_binder", "items/neutral_items/soul_binder", LUA_MODIFIER_MOTION_NONE, modifier_item_soul_binder)
LinkLuaModifier("modifier_item_soul_binder_buff", "items/neutral_items/soul_binder", LUA_MODIFIER_MOTION_NONE, modifier_item_soul_binder_buff)