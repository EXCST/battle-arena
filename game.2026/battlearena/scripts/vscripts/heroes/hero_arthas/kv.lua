-- ============================================================
-- ARTHAS — RunScript-функции для datadriven-KV (hero_arthas.txt).
-- В BS KV ссылался на HideCaster/ShowCaster из "kv.lua", но таких функций
-- там не было (битая ссылка) — реализуем сами: AddNoDraw/RemoveNoDraw
-- (паттерн items/shift.lua HideUnit/ShowUnit).
-- ============================================================

function HideCaster(keys)
	local caster = keys.caster
	if caster and not caster:IsNull() then
		caster:AddNoDraw()
	end
end

function ShowCaster(keys)
	local caster = keys.caster
	if caster and not caster:IsNull() then
		caster:RemoveNoDraw()
	end
end
