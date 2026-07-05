require('items/generic_datadriven_item')

item_troll_staff = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_troll_staff"
    end
})

function item_troll_staff:Precache(context)
    PrecacheResource("particle", "particles/items_fx/necronomicon_spawn_warrior.vpcf", context)
end

function item_troll_staff:OnSpellStart()
    if not IsServer() then return end
    local count = self:GetSpecialValueFor("summon_count")
    local duration = self:GetSpecialValueFor("summon_duration")
    local hp = self:GetSpecialValueFor("summon_hp")
    local damage = self:GetSpecialValueFor("summon_damage")
    local armor = self:GetSpecialValueFor("summon_armor")
    local BAT = self:GetSpecialValueFor("summon_BAT")

    local caster = self:GetCaster()
    local caster_fw = caster:GetForwardVector()
    local point = caster:GetAbsOrigin()
    local parentTeam = caster:GetTeamNumber()
    local playerID = caster:GetPlayerID()
    for i = 1, count do
        local position = point + caster_fw*100 + RandomVector(RandomInt(-50, 50))
        local unit = CreateSummon(
			caster,
			"npc_troll_staff_summon",
			position,
			duration,
			damage,
			armor,
			hp,
			BAT
		)
        unit:FindAbilityByName("troll_staff_fervor"):SetLevel(self:GetLevel())

        local pfx = ParticleManager:CreateParticle("particles/items_fx/necronomicon_spawn_warrior.vpcf", PATTACH_ABSORIGIN, unit)
        ParticleManager:ReleaseParticleIndex(pfx)
    end
    EmitSoundOn("TrollStaff.Cast", caster)
end

item_troll_berserk_staff = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_troll_staff"
    end
})

function item_troll_berserk_staff:Precache(context)
    PrecacheResource("particle", "particles/items_fx/necronomicon_spawn_warrior.vpcf", context)
end

function item_troll_berserk_staff:OnSpellStart()
    if not IsServer() then return end
    local count = self:GetSpecialValueFor("summon_count")
    local duration = self:GetSpecialValueFor("summon_duration")
    local hp = self:GetSpecialValueFor("summon_hp")
    local damage = self:GetSpecialValueFor("summon_damage")
    local armor = self:GetSpecialValueFor("summon_armor")
    local BAT = self:GetSpecialValueFor("summon_BAT")

    local caster = self:GetCaster()
    local caster_fw = caster:GetForwardVector()
    local point = caster:GetAbsOrigin()
    local parentTeam = caster:GetTeamNumber()
    local playerID = caster:GetPlayerID()
    for i = 1, count do
        local position = point + caster_fw*100 + RandomVector(RandomInt(-50, 50))
        local unit = CreateSummon(
            caster,
            "npc_troll_berserk_staff_summon",
            position,
            duration,
            damage,
            armor,
            hp,
            BAT
        )
        unit:FindAbilityByName("troll_staff_fervor"):SetLevel(self:GetLevel())
        unit:FindAbilityByName("troll_staff_buff"):SetLevel(self:GetLevel())

        local pfx = ParticleManager:CreateParticle("particles/items_fx/necronomicon_spawn_warrior.vpcf", PATTACH_ABSORIGIN, unit)
        ParticleManager:ReleaseParticleIndex(pfx)
    end
    EmitSoundOn("TrollStaff.Cast", caster)
end

item_troll_staff_1 = class(item_troll_staff)
item_troll_staff_2 = class(item_troll_staff)
item_troll_staff_3 = class(item_troll_staff)

item_troll_staff_4 = class(item_troll_berserk_staff)
item_troll_staff_5 = class(item_troll_berserk_staff)
item_troll_staff_6 = class(item_troll_berserk_staff)

modifier_item_troll_staff = class({
	IsHidden  = function()
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
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
	    }
    end
})

function modifier_item_troll_staff:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_troll_staff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonusMpRegen = self.ability:GetSpecialValueFor("bonus_mp_regen")
    self.bonusStr = self.ability:GetSpecialValueFor("bonus_str")
    self.bonusDamage = self.ability:GetSpecialValueFor("bonus_damage")
end

function modifier_item_troll_staff:GetModifierConstantManaRegen()
    return self.bonusMpRegen
end

function modifier_item_troll_staff:GetModifierBonusStats_Strength()
    return self.bonusStr
end

function modifier_item_troll_staff:GetModifierPreAttack_BonusDamage()
    return self.bonusDamage
end


troll_staff_fervor = class({
    GetIntrinsicModifierName = function() return "modifier_troll_staff_fervor" end
})

modifier_troll_staff_fervor = class({
    IsHidden = function(self) return self:GetStackCount() == 0 end,
    IsPurgable = function() return false end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    } end
})

function modifier_troll_staff_fervor:OnCreated()
    self.ability = self:GetAbility()
    self.target = {}
    self.first_proc = false
    self:OnRefresh()
end

function modifier_troll_staff_fervor:OnRefresh()
    if not self.ability then return end
    self.as_per_stack = self.ability:GetSpecialValueFor("as_per_stack")
    self.max_stacks = self.ability:GetSpecialValueFor("max_stacks")
end

function modifier_troll_staff_fervor:GetModifierAttackSpeedBonus_Constant(keys)
    return self:GetStackCount() * self.as_per_stack
end

function modifier_troll_staff_fervor:OnAttackLanded(keys)
    if not IsServer() then return end
    if keys.attacker == self:GetParent() then
        if self.target[1] == nil and self.first_proc == false then
            self.target = keys.target
            self.first_proc = true
        end
        if keys.target ~= self.target then
            self:SetStackCount(1)
            self.target = keys.target
        else
            if self:GetStackCount() < self.max_stacks then
                self:SetStackCount(self:GetStackCount() + 1)
            end
        end
    end
end



troll_staff_buff = class({})

function troll_staff_buff:OnSpellStart()
    local duration = self:GetSpecialValueFor("duration")
    local caster = self:GetCaster()
    
    caster:AddNewModifier(caster, self, "modifier_troll_staff_troll_buff", {duration = duration})
    caster:EmitSound("MaskOfMadness.Activate")
end

modifier_troll_staff_troll_buff = class({
    IsHidden = function() return false end,
    IsPurgable = function() return false end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    } end,
    GetEffectName = function()
        return "particles/items2_fx/mask_of_madness.vpcf"
    end,
    GetModifierAttackSpeedBonus_Constant = function(self) return self.as_bonus end,
    GetModifierDamageOutgoing_Percentage = function(self) return self.dmg_bonus_pct end,
})

function modifier_troll_staff_troll_buff:GetModifierIncomingDamage_Percentage()
    return self.incoming_damage_pct
end

function modifier_troll_staff_troll_buff:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_troll_staff_troll_buff:OnRefresh()
    if not self.ability then return end
    self.as_bonus = self.ability:GetSpecialValueFor("as_bonus")
    self.dmg_bonus_pct = self.ability:GetSpecialValueFor("dmg_bonus_pct")
    self.incoming_damage_pct = self.ability:GetSpecialValueFor("incoming_damage_pct")
end

LinkLuaModifier("modifier_item_troll_staff", "items/item_troll_staff", LUA_MODIFIER_MOTION_NONE, modifier_item_troll_staff)
LinkLuaModifier("modifier_troll_staff_fervor", "items/item_troll_staff", LUA_MODIFIER_MOTION_NONE, modifier_troll_staff_fervor)
LinkLuaModifier("modifier_troll_staff_troll_buff", "items/item_troll_staff", LUA_MODIFIER_MOTION_NONE, modifier_troll_staff_troll_buff)