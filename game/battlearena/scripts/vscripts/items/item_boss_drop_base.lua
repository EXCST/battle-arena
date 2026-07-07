item_boss_drop_base = item_boss_drop_base or class({})
item_boss_drop_base.boss_drop = true


-- this makes sure that items that dropped from boss, initially having no owner
-- properly get one when picked up, and can participate in shop recipes etc.
-- deprecated
-- function item_boss_drop_base:OnPickUpCustom()
-- 	self.boss_drop = true

-- 	Timers:CreateTimer(0.1, function()
-- 		if not IsValidEntity(self) then return end

-- 		local caster = self:GetCaster()

-- 		if not IsValidEntity(caster) then
-- 			print_format("Failed to set owner for boss drop %s - initial caster is invalid!", self:GetAbilityName())
-- 			return
-- 		end

-- 		if caster:IsCourier() or not caster:IsRealHero() then
-- 			caster = GameLoop.known_heroes[caster:GetPlayerOwnerID()]
-- 		end

-- 		if not IsValidEntity(caster) then
-- 			print_format("Failed to set owner for boss drop %s - retrieved caster (owner) is invalid!", self:GetAbilityName())
-- 			return
-- 		end

-- 		print_format("Set purchaser for boss drop %s to %s", self:GetAbilityName(), caster:GetUnitName())
-- 		self:SetPurchaser(self:GetCaster())
-- 		self.__in_transfer = true -- don't trigger item fast delivery
-- 	end)
-- end
