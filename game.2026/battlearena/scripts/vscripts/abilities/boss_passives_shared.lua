LinkLuaModifier("modifier_scaling_boss_crit", "abilities/modifier_scaling_boss_crit", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scaling_boss_bash", "abilities/modifier_scaling_boss_bash", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scaling_boss_lifesteal", "abilities/modifier_scaling_boss_lifesteal", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scaling_boss_split", "abilities/modifier_scaling_boss_split", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scaling_boss_evasion", "abilities/modifier_scaling_boss_evasion", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scaling_boss_mr", "abilities/modifier_scaling_boss_mr", LUA_MODIFIER_MOTION_NONE)

scaling_boss_crit = scaling_boss_crit or class({})
function scaling_boss_crit:GetIntrinsicModifierName() return "modifier_scaling_boss_crit" end

scaling_boss_bash = scaling_boss_bash or class({})
function scaling_boss_bash:GetIntrinsicModifierName() return "modifier_scaling_boss_bash" end

scaling_boss_lifesteal = scaling_boss_lifesteal or class({})
function scaling_boss_lifesteal:GetIntrinsicModifierName() return "modifier_scaling_boss_lifesteal" end

scaling_boss_split = scaling_boss_split or class({})
function scaling_boss_split:GetIntrinsicModifierName() return "modifier_scaling_boss_split" end

scaling_boss_evasion = scaling_boss_evasion or class({})
function scaling_boss_evasion:GetIntrinsicModifierName() return "modifier_scaling_boss_evasion" end

scaling_boss_mr = scaling_boss_mr or class({})
function scaling_boss_mr:GetIntrinsicModifierName() return "modifier_scaling_boss_mr" end
