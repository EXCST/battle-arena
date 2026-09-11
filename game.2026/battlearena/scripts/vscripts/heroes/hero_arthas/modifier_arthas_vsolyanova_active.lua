require('lib/ability_kv')
require('heroes/hero_arthas/arthas_helpers')

modifier_arthas_vsolyanova_active = class({
	IsPurgable          = function() return false end,
	IsHidden            = function() return true end,
	GetEffectName       = function() return "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis.vpcf" end,
	GetEffectAttachType = function() return PATTACH_ABSORIGIN_FOLLOW end,
})

function modifier_arthas_vsolyanova_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
		MODIFIER_PROPERTY_MODEL_CHANGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

-- ⚠️ GetSpecialValueFor в этой сборке возвращает 0 — читаем KV через AbilityKV:Get.
-- Читать на лету (не в OnCreated): GetAbility() может быть nil при создании.
function modifier_arthas_vsolyanova_active:GetModifierPreAttack_BonusDamage()
	local bonus = 0
	if IsServer() then
		bonus = AbilityKV:Get(self:GetAbility(), "bonus_damage")
	else
		-- Клиент: GetAbilityKeyValues недоступен (AbilityKV вернёт 0) — движковый
		-- GetSpecialValueFor тоже сломан. Хардкод значений из KV (bonus_damage,
		-- 7 уровней) по уровню способности — держать синхронно с hero_arthas.txt.
		local ability = self:GetAbility()
		local level = ability and ability:GetLevel() or 1
		local values = { 70, 100, 160, 220, 280, 300, 350 }
		bonus = values[level] or values[#values]
	end
	local parent = self:GetParent()
	if parent and not parent:IsNull() and parent:HasTalent("arthas_special_bonus_vsolyanova_damage") then
		bonus = bonus + 150
	end
	return bonus
end

function modifier_arthas_vsolyanova_active:GetModifierPhysicalArmorBonus()
	local parent = self:GetParent()
	if parent and not parent:IsNull() and parent:HasTalent("arthas_special_bonus_vsolyanova_armor") then
		return 30
	end
	return 0
end

if IsServer() then
	function modifier_arthas_vsolyanova_active:OnCreated()
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		self:AddParticle(pfx, false, false, -1, true, false)
	end

	function modifier_arthas_vsolyanova_active:GetModifierModelChange()
		return "models/heroes/terrorblade/demon.vmdl"
	end

	function modifier_arthas_vsolyanova_active:OnAttackLanded(keys)
		if keys.attacker ~= self:GetParent() then return end
		local attacker = keys.attacker
		local ability = self:GetAbility()
		local target = keys.target

		-- BS-хелпер GetAbilitySpecial/GetTalentSpecial не существуют в этой сборке:
		-- chance из KV через AbilityKV, талант BS заменён на HasTalent (множитель 1.1 хардкодом)
		local chance = AbilityKV:Get(ability, attacker:IsIllusion() and "nia_chance_illusions" or "nia_chance")
		if attacker:HasTalent("arthas_special_bonus_vsolyanova_chance") then
			chance = chance * 1.1
		end

		-- ⚠️ Прок ТОЛЬКО на реальных героях (игроки и боты): не крипы, не боссы,
		-- не иллюзии (IsRealHero = false). По желанию пользователя 2026-08-12.
		if target:IsRealHero() and not target:IsBoss() and RollPercentage(chance) then
			-- ⚠️ duration=0 = вечный модификатор — гард обязателен
			local duration = AbilityKV:Get(ability, "roar_duration")
			if not duration or duration <= 0 then duration = 1.0 end
			if attacker:HasTalent("arthas_special_bonus_vsolyanova_stun") then
				duration = duration + 0.5
			end

			target:EmitSound("Hero_SkeletonKing.CriticalStrike")
			local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_CUSTOMORIGIN, attacker)
			ParticleManager:SetParticleControlEnt(pfx, 1, target, PATTACH_POINT_FOLLOW, "follow_origin", target:GetAbsOrigin(), true)
			-- ⚠️ Движковый TrueKill в этой сборке молча НЕ убивает (единственное
			-- использование в проекте, проверено 2026-08-12) — паттерн BS
			-- (util/units.lua:79-90): Kill + FixedKill-страховка от блокировки смерти.
			-- Порядок аргументов КАК В ПРОЕКТЕ: (ability, attacker) — конвенция
			-- target:Kill(self, caster) (enigma:22, hand_of_midas:76, shadow_shaman:257)
			target:Kill(ability, attacker)
			if IsValidEntity(target) and target:IsAlive() then
				target:FixedKill(ability, attacker)
			end

			-- xpcall-защита: движковый хендлер маскирует ошибку (debug=nil),
			-- а xpcall с print показывает текст реальной ошибки и не ломает каст
			local pcall_ok, pcall_err = xpcall(function()
				-- аналог BS CreateGlobalParticle: частица на фонтанах всех команд
				ArthasHelpers:GlobalParticle("particles/arena/units/heroes/hero_skeletonking/alternative_vsolyanova_screen.vpcf", function(particle)
					Timers:CreateTimer(duration, function()
						ParticleManager:DestroyParticle(particle, false)
					end)
				end, PATTACH_EYES_FOLLOW)

				EmitGlobalSound("Arena.Hero_Arthas.Vsolyanova.Impact")

				-- аналог BS Notifications:TopToAll — наш клиентский пул уведомлений
				CustomGameEventManager:Send_ServerToAllClients("notifications:add", {
					token = "arthas_vsolyanova_notifiaction",
					time = duration,
					style = { color = "red", fontSize = "72px" },
				})

				local enemies = FindUnitsInRadius(attacker:GetTeamNumber(), attacker:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_ANY_ORDER, false)
				for _,v in ipairs(enemies) do
					-- ⚠️ ApplyDataDrivenModifier с движковыми модификаторами (modifier_stunned/
					-- modifier_silence) молча НЕ применяет их (нет определения в KV способности) —
					-- проект использует AddNewModifier (паттерн satan_might/hola_stunhammer)
					v:AddNewModifier(attacker, ability, "modifier_stunned", {duration=duration})
				end
				local allies = FindUnitsInRadius(attacker:GetTeamNumber(), attacker:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_ANY_ORDER, false)
				for _,v in ipairs(allies) do
					if v ~= attacker then
						v:AddNewModifier(attacker, ability, "modifier_silence", {duration=duration})
					end
				end
			end, function(e) print("[ARTHAS] proc block error: " .. tostring(e)) end)
			if not pcall_ok then
				print("[ARTHAS] proc block FAILED: " .. tostring(pcall_err))
			end

		elseif not target:IsRealHero() and not target:IsBuilding() and not target:IsCourier() then
			-- Казнь крипов/нейтралов/боссов (2026-09-02): бросок на каждую атаку.
			-- creep=1%, boss=0.1% (KV) — при пер-атак ролле 0.5-1% на боссе, живущем
			-- сотни атак, была бы гарантированная казнь в 60-90% боёв.
			-- Босс-тир = флаг IsBoss (арена/дуэль) или huge-HP (scaling-кемпы и пр.)
			local is_boss = target:IsBoss() or target:GetMaxHealth() >= 25000
			local bchance = AbilityKV:Get(ability, is_boss and "nia_chance_boss" or "nia_chance_creep")
			if not bchance or bchance <= 0 then
				bchance = is_boss and 0.1 or 1
			end
			if attacker:IsIllusion() then
				bchance = bchance * 0.25
			end

			if RollPercentage(bchance) then
				local tname = target:GetUnitName()

				target:EmitSound("Hero_SkeletonKing.CriticalStrike")
				local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_CUSTOMORIGIN, attacker)
				ParticleManager:SetParticleControlEnt(pfx, 1, target, PATTACH_POINT_FOLLOW, "follow_origin", target:GetAbsOrigin(), true)

				-- тот же рабочий паттерн убийства, что и на героях (Kill + FixedKill-страховка)
				target:Kill(ability, attacker)
				if IsValidEntity(target) and target:IsAlive() then
					target:FixedKill(ability, attacker)
				end

				if is_boss then
					xpcall(function()
						EmitGlobalSound("Arena.Hero_Arthas.Vsolyanova.Impact")
						ArthasHelpers:GlobalParticle("particles/arena/units/heroes/hero_skeletonking/alternative_vsolyanova_screen.vpcf", function(particle)
							Timers:CreateTimer(1.2, function()
								ParticleManager:DestroyParticle(particle, false)
							end)
						end, PATTACH_EYES_FOLLOW)
					end, function(e) print("[ARTHAS] boss execute FX error: " .. tostring(e)) end)
				end

				print("[ARTHAS] proc executed on " .. tostring(tname) .. (is_boss and " (BOSS)" or ""))
			end
		end
	end
end
