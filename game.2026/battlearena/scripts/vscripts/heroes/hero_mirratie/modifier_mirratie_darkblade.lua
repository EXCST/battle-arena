-- ============================================================
-- MIRRATIE — Darkblade Adept (Crownfall 2024 Collector's Cache,
-- сет для Templar Assassin). Модель lanaya.vmdl «голая»: волосы/
-- маска, наплечники, броня и клинки — отдельные веараблы, которых
-- у кастомного героя нет (движок навешивает косметику только по
-- имени героя из реестра / override_hero).
-- ⚠️ KV Creature.AttachWearables в секции ГЕРОЯ в этой сборке молча
-- игнорируется (пометка stargazer, 2026-08-12) — одеваем рантайм:
-- prop_dynamic + FollowEntity(parent, true), паттерн
-- modifier_doom_litany_cosmetics (satan/doom, проверен в игре).
-- Defs из items_game клиента (извлечено из pak01_200.vpk):
--   head 28735, shoulder 28736, armor 28624, weapon 28738 (бандл 29158).
-- Модели лежат в models/items/lanaya/templar_assasin_false_devotion_*
-- (folder named by workshop submission "False Devotion").
-- Ambient-частицы (shoulder/weapon) — те же, что у сета в items_game.
-- Вешается в on_npc_spawned.lua (IsRealHero), снимается со смертью
-- (RemoveOnDeath true -> OnDestroy чистит пропы), на респавне
-- навешивается заново.
-- ============================================================

modifier_mirratie_darkblade = modifier_mirratie_darkblade or class({})

-- Дефолтные клинки TA встроены в базовую lanaya.vmdl (отдельной модели
-- нет) — weapon-проп может дать «двойные клинки». Если так в игре —
-- поставить false, weapon-часть сета пропустится.
local MIRRATIE_DARKBLADE_WEAPON_ENABLED = true

local MIRRATIE_DARKBLADE_PROPS = {
	{
		model = "models/items/lanaya/templar_assasin_false_devotion_head/templar_assasin_false_devotion_head.vmdl",
	},
	{
		model = "models/items/lanaya/templar_assasin_false_devotion_shoulder/templar_assasin_false_devotion_shoulder.vmdl",
		particles = {
			"particles/econ/items/templar_assassin/ta_2024_crownfall_cc/ta_cc_shoulder_ambient.vpcf",
			"particles/econ/items/templar_assassin/ta_2024_crownfall_cc/ta_cc_shoulder_ambient_behind_glows.vpcf",
		},
	},
	{
		model = "models/items/lanaya/templar_assasin_false_devotion_armor/templar_assasin_false_devotion_armor.vmdl",
	},
	{
		model = "models/items/lanaya/templar_assasin_false_devotion_weapon/templar_assasin_false_devotion_weapon.vmdl",
		weapon = true,
		particles = {
			"particles/econ/items/templar_assassin/ta_2024_crownfall_cc/ta_cc_weapon_ambient.vpcf",
		},
	},
}

function modifier_mirratie_darkblade:IsHidden() return true end
function modifier_mirratie_darkblade:IsPurgable() return false end
function modifier_mirratie_darkblade:RemoveOnDeath() return true end

function modifier_mirratie_darkblade:OnCreated()
	if not IsServer() then return end

	local parent = self:GetParent()
	if not parent or parent:IsNull() then return end

	self.props = {}
	for _, spec in ipairs(MIRRATIE_DARKBLADE_PROPS) do
		if not (spec.weapon and not MIRRATIE_DARKBLADE_WEAPON_ENABLED) then
			local prop = SpawnEntityFromTableSynchronous("prop_dynamic", { model = spec.model, targetname = "" })
			if prop and not prop:IsNull() then
				prop:FollowEntity(parent, true)
				table.insert(self.props, prop)
				for _, pfx in ipairs(spec.particles or {}) do
					local fx = ParticleManager:CreateParticle(pfx, PATTACH_ABSORIGIN_FOLLOW, prop)
					ParticleManager:ReleaseParticleIndex(fx)
				end
			end
		end
	end
end

function modifier_mirratie_darkblade:OnDestroy()
	if not IsServer() then return end
	if self.props then
		for _, prop in ipairs(self.props) do
			if prop and not prop:IsNull() then
				prop:RemoveSelf()
			end
		end
		self.props = nil
	end
end