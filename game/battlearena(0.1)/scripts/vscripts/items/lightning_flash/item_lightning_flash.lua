item_lightning_flash = item_lightning_flash or class({})
LinkLuaModifier("modifier_item_lightning_flash", "items/lightning_flash/modifier_item_lightning_flash", LUA_MODIFIER_MOTION_NONE)

function item_lightning_flash:GetIntrinsicModifierName()
    return "modifier_item_lightning_flash"
end

function item_lightning_flash:CastFilterResultLocation(vLocation)
    return UF_SUCCESS
end

function item_lightning_flash:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local targetPoint = self:GetCursorPosition()
    local blinkRange = self:GetSpecialValueFor("blink_range")
    local damageRange = self:GetSpecialValueFor("damage_range")
    local damagePct = self:GetSpecialValueFor("damage_pct")

    local origin = caster:GetAbsOrigin()
    local direction = (targetPoint - origin):Normalized()
    local distance = (targetPoint - origin):Length2D()

    if distance > blinkRange then
        targetPoint = origin + direction * blinkRange
    end

    FindClearSpaceForUnit(caster, targetPoint, true)

    EmitSoundOn("Hero_Leshrac.Lightning_Storm", caster)

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        damageRange,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    local damage = caster:GetPrimaryStatValue() * (damagePct / 100)
    for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and enemy:IsAlive() then
            ApplyDamage({
                victim = enemy,
                attacker = caster,
                damage = damage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self
            })
        end
    end
end
