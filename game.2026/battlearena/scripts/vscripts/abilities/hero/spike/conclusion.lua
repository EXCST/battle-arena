local forbidden_refresh = {
	["item_refresher"] 					= 1,
	["item_recovery_orb"]				= 1,	
	["spike_conclusion"]				= 1,	
}

function ForEveryAbility( caster, functor )
	for i = 0, caster:GetAbilityCount() - 1 do
		functor( caster:GetAbilityByIndex(i) )
	end

	for i = 0, 12 do
		functor( caster:GetItemInSlot(i) )
	end

	-- TP Slot
	functor( caster:GetItemInSlot(15) )

	-- neutral slot
	functor( caster:GetItemInSlot(16) )
end

function OnSpellStart( keys ) 
	local caster = keys.caster
	local selfAbility = keys.ability

	caster:Purge( false, true, false, true, false )

	while(caster:HasModifier("modifier_huskar_burning_spear_counter")) do
		caster:RemoveModifierByName("modifier_huskar_burning_spear_counter")
	end

	caster:RemoveModifierByName("modifier_huskar_burning_spear_debuff")
	caster:RemoveModifierByName("modifier_dazzle_weave_armor")
	caster:RemoveModifierByName("modifier_dazzle_weave_armor_debuff")

	selfAbility.list = {}
	selfAbility.startTime = GameRules:GetGameTime()


	local subrefresh = function(ability)
		if not ability then return end

		local name = ability:GetName()

		if forbidden_refresh[ name ] then return end

		local cd = ability:GetCooldownTimeRemaining()

		if cd > 0 then
			selfAbility.list[name] = cd
		end

		ability:RefreshCharges()
		ability:EndCooldown()	
	end

	ForEveryAbility( caster, subrefresh )
end

function Active_OnDestroy( keys )
	local caster = keys.caster 
	local selfAbility = keys.ability 

	local timeDiff = GameRules:GetGameTime() - selfAbility.startTime

	local revertCooldown = function(ability)
		if not ability then return end

		local cd = ability:GetCooldownTimeRemaining()

		if cd > 0 then return end

		local newCd = selfAbility.list[ ability:GetName() ]

		if newCd == nil then return end

		newCd = math.max(0, newCd - timeDiff)

		if newCd > 0 then
			ability:StartCooldown(newCd)
		end
	end

	ForEveryAbility( caster, revertCooldown )
end

function Active_CooldownIncrease( keys )
	local caster = keys.caster
	local ability = keys.event_ability
	local multipler = keys.Multipler / 100

	local level = math.max(ability:GetLevel(), 1)
	local wantCd = ability:GetCooldown(level - 1) * caster:GetCooldownReduction()

	wantCd = wantCd * multipler

	ability:EndCooldown() 
	ability:StartCooldown(wantCd)
end

function OnKill( keys )
	local modifier_name = "modifier_spike_special_bonus_attack"
	local caster = keys.caster 
	local ability = keys.ability 
	local target = keys.unit 
	local damage_by_hero = ability:GetSpecialValueFor("damage_by_hero")
	local damage_by_creep = ability:GetSpecialValueFor("damage_by_creep")

	if(not caster:HasModifier(modifier_name) ) then
		ability:ApplyDataDrivenModifier(caster, caster, modifier_name, {}) 
	end

	local stack_count = caster:GetModifierStackCount(modifier_name, caster) or 0

	if( target:IsRealHero() ) then
		stack_count = stack_count + damage_by_hero
	else
		ability.killed_creeps = (ability.killed_creeps or 0) + 1 
		if(ability.killed_creeps >= 1 ) then
			stack_count = stack_count + damage_by_creep
			ability.killed_creeps = 0
		end
	end

	caster:SetModifierStackCount(modifier_name, caster, stack_count)
end