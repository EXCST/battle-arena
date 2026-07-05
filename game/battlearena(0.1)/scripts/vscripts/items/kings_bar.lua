item_kings_bar = item_kings_bar or class({})

LinkLuaModifier( "modifier_item_kings_bar", "items/kings_bar", LUA_MODIFIER_MOTION_NONE )

function item_kings_bar:GetIntrinsicModifierName()
	return "modifier_item_kings_bar"
end

function item_kings_bar:OnSpellStart()
  local caster = self:GetCaster()

  -- Basic Dispel
  caster:Purge( false, true, false, false, false )

  -- Remove debuffs that are removed only with BKB/Spell Immunity/Debuff Immunity
  caster:RemoveModifierByName("modifier_slark_pounce_leash")
  caster:RemoveModifierByName("modifier_invoker_deafening_blast_disarm")
  caster:RemoveModifierByName("modifier_oracle_fates_edict")

	-- Apply spell immunity buff
  caster:AddNewModifier(caster, self, "modifier_black_king_bar_immune", {duration = self:GetSpecialValueFor("duration")})

  -- Sound
  caster:EmitSound( "DOTA_Item.BlackKingBar.Activate" )
end

---------------------------------------------------------------------------------------------------

modifier_item_kings_bar = modifier_item_kings_bar or class({})

function modifier_item_kings_bar:IsHidden()
	return true
end

function modifier_item_kings_bar:IsDebuff()
	return false
end

function modifier_item_kings_bar:IsPurgable()
	return false
end

function modifier_item_kings_bar:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_kings_bar:OnCreated()
	local spell = self:GetAbility()
  if spell and not spell:IsNull() then
	  self.str = spell:GetSpecialValueFor( "bonus_strength" )
	  self.damage = spell:GetSpecialValueFor( "bonus_damage" )
  end
end

modifier_item_kings_bar.OnRefresh = modifier_item_kings_bar.OnCreated

function modifier_item_kings_bar:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
end

function modifier_item_kings_bar:GetModifierPreAttack_BonusDamage()
	return self.damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_kings_bar:GetModifierBonusStats_Strength()
	return self.str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_kings_bar:CheckState()
  local state = {
    [MODIFIER_STATE_CANNOT_MISS] = true,
  }
  return state
end