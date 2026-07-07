forgotten_hero_breach = forgotten_hero_breach or class({})

local ability = forgotten_hero_breach

LinkLuaModifier( "modifier_forgotten_hero_breach", "heroes/forgotten_hero/modifiers/modifier_forgotten_hero_breach", LUA_MODIFIER_MOTION_NONE )

function ability:OnSpellStart( kv )
	if not IsServer() then return end

	local caster = self:GetCaster()
	if not caster or caster:IsNull() then return end

	local duration = self:GetSpecialValueFor("duration") + (caster:GetTalentSpecialValueFor("forgotten_hero_talent_breach_duration") or 0)
	local fadeTime = self:GetSpecialValueFor("fade_time")

	local particle = ParticleManager:CreateParticle("particles/heroes/forgotten_hero/breach/breach_start.vpcf", PATTACH_ABSORIGIN, caster)

	caster:EmitSound("Hero_ForgottenHero.Breach.Cast")

	GameRules:GetGameModeEntity():SetThink(function()
		if not caster or caster:IsNull() or not caster:IsAlive() then
			ParticleManager:DestroyParticle(particle, true)
			return nil
		end

		caster:RemoveModifierByName("modifier_forgotten_hero_breach")
		caster:AddNewModifier(caster, self, "modifier_forgotten_hero_breach", { duration = duration })
		return nil
	end, "breach_fade", fadeTime)
end
