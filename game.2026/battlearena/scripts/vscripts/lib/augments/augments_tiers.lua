-- ============================================================================
-- Battle Arena: Augments — constants and tier definitions
-- ============================================================================

-- Rarity tiers (binary weights: epic = 4, rare = 2, common = 1)
AUGMENT_TIER = {
	COMMON = 1,
	RARE = 2,
	EPIC = 4,
}

TIER_BY_TEXT = {
	common = AUGMENT_TIER.COMMON,
	rare = AUGMENT_TIER.RARE,
	epic = AUGMENT_TIER.EPIC,
}

TEXT_BY_TIER = {
	[AUGMENT_TIER.COMMON] = "common",
	[AUGMENT_TIER.RARE] = "rare",
	[AUGMENT_TIER.EPIC] = "epic",
}

-- What kind of card a pick can be
AUGMENT_KIND = {
	ABILITY = 1, -- a stat of a hero ability
	GENERIC = 2, -- a global boon from the catalog
}

-- Cards offered per hand
CARDS_PER_HAND = {
	[AUGMENT_KIND.ABILITY] = 3,
	[AUGMENT_KIND.GENERIC] = 1,
}

-- How a stat accumulates
AUGMENT_MODE = {
	ADD = 1,
	MULT = 2,
}

MODE_BY_TEXT = {
	ADD = AUGMENT_MODE.ADD,
	MULT = AUGMENT_MODE.MULT,
}

-- Abilities whose intrinsic modifiers need a level reset after an update
LEVEL_RESET_ABILITIES = {
	medusa_split_shot = true,
	medusa_mana_shield = true,
	lone_druid_spirit_link = true,
	necrolyte_heartstopper_aura = true,
	lycan_feral_impulse = true,
	gyrocopter_side_gunner_spawn_ability = true,
}

-- Orbs needed to earn an upgrade of each tier (first time)
ORB_START = {
	[AUGMENT_TIER.COMMON] = 20, -- 20 creeps
	[AUGMENT_TIER.RARE] = 4,    -- 4 hero kills
	[AUGMENT_TIER.EPIC] = 1,    -- 1 boss
}

-- Each next orb goal grows by this much
ORB_GROWTH = {
	[AUGMENT_TIER.COMMON] = 30,
	[AUGMENT_TIER.RARE] = 4,
	[AUGMENT_TIER.EPIC] = 1,
}

-- Hard caps for orb goals (epic caps so epic orbs can't be farmed infinitely)
ORB_CEILING = {
	[AUGMENT_TIER.COMMON] = 9999,
	[AUGMENT_TIER.RARE] = 9999,
	[AUGMENT_TIER.EPIC] = 4,
}

-- Reroll cost per tier (free reroll points spent)
REROLL_COST = {
	[AUGMENT_TIER.COMMON] = 1,
	[AUGMENT_TIER.RARE] = 2,
	[AUGMENT_TIER.EPIC] = 4,
}

-- Default target used by multiplicative (asymptote) stat growth
DEFAULT_MULT_LIMIT = 50

-- How much a picked value may deviate from its KV base: +/- 25%
PICK_VARIANCE = 0.25

-- Weight of a never-picked card during a roll
WEIGHT_POINTS = 30

-- Free rerolls granted once per match (no monetization)
FREE_REROLLS_PER_MATCH = 100

-- Estimated net worth of a single upgrade (economy metric)
GOLD_PER_UPGRADE = 125
