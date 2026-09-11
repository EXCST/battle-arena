-- ============================================================================
-- Battle Arena: Augments — champion creep modifier (+ return-to-spawn state)
-- ============================================================================

modifier_ba_champion = modifier_ba_champion or class({})

LinkLuaModifier("modifier_ba_champion_returning", "lib/augments/champions/modifier_ba_champion", LUA_MODIFIER_MOTION_NONE)


function modifier_ba_champion:IsPurgable() return false end
function modifier_ba_champion:GetTexture() return self:GetStackCount() == -2 and "orb_rare" or "orb_epic" end

local CHAMP_RARE = AUGMENT_TIER.RARE or 2
local CHAMP_EPIC = AUGMENT_TIER.EPIC or 4

local status_fx_by_rarity = {
	[CHAMP_RARE] = "particles/creep_champion/creep_champion_status_effect.vpcf",
	[CHAMP_EPIC] = "particles/creep_champion_epic/creep_champion_epic_status_effect.vpcf"
}


function modifier_ba_champion:OnCreated(kv)
	self:SetHasCustomTransmitterData(true)
	self.parent = self:GetParent()
	if not IsServer() then return end

	self:SetStackCount(-kv.kind)

	self.kind = kv.kind
	self.status_fx_name = status_fx_by_rarity[kv.kind] or status_fx_by_rarity[CHAMP_RARE]
	self:SendBuffRefreshToClients()

	-- tint the model body by rarity (rare = green, epic = fire)
	if kv.kind == CHAMP_EPIC then
		self.parent:SetRenderColor(255, 90, 30)
	else
		self.parent:SetRenderColor(70, 255, 110)
	end

	self.base_location = self.parent:GetOrigin()

	self:StartIntervalThink(1)
end


function modifier_ba_champion:OnDestroy()
	if not IsServer() then return end

	local p = self:GetParent()
	if p and not p:IsNull() then
		p:SetRenderColor(255, 255, 255)
	end
end


function modifier_ba_champion:OnIntervalThink()
	local origin = self.parent:GetOrigin()

	local should_move_back = (origin - self.base_location):Length2D() > 1000

	if should_move_back then
		self.parent:AddNewModifier(self.parent, nil, "modifier_ba_champion_returning", { duration = 2 })
		self.parent:InterruptMotionControllers(true)
		self.parent:Purge(false, true, false, true, true)
		self.parent:MoveToPosition(self.base_location)
	end
end


function modifier_ba_champion:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION, -- GetModifierProvidesFOWVision
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, -- GetModifierMagicalResistanceBonus
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, -- GetModifierIncomingDamage_Percentage
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, -- GetModifierMoveSpeedBonus_Constant
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, -- GetModifierAttackSpeedBonus_Constant
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- GetModifierPhysicalArmorBonus
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, -- GetModifierHealthRegenPercentage
	}
end


function modifier_ba_champion:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true, -- the minimap icon comes from the separate dummy
	}
end


function modifier_ba_champion:GetModifierProvidesFOWVision() return 1 end
function modifier_ba_champion:GetModifierMagicalResistanceBonus() return 35 end
function modifier_ba_champion:GetModifierIncomingDamage_Percentage() return -40 end
function modifier_ba_champion:GetModifierMoveSpeedBonus_Constant() return 100 end
function modifier_ba_champion:GetModifierAttackSpeedBonus_Constant() return 200 + self.parent:GetLevel() * 3 end
function modifier_ba_champion:GetModifierPhysicalArmorBonus() return 10 + self.parent:GetLevel() * 1.5 end
function modifier_ba_champion:GetModifierHealthRegenPercentage() return math.lerp(1, 10, self.parent:GetLevel() / 100.0) end

function modifier_ba_champion:StatusEffectPriority() return 999999999 end -- fountain modifier is 19999
function modifier_ba_champion:GetStatusEffectName() return status_fx_by_rarity[self.kind] or status_fx_by_rarity[CHAMP_RARE] end
function modifier_ba_champion:AddCustomTransmitterData() return { kind = self.kind } end
function modifier_ba_champion:HandleCustomTransmitterData(data) self.kind = data.kind end


modifier_ba_champion_returning = modifier_ba_champion_returning or class({})


function modifier_ba_champion_returning:IsPurgable() return false end
function modifier_ba_champion_returning:IsHidden() return true end
function modifier_ba_champion_returning:CheckState()
	return {
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
		[MODIFIER_STATE_DISARMED] = true
	}
end


function modifier_ba_champion_returning:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, -- GetModifierMoveSpeed_Absolute
		MODIFIER_PROPERTY_DISABLE_AUTOATTACK, -- GetDisableAutoAttack
	}
end


function modifier_ba_champion_returning:GetModifierMoveSpeed_Absolute() return 750 end


function modifier_ba_champion_returning:GetDisableAutoAttack()
	return 1
end
