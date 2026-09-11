modifier_scaling_camp_boss = class({})
local mod = modifier_scaling_camp_boss

function mod:IsHidden() return false end
function mod:IsPurgable() return false end
function mod:DestroyOnExpire() return true end
function mod:IsPurgeException() return false end
function mod:GetTexture() return "elder_titan_natural_order" end

function mod:OnTooltip()
    return "BOSS: 50% Pure bonus | Attack speed scaling"
end

function mod:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_BASEDATTACKTIME,
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function mod:GetModifierAttackSpeedBonus_Constant()
    if not IsServer() then return 0 end
    local p = self:GetParent()
    return (p and p.bear_aspeed_bonus) or 0
end

function mod:GetModifierBaseAttackTime()
    if not IsServer() then return end
    local p = self:GetParent()
    return (p and p.bear_bat)
end

function mod:OnCreated(kv)
    if not IsServer() then return end
    local p = self:GetParent()
    if not p then return end
    local ok, err = pcall(function()
        self:SetStackCount(p.bear_spawn_cycle or 0)
        p:SetRenderColor(255, 50, 50)
        self:StartIntervalThink(0.5)
    end)
    if not ok then
        print("[SCALING-BOSS] OnCreated ERR: " .. tostring(err))
    end
end

function mod:OnIntervalThink()
    local p = self:GetParent()
    if not p or p:IsNull() then return end
    self:SetStackCount(p.bear_spawn_cycle or 0)
    if p:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
        p:SetTeam(DOTA_TEAM_NEUTRALS)
    end
end

function mod:OnDestroy()
    if not IsServer() then return end
    local p = self:GetParent()
    if p and not p:IsNull() then p:SetRenderColor(255, 255, 255) end
end

function mod:OnDeath(kv)
    if not IsServer() then return end
    if kv.unit ~= self:GetParent() then return end
    if ScalingCamp then ScalingCamp:OnBearDeath(self:GetParent()) end
end

function mod:OnAttackLanded(kv)
    if not IsServer() then return end
    if kv.attacker ~= self:GetParent() then return end
    if not kv.target or kv.target:IsNull() or not kv.target:IsAlive() then return end
    if kv.damage <= 0 then return end

    -- Pure bonus (эффекты крита/баша/вампиризма/сплита/эвейжна/MR — в способностях scaling_boss_*)
    local pureDmg = kv.damage * 0.5
    ApplyDamage({victim=kv.target, attacker=self:GetParent(), damage=pureDmg, damage_type=DAMAGE_TYPE_PURE, damage_flags=DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, kv.target, pureDmg, nil)
end
