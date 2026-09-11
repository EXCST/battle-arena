-- ============================================================================
-- Battle Arena: Augments — stores the primary attribute in stack count
-- ============================================================================

modifier_augment_primary_reader = modifier_augment_primary_reader or class({})

function modifier_augment_primary_reader:IsHidden() return true end
function modifier_augment_primary_reader:IsPurgable() return false end
function modifier_augment_primary_reader:RemoveOnDeath() return false end
function modifier_augment_primary_reader:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_augment_primary_reader:OnCreated()
	if not IsServer() then return end

	local parent = self:GetParent()

	if not parent:IsHero() then
		self:SetStackCount(DOTA_ATTRIBUTE_INVALID)
	else
		self:SetStackCount(parent:GetPrimaryAttribute())
	end
end


function modifier_augment_primary_reader:OnRefresh()
	self:OnCreated()
end
