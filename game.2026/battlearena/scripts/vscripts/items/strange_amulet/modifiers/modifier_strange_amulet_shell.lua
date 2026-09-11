modifier_strange_amulet_shell = class({})

function modifier_strange_amulet_shell:IsHidden() return true end
function modifier_strange_amulet_shell:IsPurgable() return true end
function modifier_strange_amulet_shell:RemoveOnDeath() return false end

function modifier_strange_amulet_shell:OnCreated(kv)
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
end

function modifier_strange_amulet_shell:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

if IsServer() then
	function modifier_strange_amulet_shell:OnTakeDamage(params)
		if params.unit ~= self.parent then return end
		if not self.ability or self.ability:IsNull() then return end
		if not params.attacker or params.attacker:IsNull() then return end
		if params.attacker == self.parent then return end
		if self.parent:PassivesDisabled() then return end
		if self.parent:IsIllusion() then return end
		if params.attacker:IsMagicImmune() then return end
		if params.attacker:IsInvulnerable() then return end
		if params.attacker:HasModifier("modifier_item_blade_mail_reflect") then return end
		if self.parent:HasModifier("modifier_oracle_false_promise") then return end

		local return_pct = self.ability:GetSpecialValueFor("return_damage") / 100
		if return_pct <= 0 then return end

		local damage = params.damage * return_pct
		if damage <= 2 then return end

		if params.attacker:GetHealth() < damage + 1 then
			params.attacker:Kill(self.ability, self.parent)
		else
			params.attacker:SetHealth(params.attacker:GetHealth() - damage - 1)
			params.attacker:Heal(1, self.ability)
			ApplyDamage({ victim = params.attacker, attacker = self.parent, damage = 1, damage_type = DAMAGE_TYPE_PURE, ability = self.ability })
		end

		if params.attacker:GetHealth() == 0 then
			params.attacker:Kill(self.ability, self.parent)
		end
	end
end
