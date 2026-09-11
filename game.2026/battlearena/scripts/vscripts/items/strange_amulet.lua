function StrangeAmuletStart( event )
	local caster = event.caster
	local ability = event.ability
	local charges = caster:GetStrength() 
	local duration = event.Duration

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_strange_amulet_activate_str", { duration = duration })	
	caster:SetModifierStackCount("modifier_strange_amulet_activate_str", ability, charges)
	if caster:HasModifier("modifier_strange_amulet_shell") then
		caster:RemoveModifierByName("modifier_strange_amulet_shell")
	end
	caster:AddNewModifier(caster, ability, "modifier_strange_amulet_shell", {duration = duration})
	caster:CalculateStatBonus(true)
end

function CheckCharges(event)
	local caster = event.caster
	local ability = event.ability
	local charges = ability:GetCurrentCharges()
	if charges == 0 then 
		caster:RemoveModifierByName("modifier_strange_amulet_bonus")
		return
	end
	if not caster:HasModifier("modifier_strange_amulet_bonus") then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_strange_amulet_bonus", {})
	end
	caster:SetModifierStackCount("modifier_strange_amulet_bonus", ability, charges)
	caster:CalculateStatBonus(true)
end
