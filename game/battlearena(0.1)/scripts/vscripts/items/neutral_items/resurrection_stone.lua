item_resurrection_stone = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_resurrection_stone"
    end
})

function item_resurrection_stone:Precache(context)
    PrecacheResource("particle", "particles/custom/items/resurrection_stone/effect.vpcf", context)
end

function item_resurrection_stone:GetCooldown(iLevel)
    local caster = self:GetCaster()
    local baseCooldown = self.BaseClass.GetCooldown(self, iLevel)
    return baseCooldown / caster:GetCooldownReduction()
end

function item_resurrection_stone:IsRefreshable()
    return false
end

function item_resurrection_stone:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local healingHpPct = self:GetSpecialValueFor("alived_ally_hp_heal_pct") / 100
    local healingMpPct = self:GetSpecialValueFor("alived_ally_mp_recover_pct") / 100
    local playerHero = PlayerResource:GetSelectedHeroEntity(caster:GetPlayerOwnerID())
    for i=1, PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, i)
		if(playerID > -1) then
            local playerHero = PlayerResource:GetSelectedHeroEntity(playerID)
            if(playerHero) then
                if(playerHero:IsAlive() == false) then
                    playerHero:RespawnHero(false, false)
                else
                    local healingDone = playerHero:Heal(healingHpPct * playerHero:GetMaxHealth(), self, DOTA_HEAL_TYPE_HEALING)
                    local healingMpDone = healingMpPct * playerHero:GetMaxMana()
                    playerHero:GiveMana(healingMpDone)
                    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, playerHero, healingDone, nil)
                    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, playerHero, healingMpDone, nil)
                end
                local particle = ParticleManager:CreateParticle(
                    "particles/custom/items/resurrection_stone/effect.vpcf",
                    PATTACH_ABSORIGIN,
                    playerHero
                )
                ParticleManager:SetParticleControl(particle, 1, Vector(100, 100, 100))
                ParticleManager:ReleaseParticleIndex(particle, 2)
                EmitSoundOn("Item.RessurectionStone.Cast", playerHero)
            end
		end
	end
end

modifier_item_resurrection_stone = class({
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
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH_PERCENTAGE,
            MODIFIER_PROPERTY_EXTRA_MANA_PERCENTAGE
        }
    end,
    GetModifierBonusHealthPercentage = function(self)
        return self.bonusHealthPct
    end,
    GetModifierExtraManaPercentage = function(self)
        return self.bonusManaPct
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_resurrection_stone:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self:StartIntervalThink(1)
end

function modifier_item_resurrection_stone:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealthPct = self.ability:GetSpecialValueFor("bonus_health_pct")
    self.bonusManaPct = self.ability:GetSpecialValueFor("bonus_mana_pct")
end

function modifier_item_resurrection_stone:OnIntervalThink()
    local currentHeroesDead = 0
    local currentHeroesCount = 0
    for i=1, PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, i)
		if(playerID > -1) then
            local playerHero = PlayerResource:GetSelectedHeroEntity(playerID)
            if(playerHero and playerHero:IsAlive() == false) then
                currentHeroesDead = currentHeroesDead + 1
            end
            currentHeroesCount = currentHeroesCount + 1
		end
	end
    if(currentHeroesDead >= currentHeroesCount and currentHeroesCount > 0 and self.ability:IsCooldownReady() == true) then
        self.ability:UseResources(true, false, true, true)
        self.ability:OnSpellStart()
    end
end

LinkLuaModifier("modifier_item_resurrection_stone", "items/neutral_items/resurrection_stone", LUA_MODIFIER_MOTION_NONE, modifier_item_resurrection_stone)