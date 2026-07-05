
item_broodmother_cocoon = class({})

function item_broodmother_cocoon:Precache(context)
    PrecacheResource("particle", "particles/custom/items/spider_cocoon/spider_spawn.vpcf", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_broodmother.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_broodmother.vsndevts", context)
end

function item_broodmother_cocoon:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local caster = caster
		local egg_duration = self:GetSpecialValueFor("egg_duration") 	

		EmitSoundOn("Hero_Broodmother.SpawnSpiderlingsImpact", caster)			

		local point = caster:GetAbsOrigin()
		local team = caster:GetTeam()

		local unit = CreateSummon(
			caster, 
			"npc_dota_item_broodmother_cocoon", 
			point, 
			-1, 
			nil, 
			nil, 
			nil, 
			nil
		)
		unit:AddNewModifier( unit, self, "modifier_item_broodmother_cocoon", {duration = -1} )
		caster:RemoveItem(self)
	end
end
--------------------------------------------------------
------------------------------------------------------------
modifier_item_broodmother_cocoon = class({
	IsHidden 				= function(self) return false end,
	IsPurgable 				= function(self) return false end,
	IsDebuff 				= function(self) return false end,
	IsBuff                  = function(self) return true end,
	RemoveOnDeath 			= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{MODIFIER_PROPERTY_MODEL_SCALE,
		} end,	
})

function modifier_item_broodmother_cocoon:OnCreated()
	self.meal_required = self:GetAbility():GetSpecialValueFor("meal_required")
	self.grow_scale = self:GetAbility():GetSpecialValueFor("max_scale")/self.meal_required
	if(not IsServer()) then
		return
	end
	self:StartIntervalThink(0.5)
end

function modifier_item_broodmother_cocoon:OnIntervalThink()
	local caster = self:GetCaster()
	local meal_required = self.meal_required
	
	local heroes = FindUnitsInRadius(caster:GetTeam(), 
									caster:GetAbsOrigin(), 
									nil, 
									200, 
									DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
									DOTA_UNIT_TARGET_HERO, 
									DOTA_UNIT_TARGET_FLAG_NONE, 
									FIND_ANY_ORDER, false)
	
	for i=1,#heroes do
		local hero = heroes[i]
		
		for k=0,8 do
			local item = hero:GetItemInSlot(k)
			if item then
				local item_name = item:GetName()
				if item_name == "item_fish" or item_name == "item_meat" then
					local item_charges = item:GetCurrentCharges()
					local meal_value = item:GetSpecialValueFor("meal_value")
					self:SetStackCount(self:GetStackCount()+item_charges*meal_value)
--					EmitSoundOn("DOTA_Item.Cheese.Activate",caster)-- broodmother/broo_deny_05
					hero:RemoveItem(item)
					if self:GetStackCount() <= 50 then
						EmitSoundOn("Hero_Broodmother.Pick",caster)					
					elseif self:GetStackCount() <= 75 then
						EmitSoundOn("broodmother_broo_deny_05",caster)										
					elseif self:GetStackCount() < 100 then
						EmitSoundOn("broodmother_broo_deny_12",caster)															
					end
				end	
			end
		end			
	end
	if self:GetStackCount() >= meal_required and caster:IsAlive() then
		local newItem = CreateItem( "item_broodmother_essence", nil, nil )
		CreateItemOnPositionSync( caster:GetAbsOrigin(), newItem )
		
		local effect = "particles/custom/items/spider_cocoon/spider_spawn.vpcf"
		local pfx = ParticleManager:CreateParticle(effect, PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(pfx, 0, caster:GetAbsOrigin()) -- Origin
		ParticleManager:ReleaseParticleIndex(pfx)
		StopSoundOn("Hero_Broodmother.Pick",caster)
		EmitSoundOn("Hero_Broodmother.SpawnSpiderlings",caster)

		caster:AddNoDraw()
		caster:Kill(nil,nil)		
	end
end

function modifier_item_broodmother_cocoon:GetModifierModelScale()
	return self:GetStackCount()*self.grow_scale
end


LinkLuaModifier("modifier_item_broodmother_cocoon", "items/custom/item_broodmother_cocoon", LUA_MODIFIER_MOTION_NONE, modifier_item_broodmother_cocoon)
