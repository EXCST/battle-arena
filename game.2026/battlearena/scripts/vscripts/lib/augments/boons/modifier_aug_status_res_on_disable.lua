require("lib/augments/boons/modifier_augment_base")
modifier_aug_status_res_on_disable = modifier_aug_status_res_on_disable or class(modifier_augment_base)


LinkLuaModifier("modifier_augment_status_res_bonus", "lib/augments/boons/modifier_aug_status_res_on_disable", LUA_MODIFIER_MOTION_NONE)





function modifier_aug_status_res_on_disable:RefreshStats()
	self.parent = self:GetParent()

	self.stack_duration = self:GetStatFor("flat_stack_duration")

	self.status_res_per_stack = self:ComputeStat("status_res_per_stack")
end


function modifier_aug_status_res_on_disable:OnCreated()
	self:RefreshStats()

	-- CheckStateToTable returns keys as strings (for some reason)
	self.state_hexed = tostring(MODIFIER_STATE_HEXED)
	self.state_rooted = tostring(MODIFIER_STATE_ROOTED)
	self.state_feared = tostring(MODIFIER_STATE_FEARED)
end


function modifier_aug_status_res_on_disable:OnRefresh(old_stack_count)
	self:RefreshStats()
end


function modifier_aug_status_res_on_disable:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_MODIFIER_ADDED, -- OnModifierAdded
	}
end


function modifier_aug_status_res_on_disable:OnModifierAdded(event)
	if not IsValidEntity(event.unit) or event.unit ~= self.parent then return end

	local is_stun = event.added_buff:IsStunDebuff()

	local state = {}
	event.added_buff:CheckStateToTable(state)

	if is_stun or state[self.state_hexed] or state[self.state_feared] or state[self.state_rooted] then
		local modifier = self.parent:FindModifierByName("modifier_augment_status_res_bonus")

		if not modifier or modifier:IsNull() then
			modifier = self.parent:AddNewModifier(self.parent, nil, "modifier_augment_status_res_bonus", {duration = -1})
		end

		-- Add may fail on invulnerable or dead heroes
		if modifier and not modifier:IsNull() then
			modifier:AddIndependentStack(self.status_res_per_stack, self.stack_duration, nil, true)
		end
	end
end





modifier_augment_status_res_bonus = modifier_augment_status_res_bonus or class({})


function modifier_augment_status_res_bonus:GetTexture() return "item_titan_sliver" end
function modifier_augment_status_res_bonus:IsPurgable() return false end


function modifier_augment_status_res_bonus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
	}
end


function modifier_augment_status_res_bonus:GetModifierStatusResistanceStacking()
	return self:GetStackCount()
end


function modifier_augment_status_res_bonus:OnCreated()
	local parent = self:GetParent()

	self.effect_cast = ParticleManager:CreateParticle("particles/custom/generics/status_res_on_debuff/generic_status_res_on_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(self.effect_cast, 0, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:SetParticleControlEnt(self.effect_cast, 1, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:SetParticleControl(self.effect_cast, 3, Vector(1, 1, 1))
	ParticleManager:SetParticleControl(self.effect_cast, 5, Vector(1, 1, 1))
	ParticleManager:SetParticleControl(self.effect_cast, 8, Vector(0, 0, 0))

	self:AddParticle(self.effect_cast, false, false, -1, false, false)
end


function modifier_augment_status_res_bonus:OnStackCountChanged()
	local stacks = self:GetStackCount()

	ParticleManager:SetParticleControl(self.effect_cast, 3, Vector(stacks, 1, 1))
	ParticleManager:SetParticleControl(self.effect_cast, 8, Vector(stacks, 0, 0))
end
