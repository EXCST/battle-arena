-- ============================================================================
-- Battle Arena: Augments — boon catalog (global generic picks)
-- ============================================================================

AugmentCatalog = AugmentCatalog or {}

DEFAULT_BOON_MOD_DIR = "lib/augments/boons/"


function AugmentCatalog:Init()
	AugmentCatalog.catalog_data = LoadKeyValues("scripts/augments/catalog.txt")

	AugmentCatalog.by_floor = {
		[AUGMENT_TIER.COMMON] = {},
		[AUGMENT_TIER.RARE] = {},
		[AUGMENT_TIER.EPIC] = {},
	}

	for boon_name, boon_data in pairs(AugmentCatalog.catalog_data) do
		boon_data.impl = boon_data.impl or "modifier"

		AugmentMath:Normalize(boon_data, boon_name, AUGMENT_KIND.GENERIC)

		if boon_data.impl == "modifier" and not boon_data.off then
			local modifier_name = "modifier_" .. boon_name
			LinkLuaModifier(
				modifier_name,
				(boon_data.mod_path or DEFAULT_BOON_MOD_DIR) .. modifier_name,
				boon_data.mod_kind or LUA_MODIFIER_MOTION_NONE
			)
		end

		if not boon_data.off then
			table.insert(AugmentCatalog.by_floor[boon_data.floor], boon_name)
		end
	end

	-- flat list of every boon definition (used by the roll)
	AugmentCatalog.catalog_list = table.make_value_table(AugmentCatalog.catalog_data)
end


AugmentCatalog:Init()
