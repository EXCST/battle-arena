modifier_possessed_hell_aura = modifier_possessed_hell_aura or class({})
local mod = modifier_possessed_hell_aura

require('lib/ability_kv')
require('creeps/boss/possessed/possessed_helpers')


function mod:IsHidden() return true end
function mod:IsPurgable() return false end


function mod:OnCreated()
	if not IsServer() then return end

	self.current_radius = AbilityKV:Get(self:GetAbility(), "aura_radius")
	self.aura_particle = nil

	self:SpawnAuraParticle()
	self:StartIntervalThink(1.0)
end


--- Создаёт/пересоздаёт частицу ауры Doom с текущим радиусом (CP1 = Vector(radius x3)).
function mod:SpawnAuraParticle()
	local parent = self:GetParent()

	local radius = self.current_radius or AbilityKV:Get(self:GetAbility(), "aura_radius")

	self.aura_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_doom_aura.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(self.aura_particle, 0, parent:GetAbsOrigin())
	ParticleManager:SetParticleControl(self.aura_particle, 1, Vector(radius, radius, radius))
	self:AddParticle(self.aura_particle, false, false, -1, false, false)
end


function mod:OnIntervalThink()
	if not IsServer() then return end

	local parent = self:GetParent()

	if not IsValidEntity(parent) or not parent:IsAlive() then return end

	local ability = self:GetAbility()

	if not IsValidEntity(ability) then return end

	local base_radius 		= AbilityKV:Get(ability, "aura_radius")
	local base_flat 		= AbilityKV:Get(ability, "aura_flat")
	local base_pct 			= AbilityKV:Get(ability, "aura_pct")
	local radius_per_hero 	= AbilityKV:Get(ability, "aura_radius_per_hero")
	local flat_per_hero 	= AbilityKV:Get(ability, "aura_flat_per_hero")
	local pct_per_hero 		= AbilityKV:Get(ability, "aura_pct_per_hero")
	local detection_radius 	= AbilityKV:Get(ability, "aura_detection_radius")

	self.current_radius = self.current_radius or base_radius

	local parent_pos = parent:GetAbsOrigin()

	-- скан на максимум из радиусов: урон бьёт весь видимый круг ауры,
	-- а рост ауры считает героев только в detection_radius
	local scan_radius = math.max(self.current_radius, detection_radius)
	local enemies = PossessedHelpers:FindEnemies(parent:GetTeamNumber(), parent_pos, scan_radius)

	local hero_count = 0

	for _, enemy in pairs(enemies) do
		if IsValidEntity(enemy) and enemy.IsRealHero and enemy:IsRealHero() then
			if (enemy:GetAbsOrigin() - parent_pos):Length2D() <= detection_radius then
				hero_count = hero_count + 1
			end
		end
	end

	local bonus = math.max(0, hero_count - 1)

	local new_radius = base_radius + radius_per_hero * bonus

	-- радиус изменился — пересоздаём ауру с новым CP1 (кольца читают радиус при эмиссии)
	if new_radius ~= self.current_radius then
		self.current_radius = new_radius

		if self.aura_particle then
			ParticleManager:DestroyParticle(self.aura_particle, true)
			ParticleManager:ReleaseParticleIndex(self.aura_particle)
			self.aura_particle = nil
		end

		self:SpawnAuraParticle()
	end

	local flat = base_flat + flat_per_hero * bonus
	local pct = (base_pct + pct_per_hero * bonus) / 100

	for _, enemy in pairs(enemies) do
		if IsValidEntity(enemy) and enemy:IsAlive() then
			if (enemy:GetAbsOrigin() - parent_pos):Length2D() <= self.current_radius then
				local damage = flat + enemy:GetMaxHealth() * pct

				ApplyDamage({
					victim = enemy,
					attacker = parent,
					damage = damage,
					damage_type = DAMAGE_TYPE_MAGICAL,
					damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
					ability = ability,
				})
			end
		end
	end
end
