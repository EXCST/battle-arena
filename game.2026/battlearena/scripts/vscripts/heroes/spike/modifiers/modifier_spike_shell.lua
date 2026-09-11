modifier_spike_shell = class({})

function modifier_spike_shell:IsHidden()
	return true
end

function modifier_spike_shell:IsPurgable()
	return false
end

function modifier_spike_shell:DestroyOnExpire()
	return false
end

function modifier_spike_shell:GetAttributes() 
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_spike_shell:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

local return_damage_values = {10, 12, 14, 16, 18, 19, 20}
local talent_shell_25 = "spike_special_bonus_shell_25"
local talent_shell_block = "spike_special_bonus_shell_block"
local ability_name = "angel_arena_shell"

function modifier_spike_shell:OnTakeDamage( params )
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end

	local hero = params.unit
	if hero:PassivesDisabled() then return end
	if hero:IsIllusion() then return end

	local ability = hero:FindAbilityByName(ability_name)
	if not ability or ability:IsNull() then return end
	if ability:GetLevel() < 1 then return end

	if params.inflictor == ability then return end

	if not params.attacker or params.attacker:IsNull() then return end
	if params.attacker:IsInvulnerable() then return end
	if params.damage <= 0 then return end

	local level = ability:GetLevel()
	local pct = return_damage_values[level] or return_damage_values[1]

	if hero:HasAbility(talent_shell_25) and hero:FindAbilityByName(talent_shell_25):GetLevel() > 0 then
		pct = pct + 10
	end

	local raw_damage = params.original_damage or params.damage

	if hero:HasAbility(talent_shell_block) and hero:FindAbilityByName(talent_shell_block):GetLevel() > 0 then
		if hero:GetHealth() > raw_damage then
			hero:Heal(raw_damage * pct / 100, ability)
		end
	end

	ApplyDamage({
		victim = params.attacker,
		attacker = hero,
		damage = raw_damage * pct / 100,
		damage_type = DAMAGE_TYPE_PURE,
		ability = ability,
	})
	return 0
end