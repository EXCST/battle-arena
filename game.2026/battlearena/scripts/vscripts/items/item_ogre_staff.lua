require('items/generic_datadriven_item')

item_ogre_staff = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_ogre_staff"
    end
})

function item_ogre_staff:PrecacheResource(context)
    PrecacheResource("particle", "particles/items_fx/necronomicon_spawn_warrior.vpcf", context)
end

function item_ogre_staff:OnSpellStart()
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
    local playerID = caster:GetPlayerID()
    local casterTeam = caster:GetTeamNumber()

    for i = 1, count do
        local position = point + caster_fw*100 + RandomVector(RandomInt(-50, 50))
        local unit = CreateSummon(
            caster,
            "npc_ogre_staff_summon",
            position,
            duration,
            damage,
            armor,
            hp,
            BAT
        )
        unit:FindAbilityByName("ogre_staff_smash"):SetLevel(self:GetLevel())

        local pfx = ParticleManager:CreateParticle("particles/items_fx/necronomicon_spawn_warrior.vpcf", PATTACH_ABSORIGIN, unit)
        ParticleManager:ReleaseParticleIndex(pfx)
    end
    EmitSoundOn("OgreStaff.Cast", caster)
end

item_ogrelord_staff = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_ogre_staff"
    end
})

function item_ogrelord_staff:PrecacheResource(context)
    PrecacheResource("particle", "particles/items_fx/necronomicon_spawn_warrior.vpcf", context)
end

function item_ogrelord_staff:OnSpellStart()
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
    local playerID = caster:GetPlayerID()
    local casterTeam = caster:GetTeamNumber()

    for i = 1, count do
        local position = point + caster_fw*100 + RandomVector(RandomInt(-50, 50))
        local unit = CreateSummon(
            caster,
            "npc_ogrelord_staff_summon",
            position,
            duration,
            damage,
            armor,
            hp,
            BAT
        )
        unit:FindAbilityByName("ogrelord_staff_smash"):SetLevel(self:GetLevel())
        unit:FindAbilityByName("ogrelord_staff_clap"):SetLevel(self:GetLevel())

        local pfx = ParticleManager:CreateParticle("particles/items_fx/necronomicon_spawn_warrior.vpcf", PATTACH_ABSORIGIN, unit)
        ParticleManager:ReleaseParticleIndex(pfx)
    end
    EmitSoundOn("OgreStaff.Cast", caster)
end

item_ogre_staff_1 = class(item_ogre_staff)
item_ogre_staff_2 = class(item_ogre_staff)
item_ogre_staff_3 = class(item_ogre_staff)

item_ogre_staff_4 = class(item_ogrelord_staff)
item_ogre_staff_5 = class(item_ogrelord_staff)
item_ogre_staff_6 = class(item_ogrelord_staff)

modifier_item_ogre_staff = class({
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
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH
	    
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_ogre_staff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_ogre_staff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
    self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
end

function modifier_item_ogre_staff:GetModifierConstantManaRegen()
    return self.bonus_mp_regen
end

function modifier_item_ogre_staff:GetModifierBonusStats_Strength()
    return self.bonus_str
end

function modifier_item_ogre_staff:GetModifierBonusHealth()
	return self.bonus_health
end

LinkLuaModifier("modifier_item_ogre_staff", "items/item_ogre_staff", LUA_MODIFIER_MOTION_NONE, modifier_item_ogre_staff)



ogre_staff_smash = class({
    GetAOERadius = function(self) return self:GetSpecialValueFor("radius") end
})

function ogre_staff_smash:GetCastAnimation()
    if self:GetCaster():GetModelName() == "models/creeps/ogre_1/boss_ogre.vmdl" then
        return ACT_DOTA_CAST_ABILITY_1
    end
    return ACT_DOTA_CAST_ABILITY_2
end

function ogre_staff_smash:OnSpellStart()
    if not IsServer() then return end
    local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCursorPosition(), nil, self:GetSpecialValueFor("radius"), self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), 0, false)
    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = self:GetSpecialValueFor("duration")})
        ApplyDamage({
            victim = enemy,
            attacker = self:GetCaster(),
            ability = self,
            damage = self:GetSpecialValueFor("damage"),
            damage_type = self:GetAbilityDamageType()
        })
    end
    local pfx = ParticleManager:CreateParticle("particles/neutral_fx/ogre_bruiser_smash.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
    ParticleManager:SetParticleControl(pfx, 0, self:GetCursorPosition())
    ParticleManager:SetParticleControl(pfx, 1, Vector(self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("radius"), 0))
    ParticleManager:ReleaseParticleIndex(pfx)
    ParticleManager:DestroyParticle(pfx, false)
end

ogrelord_staff_smash = class({
    GetAOERadius = function(self) return self:GetSpecialValueFor("radius") end
})

function ogrelord_staff_smash:GetCastAnimation()
    if self:GetCaster():GetModelName() == "models/creeps/ogre_1/boss_ogre.vmdl" then
        return ACT_DOTA_CAST_ABILITY_1
    end
    return ACT_DOTA_CAST_ABILITY_2
end

function ogrelord_staff_smash:OnSpellStart()
    if not IsServer() then return end
    local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCursorPosition(), nil, self:GetSpecialValueFor("radius"), self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), 0, false)
    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = self:GetSpecialValueFor("duration")})
        ApplyDamage({
            victim = enemy,
            attacker = self:GetCaster(),
            ability = self,
            damage = self:GetSpecialValueFor("damage"),
            damage_type = self:GetAbilityDamageType()
        })
    end
    local pfx = ParticleManager:CreateParticle("particles/neutral_fx/ogre_bruiser_smash.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
    ParticleManager:SetParticleControl(pfx, 0, self:GetCursorPosition())
    ParticleManager:SetParticleControl(pfx, 1, Vector(self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("radius"), 0))
    ParticleManager:ReleaseParticleIndex(pfx)
    ParticleManager:DestroyParticle(pfx, false)
end

ogrelord_staff_clap = class({
	GetCastRange = function(self)
		return self:GetSpecialValueFor("radius")
	end
})

function ogrelord_staff_clap:Precache(context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_brewmaster.vsndevts", context)
end

function ogrelord_staff_clap:OnSpellStart()
    if not IsServer() then return end
	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControl(pfx, 0, self:GetCaster():GetAbsOrigin())
	ParticleManager:SetParticleControl(pfx, 1, Vector(self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("radius")))
    ParticleManager:ReleaseParticleIndex(pfx)
	local nearby_units = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), 0, false)
    for _, enemy in pairs(nearby_units) do
		enemy:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})
		ApplyDamage({
			victim = enemy,
			attacker = self:GetCaster(),
			ability = self,
			damage = self:GetSpecialValueFor("damage"),
			damage_type = self:GetAbilityDamageType(),
		})
	end
	EmitSoundOn("Hero_Brewmaster.ThunderClap", self:GetCaster())
end