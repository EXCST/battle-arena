item_safe_lottery_coin = class({})

function item_safe_lottery_coin:OnSpellStart()
    if (not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    if (caster:IsRealHero() == false) then
        return
    end
    local goldOnEquip = self:GetSpecialValueFor("gold")
    caster:ModifyGoldFiltered(goldOnEquip, true, DOTA_ModifyGold_AbilityGold)
    local player = PlayerResource:GetPlayer(caster:GetPlayerOwnerID())
    SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, caster, goldOnEquip, nil)
    self:Destroy()
end
