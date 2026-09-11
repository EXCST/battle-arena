function Shell(params)
	local damage = params.Damage
	local attacker = params.attacker
	local hero = params.caster
	local ability = params.ability
	local return_damage_percent = ability:GetSpecialValueFor("return_damage") / 100
	print("take damage = ", damage)
	if not hero then return end
	if not attacker then return end

	if hero:PassivesDisabled() then return end
	
	if attacker == hero then return end

	if not attacker or hero:IsIllusion() then return end
	 
	if attacker:IsMagicImmune() then
		return
	end

	if attacker:HasModifier("modifier_item_blade_mail_reflect") then return end
	
	if hero:HasModifier("modifier_oracle_false_promise") then return end

	if attacker:IsInvulnerable() then return end

	
	damage = damage*return_damage_percent

	print("Return damage = ", damage)
	if damage > 2 then
		if attacker:GetHealth() < damage + 1 then
			attacker:Kill(ability, hero)
		else
			attacker:SetHealth(attacker:GetHealth() - damage - 1)
			attacker:Heal(1, ability) 
			ApplyDamage({ victim = attacker, attacker = hero, damage = 1, damage_type = DAMAGE_TYPE_PURE, ability = ability})
		end
	end

	if attacker:GetHealth() == 0 then
		attacker:Kill(ability, hero)
	end
end