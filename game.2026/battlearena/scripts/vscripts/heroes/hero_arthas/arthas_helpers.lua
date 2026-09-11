-- ============================================================
-- ARTHAS — хелперы героя (порт из Black Star, адаптация под нашу сборку)
-- ============================================================

ArthasHelpers = ArthasHelpers or {}

-- Аналог BS CreateGlobalParticle: частица, видимая всем.
-- В BS — CreateParticleForTeam на фонтане каждой команды (PATTACH_EYES_FOLLOW —
-- «screen»-частицы ульты рендерятся на клиенте своей команды).
-- Имя фонтана на нашей карте: "dota_fountain_<radiant|dire>" (проверено в KV
-- npc_units_custom.txt: секция dota_fountain); фолбэк — частица в мире,
-- видимая всем (ParticleManager:CreateParticle + PATTACH_WORLDORIGIN).
-- Частица НЕ уничтожается сама — это делает callback (таймер на destroy).
function ArthasHelpers:GlobalParticle(name, callback, pattach)
	local ps = {}
	local attached = 0
	for team = DOTA_TEAM_FIRST, DOTA_TEAM_CUSTOM_MAX do
		local fountain = Entities:FindByName(nil, "dota_fountain_" .. GetTeamName(team))
		if fountain then
			local p = ParticleManager:CreateParticleForTeam(name, pattach or PATTACH_WORLDORIGIN, fountain, team)
			if callback then callback(p) end
			ps[#ps + 1] = p
			attached = attached + 1
		end
	end
	if attached == 0 then
		local p = ParticleManager:CreateParticle(name, PATTACH_WORLDORIGIN, nil)
		if callback then callback(p) end
		ps[#ps + 1] = p
	end
	return ps
end
