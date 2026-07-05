item_soul_collector = item_soul_collector or class({})
LinkLuaModifier("modifier_item_soul_collector", "items/soul_collector/soul_collector", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_soul_collector_buff", "items/soul_collector/modifier_item_soul_collector_buff", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_soul_collector_debuff", "items/soul_collector/modifier_item_soul_collector_buff", LUA_MODIFIER_MOTION_NONE)


function item_soul_collector:Precache(context)
	PrecacheResource("particle", "particles/econ/items/drow/drow_arcana/drow_arcana_silence_wave.vpcf", context)
end


function item_soul_collector:GetIntrinsicModifierName()
	return "modifier_item_soul_collector"
end


function item_soul_collector:OnSpellStart()
	local caster = self:GetCaster()
	local cast_position = self:GetCursorPosition()

	local width = self:GetSpecialValueFor("proj_width")
	local distance = self:GetSpecialValueFor("proj_distance") + caster:GetCastRangeBonus()
	local speed = self:GetSpecialValueFor("proj_speed")

	local velocity = (cast_position - caster:GetOrigin()):Normalized() * speed

	ProjectileManager:CreateLinearProjectile({
		EffectName 		= "particles/econ/items/drow/drow_arcana/drow_arcana_silence_wave.vpcf",
		Ability 		= self,
		vSpawnOrigin 	= caster:GetOrigin(),
		vVelocity 		= velocity,
		fDistance 		= distance,
		fStartRadius 	= width,
		fEndRadius 		= width,
		Source 			= caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	})
end


function item_soul_collector:OnProjectileHit(target, location)
	if not IsValidEntity(target) then return end
	local caster = self:GetCaster()

	if target:HasModifier("modifier_item_soul_merchant_debuff") or target:HasModifier("modifier_item_soul_collector_debuff") then return end

	local link_duration = self:GetSpecialValueFor("link_duration")
	link_duration = target:ApplyStatusResistance(link_duration, caster)
	local target_modifier = target:AddNewModifier(caster, self, "modifier_item_soul_collector_debuff", {duration = link_duration})
	local caster_modifier = caster:AddNewModifier(caster, self, "modifier_item_soul_collector_buff", {duration = link_duration})
	if caster_modifier and target_modifier then
		caster_modifier.target = target
		target_modifier.target = caster
		target_modifier.cm = caster_modifier
	end
end


modifier_item_soul_collector = modifier_item_soul_collector or class({})

function modifier_item_soul_collector:IsHidden() return true end
function modifier_item_soul_collector:IsPurgable() return false end
function modifier_item_soul_collector:RemoveOnDeath() return false end
function modifier_item_soul_collector:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_soul_collector:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_item_soul_collector:OnRefresh()
	if not IsValidEntity(self.ability) then return end

	self.str = self.ability:GetSpecialValueFor("str")
	self.int = self.ability:GetSpecialValueFor("int")
	self.hp_regen = self.ability:GetSpecialValueFor("hp_regen")
	self.hp = self.ability:GetSpecialValueFor("hp")
	self.mp_regen = self.ability:GetSpecialValueFor("mp_regen")
	self.damage = self.ability:GetSpecialValueFor("damage")

	if IsServer() then DamageToExp:Register(self.parent, self.ability, "soul_collector") end
end

function modifier_item_soul_collector:OnDestroy()
	if IsServer() then DamageToExp:Unregister(self.parent, self.ability, "soul_collector") end
end


function modifier_item_soul_collector:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, -- GetModifierBonusStats_Strength
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, -- GetModifierConstantHealthRegen
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS, -- GetModifierExtraHealthBonus
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, -- GetModifierPreAttack_BonusDamage
	}
end

function modifier_item_soul_collector:GetModifierBonusStats_Strength() return self.str end
function modifier_item_soul_collector:GetModifierBonusStats_Intellect() return self.int end
function modifier_item_soul_collector:GetModifierConstantHealthRegen() return self.hp_regen end
function modifier_item_soul_collector:GetModifierExtraHealthBonus() return self.hp end
function modifier_item_soul_collector:GetModifierConstantManaRegen() return self.mp_regen end
function modifier_item_soul_collector:GetModifierPreAttack_BonusDamage() return self.damage end
