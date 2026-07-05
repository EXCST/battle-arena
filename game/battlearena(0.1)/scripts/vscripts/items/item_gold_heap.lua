item_gold_heap = {}

function item_gold_heap:OnSpellStart()
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
    self:SpendCharge()
    if (self:GetCurrentCharges() < 1) then
        self:Destroy()
    end
end
