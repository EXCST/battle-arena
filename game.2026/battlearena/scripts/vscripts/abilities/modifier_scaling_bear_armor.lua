require('lib/ability_kv')

modifier_scaling_bear_armor = class({})

function modifier_scaling_bear_armor:IsHidden()
	return false
end

function modifier_scaling_bear_armor:IsPurgable()
	return false
end

function modifier_scaling_bear_armor:GetTexture()
	return "custom/scaling_bear_armor"
end

-- GetSpecialValueFor сломан для кастомных способностей — читаем из KV напрямую.
-- Читаем на лету: в OnCreated интринзика GetAbility() ещё nil (вернётся 0).
function modifier_scaling_bear_armor:GetPurePct()
	local pure = AbilityKV:Get(self:GetAbility(), "pure_pct")
	if not pure or pure <= 0 then pure = 50 end
	return pure
end

function modifier_scaling_bear_armor:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DAMAGE_OUTGOING_PERCENTAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

-- 1. Уменьшаем физический урон на pure_pct%
function modifier_scaling_bear_armor:GetModifierDamageOutgoing_Percentage( params )
	if self:GetCaster():PassivesDisabled() then return 0 end
	if params.damage_type ~= DAMAGE_TYPE_PHYSICAL then return 0 end
	return -self:GetPurePct()
end

-- 2. Добавляем чистый урон вместо уменьшенного
function modifier_scaling_bear_armor:OnAttackLanded( params )
	if IsServer() then
		if self:GetCaster():PassivesDisabled() then return end
		if params.attacker ~= self:GetParent() then return end
		local target = params.target
		if not target or target:IsNull() then return end
		if target:GetHealth() <= 0 then return end

		-- params.damage уже с учётом уменьшения на pure_pct%
		-- Вычисляем сколько должно быть чистого урона
		local pure = params.damage * self:GetPurePct() / (100 - self:GetPurePct())

		local info = {
			victim = target,
			attacker = self:GetCaster(),
			damage = pure,
			damage_type = DAMAGE_TYPE_PURE,
		}
		ApplyDamage( info )
	end
end
