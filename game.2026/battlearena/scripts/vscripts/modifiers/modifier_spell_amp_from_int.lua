-- ============================================================================
-- Battle Arena: компенсация за убранный MR от интеллекта (modifier_override_magic_resist).
-- Каждый кадр снимает текущий инт и превращает его в spell amp: 1% за 24 инта.
-- Множители spell_amp_tune (per-способность) применяются ТОЛЬКО к инт-части,
-- остальной spell amp (аугменты/предметы) не трогается.
-- Механика: аналог AAF modifier_spell_amp_from_int; адаптировано под бонусные
-- статы battlearena (GetIntellect(true) — статы аугментов идут модификаторами,
-- а не в базу).
-- ============================================================================

modifier_spell_amp_from_int = modifier_spell_amp_from_int or class({})

-- Множитель инт-spell amp для способностей (0 = полностью исключить из бонуса).
-- Список скопирован из AAF (референс-баланс); имена, которых нет в battlearena,
-- просто не матчатся. Тюнинг кастомных способностей — отдельной задачей.
modifier_spell_amp_from_int.spell_amp_tune = {
	abyssal_underlord_firestorm = 0,
	elder_titan_earth_splitter = 0,
	winter_wyvern_arctic_burn = 0,
	doom_bringer_infernal_blade = 0,
	doom_bringer_doom = 0.25,
	enigma_midnight_pulse = 0,
	sandking_caustic_finale = 0,
	zuus_static_field = 0,
	huskar_life_break = 0,
	phoenix_sun_ray = 0,
	phantom_assassin_fan_of_knives = 0,
	jakiro_liquid_ice = 0,
	jakiro_liquid_fire = 0,
	item_spirit_vessel = 0,
	venomancer_poison_nova = 0,
	venomancer_noxious_plague = 0,
	bloodseeker_blood_mist = 0,
	ringmaster_impalement = 0,
	kez_raptor_dance = 0,
	bloodseeker_rupture = 0,
	necrolyte_reapers_scythe = 0,
	witch_doctor_maledict = 0,
	huskar_burning_spear = 0,
	omniknight_hammer_of_purity = 0,
	skywrath_mage_arcane_bolt = 0.4,
	warlock_fatal_bonds_lua = 0,

	centaur_stampede = 0,
	antimage_mana_void = 0,
	chen_martyrdom = 0,

	obsidian_destroyer_arcane_orb = 0.2,
	obsidian_destroyer_sanity_eclipse = 0,
	silencer_glaives_of_wisdom = 0,
	nyx_assassin_jolt = 0.25,
	muerta_pierce_the_veil = 0,
	muerta_gunslinger = 0,
	item_havoc_hammer = 0.25,
	item_devastator = 0.15,
	item_devastator_2 = 0.15,
	item_devastator_3 = 0.15,
	item_witch_blade = 0.25,
	item_ethereal_blade = 0.25,
	item_ethereal_blade_2 = 0.25,
	item_ethereal_blade_3 = 0.25,
	bane_enfeeble = 0.5,
	bane_fiends_grip = 0.5,
	bane_brain_sap = 0.25,
	enigma_black_hole = 0.25,
	pudge_dismember = 0.4,
	centaur_double_edge = 0.50,
	item_soul_collector = 0.5,
	item_soul_merchant = 0.5,
	item_rubick_dagon = 0.5,
	disruptor_electromagnetic_repulsion = 0.3,

	morphling_adaptive_strike_agi = 0.1,
	ancient_apparition_chilling_touch = 0.5,

	shadow_demon_disseminate = 0,
	item_orchid = 0,
	item_bloodthorn = 0,
	item_bloodthorn_2 = 0,
	item_bloodthorn_3 = 0,
	item_hydras_breath = 0,

	primal_beast_trample = 0,
}


function modifier_spell_amp_from_int:IsHidden() return false end
function modifier_spell_amp_from_int:IsPurgable() return false end
function modifier_spell_amp_from_int:RemoveOnDeath() return false end
function modifier_spell_amp_from_int:GetTexture() return "int_spell_amp" end


function modifier_spell_amp_from_int:OnCreated()
	self.parent = self:GetParent()
	self.raw_spell_amp = 0
	self.spell_amp_from_int = 0

	self:StartIntervalThink(0)
	self:OnIntervalThink()
end


function modifier_spell_amp_from_int:OnIntervalThink()
	if IsServer() and self.parent:IsAlive() then
		-- снимок текущего spell amp без собственного вклада (защита от рекурсии)
		self.__flag = true
		self.raw_spell_amp = self.parent:GetSpellAmplification(false)
		self.__flag = false
	end

	self.spell_amp_from_int = self.parent:GetIntellect(true) / 24 -- 24 инта = 1% spell amp
end


function modifier_spell_amp_from_int:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, -- GetModifierSpellAmplify_Percentage
	}
end


function modifier_spell_amp_from_int:GetModifierSpellAmplify_Percentage(event)
	if self.__flag then return 0 end
	if not IsValidEntity(self.parent) then return 0 end

	local inflictor = event.inflictor

	if IsClient() then
		return self.spell_amp_from_int
	end

	local new_spell_amp = self.raw_spell_amp + (self.spell_amp_from_int) / 100.0

	if IsValidEntity(inflictor) then
		local ability_name = inflictor:GetAbilityName()
		local multiplier = self.spell_amp_tune[ability_name]

		if multiplier then
			new_spell_amp = new_spell_amp * multiplier
		end
	end

	return (new_spell_amp - self.raw_spell_amp) * 100.0
end
