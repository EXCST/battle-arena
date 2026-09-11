function OnAttack( keys )
	local caster 	= keys.caster
	local ability 	= keys.ability
	local target 	= keys.target
	local cooldown 	= ability:GetCooldown(ability:GetLevel())

	print("[AZRAEL] OnAttack called. caster=" .. tostring(caster) .. " target=" .. tostring(target))

	if not caster:IsRangedAttacker() then print("[AZRAEL] not ranged"); return end
	if caster:IsIllusion() then print("[AZRAEL] illusion"); return end

	if ability:GetCooldownTimeRemaining() ~= 0 then print("[AZRAEL] on cd"); return end
	if caster:IsHexed() then print("[AZRAEL] hexed"); return end 

	if (caster:GetAbsOrigin() - target:GetAbsOrigin() ):Length2D() > caster:Script_GetAttackRange()*1.3 then print("[AZRAEL] too far"); return end

	ability:StartCooldown(cooldown)

	caster:PerformAttack(target, true, true, true, true, true, false, false)

	if not target or target:IsNull() or not target:IsAlive() then print("[AZRAEL] target dead/nil"); return end

	local curse = caster:FindAbilityByName("huntress_curse_arrow")
	print("[AZRAEL] curse ability found: " .. tostring(curse))
	if not curse then print("[AZRAEL] not huntress (no curse arrow)"); return end

	if not caster:HasModifier("modifier_huntress_hunting_spirit") then print("[AZRAEL] no hunting spirit"); return end

	print("[AZRAEL] applying curse arrow")
	target:Purge(true, false, false, false, false)
	target:RemoveModifierByName("modifier_huntress_curse_arrow")
	curse:SetLevel(1)
	curse:SetHidden(false)
	print("[AZRAEL] curse shown")
	local mod = target:AddNewModifier(caster, curse, "modifier_huntress_curse_arrow", { duration = 3.0 })
	print("[AZRAEL] modifier applied: " .. tostring(mod))
end
