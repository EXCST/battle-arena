fireblade_scorched_blades = fireblade_scorched_blades or class({})
local ability = fireblade_scorched_blades

LinkLuaModifier( "modifier_fireblade_scorched_blades", 'heroes/fireblade/modifiers/modifier_fireblade_scorched_blades', LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_fireblade_scorched_blades_debuff", 'heroes/fireblade/modifiers/modifier_fireblade_scorched_blades_debuff', LUA_MODIFIER_MOTION_NONE )

function ability:GetIntrinsicModifierName()
	return "modifier_fireblade_scorched_blades"
end

function ability:GetCooldown( nLevel )
	local caster = self:GetCaster()
	if caster and caster:HasAbility("fireblade_talent_scorched_blades_silence") and caster:FindAbilityByName("fireblade_talent_scorched_blades_silence"):GetLevel() > 0 then
		return 4.0
	end
	return 0
end
