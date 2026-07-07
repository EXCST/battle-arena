
item_spider_cocoon = class({})

function item_spider_cocoon:Precache(context)
    PrecacheResource("particle", "particles/custom/items/spider_cocoon/spider_spawn.vpcf", context)
end

function item_spider_cocoon:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local hatchDuration = self:GetSpecialValueFor("spawn_duration")
    local cocoon = CreateSummon(
        caster, 
        "npc_dota_big_spider_cocoon", 
        self:GetCursorPosition(), 
        hatchDuration, 
        nil, 
        nil, 
        nil, 
        nil
    )
    cocoon:AddNewModifier(caster, self, "modifier_item_spider_cocoon_egg", {duration = -1})
    self:SpendCharge()
end

modifier_item_spider_cocoon_egg = class({
    IsHidden = function(self)
        return false
    end,
    IsPurgable = function()
        return false
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_EVENT_ON_DEATH
        }
    end
})

function modifier_item_spider_cocoon_egg:OnCreated()
    self.parent = self:GetParent()
end

function modifier_item_spider_cocoon_egg:OnDeath(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    local caster = self:GetCaster()
    local spider = CreateSummon(
        caster, 
        "npc_dota_big_spider", 
        self.parent:GetAbsOrigin(), 
        -1, 
        nil, 
        nil, 
        nil, 
        nil
    )
    EmitSoundOn("EggSack.Burst", spider)
    local particle = ParticleManager:CreateParticle("particles/custom/items/spider_cocoon/spider_spawn.vpcf", PATTACH_ABSORIGIN, spider)
    ParticleManager:ReleaseParticleIndex(particle)
    UTIL_Remove(self.parent)
end

LinkLuaModifier("modifier_item_spider_cocoon_egg", "items/custom/item_spider_cocoon", LUA_MODIFIER_MOTION_NONE, modifier_item_spider_cocoon_egg)