-- lib/duel_bosses/modifiers/modifier_duel_boss_smoke.lua
-- «Контужение» — дебафф промахов (v3: зона-дым из kit v2 убрана, дек переиспользуется
-- гранатой Deadeye). MODIFIER_PROPERTY_MISS_PERCENTAGE (геттер GetModifierMiss_Percentage,
-- доки Valve: "Increased chance to miss") = носитель промахивается базовыми атаками (45%).
-- ⚠️ БЕЗ require('lib/timers').

LinkLuaModifier("modifier_duel_boss_smoke", "lib/duel_bosses/modifiers/modifier_duel_boss_smoke", LUA_MODIFIER_MOTION_NONE)

local MISS_PERCENT = 45

modifier_duel_boss_smoke = modifier_duel_boss_smoke or class({})

function modifier_duel_boss_smoke:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MISS_PERCENTAGE,
	}
end

function modifier_duel_boss_smoke:GetModifierMiss_Percentage()
	return MISS_PERCENT
end

function modifier_duel_boss_smoke:OnCreated()
	if not IsServer() then return end
	-- «звёздочки» над головой — оглушённо-контуженный вид
	local p = ParticleManager:CreateParticle("particles/econ/items/ogre_magi/ogre_magi_arcana/ogre_magi_arcana_stunned_orbit.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
	ParticleManager:ReleaseParticleIndex(p)
end

function modifier_duel_boss_smoke:IsDebuff() return true end
function modifier_duel_boss_smoke:IsHidden() return false end
function modifier_duel_boss_smoke:IsPurgable() return true end
function modifier_duel_boss_smoke:RemoveOnDeath() return true end

function modifier_duel_boss_smoke:GetTexture()
	return "sniper_concussive_grenade"
end
