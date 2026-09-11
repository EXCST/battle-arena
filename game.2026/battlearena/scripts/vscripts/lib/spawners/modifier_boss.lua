modifier_boss = modifier_boss or class({})
local mod = modifier_boss

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