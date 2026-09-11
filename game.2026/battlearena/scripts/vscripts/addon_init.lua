print("[BATTLEARENA] addon_init.lua loaded!")
require('lib/talent_support')
require('lib/base_lua_helpers')

-- extensions required by the augments system (CDOTA_BaseNPC extension loads later in addon_game_mode)
require('extensions/table')
require('extensions/string')
require('extensions/math')
require('extensions/cdota_modifier_lua')

-- augments system core (early load for LinkLuaModifier)
require('lib/augments/augments_tiers')
require('lib/augments/augments_math')
require('lib/augments/augments_catalog')

function CEntityInstance:GetNetworkableEntityInfo(key)
    local t = CustomNetTables:GetTableValue("custom_entity_values", tostring(self:GetEntityIndex())) or {}
    return t[key]
end

pcall(LinkLuaModifier, "modifier_strange_amulet_shell", "items/strange_amulet/modifiers/modifier_strange_amulet_shell", LUA_MODIFIER_MOTION_NONE)