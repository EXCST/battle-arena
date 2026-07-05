function item_golden_lock_on_spell_start(keys)
	local caster = keys.caster
	local player = caster:GetPlayerOwner()
	local pID = caster:GetPlayerOwnerID()
	local hero = player:GetAssignedHero()
	local gold = hero:GetGold()
	if( gold < 25000 ) then
		return UF_FAIL_CUSTOM
	end 
	if( gold >= 25000 ) then
	keys.caster:SpendGold(keys.BonusGold, 0)
	keys.caster:RemoveItem(keys.ability)
	keys.caster:EmitSound("DOTA_Item.Hand_Of_Midas")
	local midas_particle = ParticleManager:CreateParticle("particles/econ/items/luna/luna_lucent_ti5_gold/luna_lucent_beam_impact_bits_notarget_ti_5_gold.vpcf", PATTACH_ABSORIGIN_FOLLOW, keys.caster)	
	ParticleManager:SetParticleControlEnt(midas_particle, 1, keys.caster, PATTACH_POINT_FOLLOW, "attach_hitloc", keys.caster:GetAbsOrigin(), false)
end
end