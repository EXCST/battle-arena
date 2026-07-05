item_demon_seal = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_demon_seal"
    end
})

function item_demon_seal:Precache(context)
    PrecacheUnitByNameSync("npc_demon_seal_demon", context)
    PrecacheResource("particle", "particles/econ/items/warlock/warlock_ti10_head/warlock_ti_10_fatal_bonds_cast.vpcf", context)
    PrecacheResource("particle", "particles/econ/items/warlock/warlock_ti10_head/warlock_ti_10_fatal_bonds_icon.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_warlock/warlock_rain_of_chaos.vpcf", context)
    PrecacheResource("particle", "particles/econ/items/warlock/warlock_hellsworn_construct/golem_hellsworn_ambient.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf", context)
end

function item_demon_seal:GetAbilityTextureName()
    local caster = self:GetCaster()
    if(caster:GetModifierStackCount(self:GetIntrinsicModifierName(), caster) == 1) then
        return "neutral/demon_seal_enabled"
    end
    return self.BaseClass.GetAbilityTextureName(self)
end

function item_demon_seal:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    if(caster.GetStrength == nil) then
		PlayerResource:SendCustomErrorMessageToPlayer(caster:GetPlayerOwnerID(), "dota_hud_error_cant_cast_on_considered_hero")
        return
    end
    local modifier = self:GetModifier()
    if(modifier:SwitchState()) then
        local health = caster:GetStrength() * self:GetSpecialValueFor("summon_hp_per_hero_str")
        local armor = caster:GetAgility() * self:GetSpecialValueFor("summon_armor_per_hero_agi")
        local attackDamage = caster:GetPrimaryStatValue() * self:GetSpecialValueFor("summon_damage_per_hero_int")
        local bat = self:GetSpecialValueFor("summon_bat")
        local demon = CreateSummon(
			caster, 
			"npc_demon_seal_demon", 
			caster:GetAbsOrigin(), 
			-1, 
			attackDamage, 
			armor, 
			health, 
			bat
		)
        demon:AddNewModifier(caster, self, "modifier_item_demon_seal_summon", {duration = -1})
        EmitSoundOn("Item.DemonSeal.Cast", demon)
        EmitSoundOn("Item.DemonSeal.Cast2", demon)
        local particle = ParticleManager:CreateParticle(
            "particles/units/heroes/hero_warlock/warlock_rain_of_chaos.vpcf", 
            PATTACH_ABSORIGIN, 
            demon
        )
        ParticleManager:SetParticleControl(particle, 1, Vector(400, 1, 1))
        ParticleManager:ReleaseParticleIndex(particle, 2)
        modifier:SetDemon(demon)
        self:EndCooldown()
    end
end

function item_demon_seal:SetModifier(modifier)
    self._modifier = modifier
end

function item_demon_seal:GetModifier()
    return self._modifier
end

function item_demon_seal:ToggleOff()
    self._modifier:ToggleOff()
end

