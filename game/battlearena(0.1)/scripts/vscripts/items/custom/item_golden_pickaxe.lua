if not item_golden_pickaxe then
    item_golden_pickaxe = class({})
end

function item_golden_pickaxe:Precache(context)
    PrecacheResource( "particle", "particles/econ/events/ti9/shovel_dig.vpcf", context)
    PrecacheResource( "particle", "particles/econ/events/ti9/shovel_revealed_dancing_skeleton.vpcf", context)
    PrecacheResource( "particle", "particles/econ/events/ti9/shovel_revealed_frog.vpcf", context)
    PrecacheResource( "particle", "particles/econ/events/ti9/shovel_revealed_squirrel.vpcf", context)
    PrecacheResource( "particle", "particles/econ/events/ti9/shovel_revealed_spiders.vpcf", context)
    PrecacheResource( "particle", "particles/econ/events/ti9/shovel_revealed_skeleton.vpcf", context)
    PrecacheResource( "particle", "particles/econ/events/ti9/shovel_revealed_nothing.vpcf", context)
    PrecacheResource( "particle", "particles/econ/events/ti9/shovel_revealed_turtle.vpcf", context)
end

function item_golden_pickaxe:OnSpellStart()
    local caster = self:GetCaster()
    local pos = self:GetCursorPosition()
    self.fx = ParticleManager:CreateParticle("particles/econ/events/ti9/shovel_dig.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(self.fx, 0, pos)
    EmitSoundOn("SeasonalConsumable.TI9.Shovel.Dig", caster)
end

function item_golden_pickaxe:OnChannelFinish(bInterrupted)
    if self.fx then
        ParticleManager:DestroyParticle(self.fx, false)
        ParticleManager:ReleaseParticleIndex(self.fx)
        self.fx = nil
        StopSoundOn("SeasonalConsumable.TI9.Shovel.Dig", self:GetCaster())
    end

    if not bInterrupted then
        local pos = self:GetCursorPosition()
        local chancex1 = self:GetSpecialValueFor("trigger_chance_x1")
        local chancex2 = self:GetSpecialValueFor("trigger_chance_x2")
        local chancex3 = self:GetSpecialValueFor("trigger_chance_x3")
       
        if RollPercentage(chancex3) then
            self:SpawnRune(pos, 3)
        elseif RollPercentage(chancex2) then
            self:SpawnRune(pos, 2)
        elseif RollPercentage(chancex1) then
            self:SpawnRune(pos, 1)
        else
            self:SpawnEffects(pos)
        end
    end
end

function item_golden_pickaxe:SpawnRune(pos, x)
    local position = pos
    for i=1,x do
        EmitSoundOnLocationWithCaster(pos, "SeasonalConsumable.TI9.Shovel.RevealedTreasure", self:GetCaster())
        local item = CreateItem( "item_rune_bounty_custom", nil, nil )
        CreateItemOnPositionSync(position, item)
        position = position + RandomVector(RandomFloat(50,100))
    end
end

function item_golden_pickaxe:SpawnEffects(pos)
    local effects = {
        {
            fx = "particles/econ/events/ti9/shovel_revealed_dancing_skeleton.vpcf",
            sound = "SeasonalConsumable.TI9.Shovel.RevealedDancingSkeleton"
        },
        {
            fx = "particles/econ/events/ti9/shovel_revealed_frog.vpcf",
            sound = "SeasonalConsumable.TI9.Shovel.RevealedFrog"
        },
        {
            fx = "particles/econ/events/ti9/shovel_revealed_squirrel.vpcf",
            sound = "SeasonalConsumable.TI9.Shovel.RevealedSquirrel"
        },
        {
            fx = "particles/econ/events/ti9/shovel_revealed_spiders.vpcf",
            sound = "SeasonalConsumable.TI9.Shovel.RevealedSpiders"
        },
        {
            fx = "particles/econ/events/ti9/shovel_revealed_skeleton.vpcf",
            sound = "SeasonalConsumable.TI9.Shovel.RevealedSkeleton"
        },
        {
            fx = "particles/econ/events/ti9/shovel_revealed_nothing.vpcf",
            sound = ""
        },
        {
            fx = "particles/econ/events/ti9/shovel_revealed_turtle.vpcf",
            sound = "SeasonalConsumable.TI9.Shovel.RevealedTurtle"
        },
    }

    local effect = effects[RandomInt(1, #effects)]
    if effect then
        DeepPrintTable(effect)
        local part = ParticleManager:CreateParticle(effect.fx, PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(part, 0, pos)
        ParticleManager:SetParticleControl(part, 1, pos)
        ParticleManager:SetParticleControl(part, 32, pos)
        ParticleManager:ReleaseParticleIndex(part)
        if effect.sound ~= "" then
            EmitSoundOnLocationWithCaster(pos, effect.sound, self:GetCaster())
        end
    end
end