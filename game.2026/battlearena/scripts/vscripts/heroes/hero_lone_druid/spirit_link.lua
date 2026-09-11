lone_druid_spirit_link_custom = class({})

function lone_druid_spirit_link_custom:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_lone_druid/lone_druid_spiritlink_cast.vpcf", context)
end

function lone_druid_spirit_link_custom:OnSpellStart()
	if(not IsServer()) then
		return
	end
	local caster = self:GetCaster()
    local buffDuration = self:GetSpecialValueFor("buff_duration")
    caster:AddNewModifier(caster, self, "modifier_lone_druid_spirit_link_custom_buff", {duration = buffDuration})
    EmitSoundOn("Hero_LoneDruid.SpiritLink.Cast", caster)
	if (caster.bear and caster.bear:IsAlive()) then
        caster.bear:AddNewModifier(caster, self, "modifier_lone_druid_spirit_link_custom_buff", {duration = buffDuration})
        EmitSoundOn("Hero_LoneDruid.SpiritLink.Bear", caster.bear)
        local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_spiritlink_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControlEnt(pfx, 1, caster.bear, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
        ParticleManager:ReleaseParticleIndex(pfx)
    else
        local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_spiritlink_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControlEnt(pfx, 1, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
        ParticleManager:ReleaseParticleIndex(pfx)
    end
end

modifier_lone_druid_spirit_link_custom_buff = class({
    IsHidden = function(self)
        return false
    end,
    IsPurgable = function()
        return true
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_TOOLTIP
        
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_PERCENTAGE,
        }
    end,
    GetModifierMoveSpeedBonus_Percentage = function(self)
        return self.bonusMoveSpeedPct
    end,
    GetModifierAttackSpeed_Percentage = function(self)
        return self.bonusAttackSpeedPct
    end
})

function modifier_lone_druid_spirit_link_custom_buff:OnCreated()
    if (not IsServer()) then
        return
    end
    self.ability = self:GetAbility()
    self:OnRefresh()
    self:SetHasCustomTransmitterData(true)
	self:SendBuffRefreshToClients()
end

function modifier_lone_druid_spirit_link_custom_buff:OnRefresh()
    if (not IsServer()) then
        return
    end
	if(not self.ability) then
		return
	end
    self.bonusAttackSpeedPct = self.ability:GetSpecialValueFor("bonus_as")
    self.bonusMoveSpeedPct = self.ability:GetSpecialValueFor("bonus_ms")
end

function modifier_lone_druid_spirit_link_custom_buff:OnTooltip()
    return self:GetModifierAttackSpeed_Percentage()
end

function modifier_lone_druid_spirit_link_custom_buff:AddCustomTransmitterData()
    return
    {
        bonusAttackSpeedPct = self.bonusAttackSpeedPct,
        bonusMoveSpeedPct = self.bonusMoveSpeedPct
    }
end

function modifier_lone_druid_spirit_link_custom_buff:HandleCustomTransmitterData(data)
    self.bonusAttackSpeedPct = data.bonusAttackSpeedPct
    self.bonusMoveSpeedPct = data.bonusMoveSpeedPct
end



LinkLuaModifier("modifier_lone_druid_spirit_link_custom_buff", "abilities/heroes/hero_lone_druid/spirit_link", LUA_MODIFIER_MOTION_NONE, modifier_lone_druid_spirit_link_custom_buff)