modifier_item_demon_seal = class({
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
            MODIFIER_PROPERTY_ROSHDEF_STATS_STRENGTH_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_STATS_AGILITY_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_STATS_INTELLECT_BONUS_PERCENTAGE,
            MODIFIER_EVENT_ON_DEATH
        }
    end,
    GetModifierBonusStats_Strength_Percentage = function(self)
        return self.bonusAllStatsPct
    end,
    GetModifierBonusStats_Agility_Percentage = function(self)
        return self.bonusAllStatsPct
    end,
    GetModifierBonusStats_Intellect_Percentage = function(self)
        return self.bonusAllStatsPct
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_demon_seal:OnCreated()
    self.ability = self:GetAbility()
    self.owner = self.ability:GetCaster()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.ability:SetModifier(self)
end

function modifier_item_demon_seal:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAllStatsPct = self.ability:GetSpecialValueFor("bonus_allstats_pct")
end

function modifier_item_demon_seal:SetDemon(demon)
    self._demon = demon
end

function modifier_item_demon_seal:GetDemon()
    if(self._demon ~= nil and self._demon:IsNull() == false and self._demon:IsAlive() == true) then
        return self._demon
    end
    return nil
end

function modifier_item_demon_seal:SwitchState()
    if(self:GetStackCount() == 1) then
        self:ToggleOff()
        return false
    else
        self:SetStackCount(1)
        return true
    end
end

function modifier_item_demon_seal:ToggleOff()
    self.ability:UseResources(true, false, true, true)
    local demon = self:GetDemon()
    if(demon) then
        demon:Kill(nil,nil)
    end
    self:SetStackCount(0)
end

function modifier_item_demon_seal:OnDeath(kv)
    if(kv.unit ~= self.owner) then
        return
    end
    self:ToggleOff()
end

function modifier_item_demon_seal:OnDestroy()
    if(not IsServer()) then
        return
    end
    self:ToggleOff()
end

modifier_item_demon_seal_summon = class({
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
        return 
        {
            MODIFIER_EVENT_ON_DEATH
        }
    end,
    GetEffectName = function()
        return "particles/econ/items/warlock/warlock_ti10_head/warlock_ti_10_fatal_bonds_icon.vpcf"
    end,
    GetEffectAttachType = function()
        return PATTACH_OVERHEAD_FOLLOW
    end
})

function modifier_item_demon_seal_summon:OnCreated()
    if(not IsServer()) then
        return
    end
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self.caster = self.ability:GetCaster()
    self.tickInterval = self.ability:GetSpecialValueFor("tick_interval_absorption")
    self.currentMaxHpPctCost = (self.ability:GetSpecialValueFor("base_hp_absorption_per_sec") / 100) * self.tickInterval
    self.bonusMaxHpPctCostPerTick = (self.ability:GetSpecialValueFor("increase_hp_absorption_per_sec") / 100) * self.tickInterval
    self.damageTable = {
        victim = self.caster,
        attacker = self.caster,
        ability = self.ability,
        damage = 0,
        damage_type = self.ability:GetAbilityDamageType(),
        damage_flags = DOTA_DAMAGE_FLAG_IGNORES_MAGIC_ARMOR + DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR 
        + DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_DAMAGE_FLAG_BYPASSES_BLOCK 
        + DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
    }
    local particle = ParticleManager:CreateParticle(
        self:GetEffectName(), 
        PATTACH_OVERHEAD_FOLLOW, 
        self.caster
    )
    self:AddParticle(particle, false, false, 1, false, true)
    local particle1 = ParticleManager:CreateParticle(
        "particles/econ/items/warlock/warlock_hellsworn_construct/golem_hellsworn_ambient.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW, 
        self.parent
    )
    ParticleManager:SetParticleControlEnt(particle1, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_mane1", self.parent:GetOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle1, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_mane2", self.parent:GetOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle1, 2, self.parent, PATTACH_POINT_FOLLOW, "attach_mane3", self.parent:GetOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle1, 3, self.parent, PATTACH_POINT_FOLLOW, "attach_mane4", self.parent:GetOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle1, 4, self.parent, PATTACH_POINT_FOLLOW, "attach_mane5", self.parent:GetOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle1, 5, self.parent, PATTACH_POINT_FOLLOW, "attach_mane6", self.parent:GetOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle1, 6, self.parent, PATTACH_POINT_FOLLOW, "attach_mane7", self.parent:GetOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle1, 7, self.parent, PATTACH_POINT_FOLLOW, "attach_mane8", self.parent:GetOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle1, 10, self.parent, PATTACH_POINT_FOLLOW, "attach_hand_r", self.parent:GetOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle1, 11, self.parent, PATTACH_POINT_FOLLOW, "attach_hand_l", self.parent:GetOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle1, 12, self.parent, PATTACH_POINT_FOLLOW, "attach_mouthFire", self.parent:GetOrigin(), true)
    self:AddParticle(particle1, false, false, 1, false, false)
    local particle2 = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW, 
        self.parent
    )
    self:AddParticle(particle2, false, false, 1, false, false)
    self:StartIntervalThink(self.tickInterval)
end

function modifier_item_demon_seal_summon:OnIntervalThink()
    if(self.caster:IsNull() == true or self.caster:IsAlive() == false) then
        self:Destroy()
        return
    end
    self.damageTable.damage = self.caster:GetMaxHealth() * self.currentMaxHpPctCost
    ApplyDamage(self.damageTable)
    self.currentMaxHpPctCost = self.currentMaxHpPctCost + self.bonusMaxHpPctCostPerTick
    local particle = ParticleManager:CreateParticle(
        "particles/econ/items/warlock/warlock_ti10_head/warlock_ti_10_fatal_bonds_cast.vpcf", 
        PATTACH_CUSTOMORIGIN, 
        nil
    )
    ParticleManager:SetParticleControlEnt(particle, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, self.caster, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle, 2)
end

function modifier_item_demon_seal_summon:OnDeath(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    self.ability:ToggleOff()
end

function modifier_item_demon_seal_summon:OnDestroy()
    if(not IsServer()) then
        return
    end
    self.parent:Kill(nil,nil)
end

LinkLuaModifier("modifier_item_demon_seal_summon", "items/neutral_items/demon_seal", LUA_MODIFIER_MOTION_NONE, modifier_item_demon_seal_summon)
LinkLuaModifier("modifier_item_demon_seal", "items/neutral_items/demon_seal", LUA_MODIFIER_MOTION_NONE, modifier_item_demon_seal)