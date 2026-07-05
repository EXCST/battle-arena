item_soul_merchant = item_soul_merchant or class({})
LinkLuaModifier("modifier_item_soul_merchant", "items/soul_merchant/soul_merchant", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_soul_merchant_buff", "items/soul_merchant/modifier_item_soul_merchant_buff", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_soul_merchant_debuff", "items/soul_merchant/modifier_item_soul_merchant_buff", LUA_MODIFIER_MOTION_NONE)


function item_soul_merchant:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_dazzle/dazzle_nothl_voyage_tether.vpcf", context)
end


function item_soul_merchant:GetIntrinsicModifierName()
	return "modifier_item_soul_merchant"
end


function item_soul_merchant:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:TriggerSpellAbsorb(self) or target:TriggerSpellReflect(self) then return end
	if target:HasModifier("modifier_item_soul_merchant_debuff") or target:HasModifier("modifier_item_soul_collector_debuff") then return end

	local link_duration = self:GetSpecialValueFor("link_duration")
	link_duration = target:ApplyStatusResistance(link_duration, caster)
	local target_modifier = target:AddNewModifier(caster, self, "modifier_item_soul_merchant_debuff", {duration = link_duration})
	local caster_modifier = caster:AddNewModifier(caster, self, "modifier_item_soul_merchant_buff", {duration = link_duration})
	if caster_modifier and target_modifier then
		caster_modifier.target = target
		target_modifier.target = caster
		target_modifier.cm = caster_modifier
	end
end



modifier_item_soul_merchant = modifier_item_soul_merchant or class({})



function modifier_item_soul_merchant:IsHidden() return true end
function modifier_item_soul_merchant:IsPurgable() return false end
function modifier_item_soul_merchant:RemoveOnDeath() return false end
function modifier_item_soul_merchant:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_soul_merchant:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_item_soul_merchant:OnRefresh()
	if not IsValidEntity(self.ability) then return end

	self.str = self.ability:GetSpecialValueFor("str")
	self.int = self.ability:GetSpecialValueFor("int")
	self.hp_regen = self.ability:GetSpecialValueFor("hp_regen")
	self.hp = self.ability:GetSpecialValueFor("hp")
	self.mp_regen = self.ability:GetSpecialValueFor("mp_regen")
	self.damage = self.ability:GetSpecialValueFor("damage")

	if IsServer() then DamageToExp:Register(self.parent, self.ability, "soul_merchant") end
end


function modifier_item_soul_merchant:OnDestroy()
	if IsServer() then DamageToExp:Unregister(self.parent, self.ability, "soul_merchant") end
end


function modifier_item_soul_merchant:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, -- GetModifierBonusStats_Strength
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, -- GetModifierConstantHealthRegen
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS, -- GetModifierExtraHealthBonus
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, -- GetModifierPreAttack_BonusDamage
	}
end

function modifier_item_soul_merchant:GetModifierBonusStats_Strength() return self.str end
function modifier_item_soul_merchant:GetModifierBonusStats_Intellect() return self.int end
function modifier_item_soul_merchant:GetModifierConstantHealthRegen() return self.hp_regen end
function modifier_item_soul_merchant:GetModifierExtraHealthBonus() return self.hp end
function modifier_item_soul_merchant:GetModifierConstantManaRegen() return self.mp_regen end
function modifier_item_soul_merchant:GetModifierPreAttack_BonusDamage() return self.damage end
