UltimateGateFilter = {}

local GATED_ULTIMATES = {
	spike_conclusion = true,
	shadowsong_dark_reflection = true,
	fireblade_firestrip = true,
	stegius_desolating_touch = true,
	saber_excalibur = true,
	arthas_vsolyanova = true,
	stargazer_cosmic_countdown = true,
	mirratie_impaling_shot = true,
	satan_curse = true,
	huntress_hunting_spirit = true,
	hola_rescue = true,
	joe_black_song = true,
}

function UltimateGateFilter:ExecuteOrderFilter( event )

	if (event.order_type ~= DOTA_UNIT_ORDER_TRAIN_ABILITY) then
		return true
	end

	local hero = EntIndexToHScript(event.units["0"])
	if not hero or hero:IsNull() then
		return true
	end

	local ability = nil
	if event.entindex_ability then
		ability = EntIndexToHScript(event.entindex_ability)
	elseif event.ability_index then
		ability = EntIndexToHScript(event.ability_index)
	end

	if not ability or ability:IsNull() then
		return true
	end

	if not GATED_ULTIMATES[ability:GetAbilityName()] then
		return true
	end

	if hero:GetLevel() < (ability:GetLevel() + 1) * 6 then
		return false
	end

	return true
end
