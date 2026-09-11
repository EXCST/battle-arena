angel_arena_hola_heal = class({})

function angel_arena_hola_heal:OnSpellStart()
    local caster = self:GetCaster()
    local heal = self:GetSpecialValueFor("heal")
    if caster and caster:IsAlive() then
        caster:Heal(heal, self)
    end
end
