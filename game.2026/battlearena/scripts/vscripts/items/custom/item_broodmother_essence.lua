item_broodmother_essence = class({})

function item_broodmother_essence:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local playerID = self:GetCaster():GetPlayerOwnerID()
    self:SpendCharge()
	PlayerResource:ReplacePlayerHero(playerID, "npc_dota_hero_broodmother")
end