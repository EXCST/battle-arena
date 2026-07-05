modifier_item_abyssal_blade_2_bash = class({})

function modifier_item_abyssal_blade_2_bash:IsHidden() return true end
function modifier_item_abyssal_blade_2_bash:IsPurgable() return false end
function modifier_item_abyssal_blade_2_bash:DestroyOnExpire() return false end
function modifier_item_abyssal_blade_2_bash:RemoveOnDeath() return false end

function modifier_item_abyssal_blade_2_bash:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function modifier_item_abyssal_blade_2_bash:OnAttackLanded(params)
    if not IsServer() then return end
    if params.attacker ~= self:GetParent() then return end
    if params.attacker:IsRanged() then return end
    if params.target:IsMagicImmune() then return end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end

    local bash_chance = ability:GetSpecialValueFor("bash_chance_melee")
    local bash_duration = ability:GetSpecialValueFor("bash_duration")
    local bonus_damage = ability:GetSpecialValueFor("bonus_chance_damage")

    if RollPercentage(bash_chance or 25) then
        params.target:AddNewModifier(params.attacker, ability, "modifier_stunned", { duration = bash_duration })

        local damageTable = {
            victim = params.target,
            attacker = params.attacker,
            damage = bonus_damage,
            damage_type = DAMAGE_TYPE_PHYSICAL,
            damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
            ability = ability,
        }
        ApplyDamage(damageTable)

        local pidx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_bashed.vpcf", PATTACH_OVERHEAD_FOLLOW, params.target)
        ParticleManager:SetParticleControl(pidx, 0, params.target:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(pidx)
    end
end
