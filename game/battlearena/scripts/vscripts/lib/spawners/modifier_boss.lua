BossModifier = BossModifier or class({})
local mod = BossModifier

function mod:IsHidden()         return true  end
function mod:IsPurgable()       return false end
function mod:DestroyOnExpire()  return true end
function mod:IsPurgable()       return false end
function mod:IsPurgeException() return false end

function mod:DeclareFunctions() return 
{
	MODIFIER_EVENT_ON_DEATH,
}
end

function mod:OnDeath(kv)
	if not IsServer() then return end

	local parent = self:GetParent()

	local unit = kv.unit

	if unit ~= parent then return end

	BossSpawner:_OnDeath( unit )
end