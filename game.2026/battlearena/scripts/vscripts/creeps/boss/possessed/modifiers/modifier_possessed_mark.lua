modifier_possessed_mark = modifier_possessed_mark or class({})
local mod = modifier_possessed_mark

require('creeps/boss/possessed/possessed_helpers')


function mod:IsHidden() return false end
function mod:IsPurgable() return false end
function mod:IsDebuff() return true end
function mod:DestroyOnExpire() return true end
function mod:RemoveOnDeath() return true end


function mod:GetEffectName()
	return "particles/econ/items/ogre_magi/ogre_magi_arcana/ogre_magi_arcana_stunned_orbit.vpcf"
end


function mod:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end


function mod:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.position = self:GetParent():GetAbsOrigin()
end


function mod:OnDestroy()
	if not IsServer() then return end

	local caster = self.caster
	local ability = self.ability

	if not IsValidEntity(caster) or not IsValidEntity(ability) then return end

	local position = self.position
	local splash_radius = AbilityKV:Get(ability, "splash_radius")
	local splash_pct = AbilityKV:Get(ability, "splash_pct") / 100
	local victim = self:GetParent()

	if IsValidEntity(victim) and victim:IsAlive() then
		PossessedHelpers:DealDamage(ability, caster, victim)
	end

	local enemies = PossessedHelpers:FindEnemies(caster:GetTeamNumber(), position, splash_radius)

	for _, enemy in pairs(enemies) do
		if IsValidEntity(enemy) and enemy ~= victim then
			local flat = AbilityKV:Get(ability, "damage_flat")
			local pct = AbilityKV:Get(ability, "damage_pct") / 100
			local damage = (flat + enemy:GetMaxHealth() * pct) * splash_pct

			ApplyDamage({
				victim = enemy,
				attacker = caster,
				damage = damage,
				damage_type = DAMAGE_TYPE_PURE,
				damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
				ability = ability,
			})
		end
	end

	local p = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(p, 0, position)
	ParticleManager:SetParticleControl(p, 1, Vector(splash_radius, 1, 1))
	ParticleManager:ReleaseParticleIndex(p)

	EmitSoundOnLocationWithCaster(position, "Boss_Possessed.MagmaTrails.Trail", caster)
end
