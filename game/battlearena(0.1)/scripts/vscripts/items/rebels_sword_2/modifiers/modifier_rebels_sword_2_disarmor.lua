modifier_rebels_sword_2_disarmor = class({})
--------------------------------------------------------------------------------

function modifier_rebels_sword_2_disarmor:IsHidden() 			return false;  	end
function modifier_rebels_sword_2_disarmor:IsDebuff() 			return true;   	end 
function modifier_rebels_sword_2_disarmor:IsPurgable() 		return true; 	end
function modifier_rebels_sword_2_disarmor:DestroyOnExpire() 	return true; 	end

--------------------------------------------------------------------------------

function modifier_rebels_sword_2_disarmor:GetTexture()
	return "../items/rebels_sword_2"
end

--------------------------------------------------------------------------------

function modifier_rebels_sword_2_disarmor:DeclareFunctions() return 
{
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
}
end

--------------------------------------------------------------------------------

function modifier_rebels_sword_2_disarmor:GetModifierPhysicalArmorBonus(kv)        
	return -self:GetStackCount()    
end 