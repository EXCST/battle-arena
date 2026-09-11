# Досье: босс-система китайской кастомки «Новая папка (4)» (`my_game_axe` / AK)

> ⚠️ Поведенческий разбор «на атомы» (AI-ритмы/пулы, каталог всех босс-китов с таймингами, архетипы элит, мувсеты/движения, реестры чисел, KV-словарь) — см. **`docs/boss_liveliness_analysis.md`** (2026-09-09). Этот файл — архитектурный каркас.
> Разбор от 2026-08-31. Цель: понять, **как их боссы выглядят «живыми»** — от сборки юнита до AI и каст-фреймворка.
> Код НЕ копируем — это референс-исследование. Источники: `C:\Users\JimShrute\Desktop\Новая папка (4)\scripts\vscripts\`.
> Наш переносный аналог-скелет: `lib/duel_bosses/` (паттерны уже частично восстановлены отсюда в прошлой сессии).

---

## 0. TL;DR — из чего состоит «живость» (7 опор)

1. **Единый каст-стейт-машина фреймворк** (`MonsterAbility_CS`): у каждого скилла декларативный конфиг (`castPoint`, `castDuration`, `canCast`, `castAnimation`, `castColor`, хуки), а движок-коллбеки обвязаны один раз в базе.
2. **Каст-бар + окно «破招» (counter-break)**: передняя стойка показывается полосой прогресса; последние N секунд — «уязвимое окно», удар в него = короткий стан + полный катдаун + награда (постура-бар +15%). Вне окна босс дебафф-иммунен и с −80% входящего урона. Прервали законно — босс **сам себя станит на 4с**.
3. **Телеграфы как язык боя**: растущие красные линии с ре-аймом и «замком» направления, кольца с ограниченным преследованием (от них можно убежать), мигание за 25% до удара, финишный звук каста за 0.08с, цветные зарядки (castColor CP60), ScreenShake.
4. **AI-слой с характером**: взвешенный рандум-пул скиллов (вес 1000, после использования ×0.618 — «золотое затухание», босс не спамит, но предсказуем-на-глаз), pacing по КД+джиттер, фазовые скиллы приоритетнее всех; для флагманских боссов — ручные ротационные AI (дистанционные коридоры, запрет повтора, хилы по HP-порогам, ульты по стакам «heat»).
5. **Физическое поведение**: тактическая пере-позиция ПЕРЕД кастом (поиск точек назад по спирали с GridNav), повороты к цели со скоростью (`LockTargetForSpeed`), разбег/таран покадровым Mover'ом с **наказанием за столкновение со стеной** (босс врежется, глупо постоит 0.3с оттолкнётся), схватил—швыряет дугой, инерция/скольжение после удара, `collision_effect` — монстры физически расталкивают друг друга (никогда не сливаются в кашу).
6. **Фазы/постура/энрейдж**:转阶段 как отдельный тип скилла (возврат к спавну → неуязвимое «шоу» окно 6с со скрытием бара и жестом → бафф фазы 2); постура-бар в стиле Sekiro (стаггер на 8с, сокращается уроном); энрейдж <10% HP; тепловые стаки (Lina) с истощением.
7. **Восприятие и масштабирование энкаунтера**: урон босса делится на число игроков рядом (1/N), боссбар в неттэйбле с персональным показом, весь урон — `%` от атаки (`damage_rate`) через единую Damage-систему → боссы читаемы и настраиваемы таблицами (CSV → KV + rulesets).

---

## 1. Стек и зоны доступа

- **TypeScriptToLua (TSTL)** + свой `dota_ts_adapter` (`registerAbility/registerModifier` = LinkLuaModifier+preload обвязка), `lualib_bundle.lua` (TS рантайм).
- **Шифрование**: 420 из 1523 `.lua` — это `return (GameRules.XDecrypt("<AES-128-CBC hex>"))`; реализация в открытом `utils/decrypt.lua`:
  - сервер: `key = GetDedicatedServerKeyV3('99f_version1.0')` → `aeslua.decrypt` → `loadstring(plain)(...)` (расшифровка и исполнение — внутри XDecrypt);
  - клиент: заглушка с `error(...)` (ключа для клиента нет намеренно);
  - ключ — Steam-инфраструктурный (x-template + github XavierCHN/fetch-keys), **в файлах его нет → статически не вскрывается**.
- **Открыто (100% читается)**: весь слой скиллов `abilities/monster/**` (455 файлов, 0 зашифровано — включая ВСЕ киты боссов и их AI-классы!), `abilities/_base/base_ability.lua`, `abilities/system/*`, `modifiers/**` (cast-модификаторы, телеграфы, постура-бар, enrage), `utils/` (pool/timers/tween/json/aeslua), `abilities/special.lua`.
- **Зашифровано (ключевое для боссов)**: `modules/globalfunctions.lua`, `modules/attackmanager.lua`, `modules/damagemanager.lua`, `modules/debuffstatusmanager.lua`, `modules/custom_projectile_manager.lua`, `modules/monstercounterbreakmanager.lua`, `modules/attributes/attributesmanager.lua`, `enhance/cdota_basenpc.lua` (расширения юнитов: Mover, LockTargetForSpeed, MonsterDamage, GetMinDistanceUnit...), `my_game_axe/room/comp/boss.lua|monster.lua` (спавн боссов в комнатах), `my_game_axe/unitmanager.lua`, `boss_bar_manager.lua`, `magic_tower_monster_ai_controller.lua`, `secondaryheroaicontroller.lua`, `type/*` (константы), JSON-данные (`json/ak_monster.lua` и пр.).
  → Для них выполнена **реконструкция по всем открытым точкам вызова** (см. §10, §12) — интерфейсы восстановлены с высокой уверенностью; тела функций — нет.
- **Runtime-дамп** (полное вскрытие 420 файлов) технически = временный патч открытого `utils/decrypt.lua` (печатать `plain` в консоль с маркерами) + запуск карты их игры. Не проверялся: `GetDedicatedServerKeyV3` может резолвиться только у автора/их серверов (это live-service игра с своим бэкендом `server/`, `pay/`), локальный запуск может не подняться вовсе.

---

## 2. Пайплайн сборки босса (данные → юнит)

```
CSV (ak_monster.csv, ak_abilities...) 
  → scripts/npc/ak_monster.txt        // KV юнитов (автоген, читаем)
  → scripts/npc/ak_monster_abilities.txt // ability_lua + ScriptFile + AbilityValues (читаем)
  → json/ak_monster.lua, json/rulesets/{s1,s2}/... // рантайм-данные (ЗАШИФРОВАНЫ)
  → (зашифрованный) MyGameUnit/room/comp — спавн + SetLevel + выдача слотов
```

Пример юнита-босса (`monster_12004`, «Skywrath»-лайнка — фактически Tiny-кит):
```kv
"monster_12004" {
    "UnitType" "monster_boss"          // ← определяет поведение каст-фреймворка
    "BaseClass" "npc_dota_trap_ward"   // движковый BaseClass (не герой)
    "Model" "models/items/tiny/scarlet_quarry/scarlet_quarry_02.vmdl"
    "Custom_StatusHealth" "1200"       // ← статы НЕ движковые: вся атрибутика
    "Custom_AttackDamage" "25"         //   через MyGameAttribute (nettable unit_attributes)
    "Custom_StunResistance" "75"       // резисты — свои поля
    "Custom_OnAttackHealthPctDamage" "3" // автоатака=%HP цели
    "aggroRange" "3000" "leashRange" "3000" // свои KV-поля под AI
    "Ability1" "tiny_ab1" ... "Ability5" "boss_ai"  // ← ИИ = интринзик-пассивка в слоте!
    "Ability6" "red_elite"             // цветной аура-свечение элиты (GetEffectName)
    "Ability7" "collision_effect"      // расталкивание союзников тиком 0.03с
    "DropPoolId" "..." "first_drop" "..." // лут (item:вес конвеер)
}
```
- Уровни способностей (`GetLevel()>0` требует их AI) выставляет зашифрованный `unitmanager` при спавне.
- `UnitType` (`monster_boss|miniboss|elite|normal`) читается каст-фреймворком: босс = полноценный counter-break-контур; **normal — «как в ваниле»** (прерываемый каст без иммунитета), у элиты — упрощённый.
- Способности: `ability_lua`+`ScriptFile`; числа — в **Lua-константах в шапке файла скилла** (стиль проекта); `AbilityValues` в KV используются единицами (3 файла из 455); сезонные rulesets к монстрам НЕ применяются (`ShouldUseSeasonRuleset()=false` у MonsterAbility_CS).

---

## 3. Иерархия базовых классов

```
BaseAbility (adapter)
  └ BaseAbility_CS          // config-приоритеты: GetBehavior/GetCastPoint/GetCastRange/GetCooldown/
     │                      //   GetManaCost/GetCastAnimation/GetPlaybackRateOverride + CastFilterResult*→canCast
     │                      // + ability charges (Custom_AbilityCharges) + tag-система (ResolveTagNumber)
     └ MonsterAbility_CS     // ВСЕ скиллы мобов: GetMosnterAbilityConfig (sic, опечатка автора)
        │                    // + каст-стейт-машина (OnAbilityPhaseStart/OnSpellStart/OnAbilityPhaseInterrupted)
        │                    // + FinishCue, PlayFinishEffect(CP60 цвет), telegraph-обёртки
        ├ BossPhaseTransitionAbility_CS  // тип «转阶段» (§8)
        └ конкретные киты (boss_kez_1, elite_103, ...)
BaseModifier (adapter)
  └ BaseModifier_CS = WithTagRules(WithAttributes(WithEventHandler(BaseModifier)))
     │   // With* — миксины (зашифрованы, интерфейс восстановлен):
     │   //  WithAttributes: GetAttributeBonus() таблица → авто AddAttribute/Remove при Create/Destroy
     │   //  WithEventHandler: DeclareEvents{BusinessEvents.*} → авто-подписка, диспатч метода <Event>_CS(self, ev)
     │   //  CheckState() {[MODIFIER_STATE_*]=bool} — декларация состояний (движковый auto-sync)
     │   //  GetModifierConfig(){isHidden,isDebuff,isPurgable,...} — замена boilerplate Is*
     ├ MonsterModifier_CS     // + telegraph-хелперы (WarningEffect/WarningRingEffect/FindHeroesInRadius)
     └ конкретные модификаторы (каст-фреймворк, постура, эффекты скиллов)
```

### Поля `GetMosnterAbilityConfig()` (справочник)

| Поле | Что делает |
|---|---|
| `castPoint` | длительность ПРЕ-фазы (закл.стойка) — бар, иммун, телеграф |
| `castDuration` | длительность POST-фазы (лок после удара: канал/поза), >0 → `cast_controller` + SetPostureLocked |
| `behavior` | DOTA_ABILITY_BEHAVIOR_* (NO_TARGET/POINT/UNIT_TARGET/HIDDEN...) — от него AI выбирает метод каста |
| `castRange` | число или `function(location,target)` |
| `cooldown`/`manaCost`/`healthCost` | переопределение KV-значений |
| `castAnimation` + `animationPlaybackRate` | жест каста + синхрон скорости (база сама пересчитывает playback = base·castPoint/resolved) |
| `isNotMove` | nil/true — жёсткий лок команд на всё кастование; `false` — поворот разрешён (10 файлов) |
| `canCast(self,{target|point})` | **UF_SUCCESS/UF_FAIL_CUSTOM (+nil≡успех)**. Работает ТРЕЖДЫ: фильтрация в AI (перебор пула), CastFilterResult* движка (игрок/автокаст), проверки кастомных AI |
| `castError()` | строка ошибки в HUD при попытке каста (например «附近没有可释放等离子场的目标») |
| `castColor` | Vector RGB в CP60 заряд-частицы (цвет ауры蓄力 у китов; дефолт красный) |
| `castProgressBarColor` | `"blue"`×11/`"red"`×1 — маркер «контр-брейк читаем предметами» (item_0471 требует blue) |
| `counterBreakWindowDuration` | длина окна破招 в хвосте пред-каста (пер-скилл; дефолт из менеджера) |
| `castPointDamageReduction` | DR% во время пред-фазы (дефолт для боссов **80**) |
| `thunderizedCounterBreak`(+`StunDuration`,`DamageImmune`) | скилл «ломается» гром-предметами (4 скилла) |
| `OnPrePhaseMove`+`prePhaseMoveTimeout` | динамическое движение ДО закл.стойки (§7, 6 скиллов, всё у Phantom-босса) |
| `OnPhaseStart` | старт пред-фазы (телеграфы, LockTarget, заряд-частицы, станы-режимы) |
| `OnStart` | момент удара (конец castPoint) — основная логика скилла |
| `OnInterrupt` / `OnFinish` | срыв / завершение (в т.ч. по таймауту cast_controller) — уборка визуалов |

---

## 4. Каст-стейт-машина (сердце «живости»)

```
AI (или игрок) → CastAbilityNoTarget/...
   │
   ├ CastFilterResult → cfg.canCast  ← единый источник истины «можно ли сейчас»
   ▼
OnAbilityPhaseStart (движковая wind-up точка; native castPoint = cfg.castPoint)
   ├ token = DoUniqueString (все отложенные колбэки сверяют токен — защита от гонки/переподключения)
   ├ cfg.OnPrePhaseMove? → модifier_monster_cast_pre_move + ручной монитор стан/жизни каждый тик
   │      └ finishMove() → StartPhaseStartLayer + ScheduleManualSpellStart (ручной отсчёт castPoint)
   └ StartPhaseStartLayer:
       ├ GetInterruptWindowDuration(caster, unitType, castPoint, cfg.window) → point (окно破招)
       ├ + modifier_monster_cast_pre_progress  (КАСТ-БАР: stack=0..100 прогресс;
       │      transmitter {interruptWindowPct}; on client GetModifierIncomingPhysical/SpellDamageConstant
       │      с event.report_max возвращают ширины СЕГМЕНТОВ бара (красн.=окно, син.=защита) — трюк без nettable;
       │      + ScreenShake + заряд-частица hero_ability_bk (CP60=castColor))
       ├ + ScheduleFinishCue(castPoint-0.08с) → звук "AK.Monster.CastFinishCue" + частица bkb
       └ (кроме normal-монстров) + modifier_monster_cast_debuff_immune {duration=castPoint, point, DR=80%}
              DEBUFF_IMMUNE+ROOTED+DISARMED+COMMAND_RESTRICTED+NO_TURN+NO_MOTION_CONTROL, damage_reduction
              → тиком ловит момент remaining<=point → EnterCounterBreakWindow()
                → MyGameMonsterCounterBreak:EnterWindow(unit)  ← «гарцующая» фаза: окно, когда бьёшь — срыв
                (OnDestroy/создании → ClearWindow + снять modifier_monster_cast_stun)
   ▼
OnSpellStart (конец пред-фазы)
   ├ dead/stunned? → finishNow(interrupted=true)
   ├ token-валидация; CleanupPrecastVisuals
   └ cfg.OnStart()  ← реализация удара (снаряды/урон/телепорт/схват...)
       castDuration>0 → SetPostureLocked(true) + modifier_monster_cast_controller
            ( DisableTurning; COMMAND_RESTRICTED+DISARMED+NO_UNIT_COLLISION+CANNOT_BE_MOTION_CONTROLLED;
              OnDestroy → снять лок + cfg.OnFinish() )
   ▼
завершение: controller истёк → OnFinish + старт CD; либо DestroyDuration() из скилла рано.

ПУТЬ СРЫВА А: OnAbilityPhaseInterrupted (стан/силентс извне вне окна)
   → InterruptPrecastFlow: OnInterrupt+OnFinish, «сломанная» частица bkb_2b,
     самостан caster 4с (STUN через AddDeBuffStatus; НЕ для normal), StartConfiguredCooldown, Stop.
ПУТЬ СРЫВА Б: counter-break (окно破招, удар гром-атакой/предметом thunder*)
   → TryTriggerThunderizedCounterBreak(attacker): _skipNextPhaseInterrupted (нативный ивент гасится),
     OnInterrupt, уборка, DestroyDuration или OnFinish, finish FX, стан modifier_generic_stunned
     0.5с (или thunderizedCounterBreakStunDuration), полный CD,
     MyGameMonsterCounterBreak:TriggerThunderizedCounterBreak(caster)
     → событие ON_POSTURE_COUNTER_HIT → постура-бар +15% порога (§8.4).
```
Ключевые цитаты-комментарии автора (перевод): «通用施法控制…自行驱动 castPoint/castDuration 时序,不依赖原生施法前摇(避免被控制原生打断)»; «仅 castPoint 结束前 0.2s 窗口内,眩晕才算打断»; «普通怪:前摇可被人直接打断;不施加 debuff 免疫/破招窗口».

---

## 5. Телеграфы (читаемость)

`modifiers/monster/monster_warning_effects.lua` (открыт, 407 строк):

### 5.1 Линейный `warningEffectLinear(caster, ability, start, end, duration, options)`
- 2 `CreateModifierThinker`-якоря (modifier_dummy_thinker, открытый класс-пустышка) + частица `particles/range_finder_linear_{1|2}.vpcf` на стартовый thinker.
- CP2 = Vector(duration, startWidth=128, endWidth=128); CP15 = Vector(1, 1−t, 0) — **цвет зелёный→красный** по мере готовности.
- Тик 0.03с (чистый `Timers`-цикл, БЕЗ thinker-ов на юнитах): линия РАСТЁТ от старта (end thinker двигается SetAbsOrigin на `fullLength·t`), `options.follow` — старт за кастером, `getDirection()` — **ре-айм в реальном времени**, пока вектор валиден, дальше `directionLocked` (замок направления — босс «фиксирует» линию перед ударом); `getStartPosition()` — динамический старт.
- Ground-clamp (`GetGroundHeight`), FoW-игнор (`SetParticleShouldCheckFoW(false)` — видно даже в тумане), по окончании — событие `ON_MONSTER_WARNING_ENDED {caster, ability, warning_type, start/end, radius, time}` на шину MyGameEvent.

### 5.2 Кольцевой `warningEffectRing(caster, center, radius, duration, options)`
- Якорь-thinker + `particles/monster/ability_warning_ring.vpcf`; CP1=Vector(radius, 0, −speed·1.4), CP2=Vector(duration,0,0).
- Опции: `speed` (дефолт radius/duration), `getCenter()`/`follow` (движущийся центр), `viewers` — **персональные частицы через CreateParticleForPlayer** (показать телеграф только конкретным игрокам!), `isViewerActive` — динамическая отписка.
- t>0.75: синусоидальная пульсация размера (6 Гц)×0.4 + тот же зелёный→красный CP15. По концу — `ON_MONSTER_WARNING_ENDED`.
- Статистика: `WarningEffect` — 147 вызовов/108 файлов; `WarningRingEffect` — 100/91.

### 5.3 Ограниченный трекинг `EliteCreateLimitedWarningTargetTracker` (elite_showcase_utils, открыт)
- Телеграф-центр «хвостом» за целью, но **со скоростью-лимитом** (`followSpeed`, напр. 330) и лимитом времени (`followDuration`): игрок может УБЕЖАТЬ — кольцо отстаёт; `lock()` — финальная точка для блинка (elite_103: телеграф → OnStart → блинк в точку кольца).

---

## 6. AI-слой (все реализации открыты!)

### 6.1 Generic босс: `modifiers/modifier_boss_ai.lua` (класс `modifier_boss_ai_test`, вешается интринзиком `boss_ai`)
Тик 1с, порядок каждого тика:
1. гейты: есть скиллы/не мёртв/не stunned/`not IsMonsterCasting()`;
2. цель = `GetMinDistanceUnit(3000)` (ближайший игрок; НЕ рандом);
3. ** фаза приоритет**: каждый тик пробуем `TryCastPhaseTransitionSkill` (HP≤порог → каст转阶段; вне greed_cave сессий); кастнули — `count = CD + rand(−1..3)` и выход;
4. `count−−`; count>0 — пропуск (это «тайминг-дышалка»: после каста ставится `cd + rand(1..2) + cd·rand(0.05..0.15)`);
5. нет цели → `count = rand(1..4)` (ждёт);
6. **пул**: `skill:random()` (взвешенный), проверка `CanCastSkill` (валидность хэндла pcall'ом, CD, `GetEffectiveCastRange` против цели — фолбэк 1500, cfg.canCast), НЕ прошло → **до 5 перевыборов**, после каждого — `SubSkillWeight: w = max(1, floor(w·0.618))`;
7. каст по behavior: POINT→`CastAbilityOnPosition(цель)`, UNIT_TARGET→`CastAbilityOnTarget(цель)`, иначе NoTarget — **прямые методы** (не ExecuteOrder — та же грабля, что у нас).
Противоположности в API: `RandomPool` (открыт, utils/pool.lua): add/remove/setWeightPrize/random/randomSole/randomCard с виртуальными весами ×10000.
Заметки: «защита от повтора» = 0.618 — та же идея, что `WEIGHT_POINTS=30/(1+picks)` в наших augments, но экспоненциальная.

### 6.2 Brewmaster: тот же цикл + `TryCastPrioritySkill` — приоритетная способность `boss_brewmaster_1` пробУется КАЖДЫЙ тик до пула (бафф-хил «醇酒壮胆» не должен ждать очереди).

### 6.3 Lina Soul: ручная Р Otация-дизайнер (0.25с тик, `nextActionTime` гейт)
```
CanThink: стун/силент/IsMonsterCasting/exhaust/reheat-щит/fireball-marking/pause — блок
1. TryCastThresholdHeal: хил-способность с OWN HP-порогами (60%/30%), каждый порог ОДИН РАЗ за бой (HasAvailableThreshold/ConsumeAvailableThreshold — методы способности)
2. TryCastStar: ульт «Звезда» при heat=5/5 стаков (стаки растят от кастов, +5% dmg/стак, спад через 6с; истощение после ульты)
3. TryCastSmallSkill: SMALL_SKILL_RULES — коридоры дистанций:
   soul_1/2: 0..1800, soul_4: 0..650 (мили), soul_5: 450..1800 (кирк-зона)
   → кандидаты = коридор∩готовность; >1 → ИСКЛЮЧИТЬ последний использованный (анти-повтор); random
после каста: nextActionTime = now + castPoint + castDuration + 1.25s (ACTION_GAP — «взмах-пауза»)
```
Это эталон «босс с паттерном»: файтер-ротация, а не мешок скиллов. (Такие же ручные AI: `boss_rubick_environment_ai`, зашифрованный `magic_tower_monster_ai_controller`.)

### 6.4 Обычные мобы: `monster_ai_wander` (интринзик `monster_ai_wander`)
Тик 1с: каст-интервалы 6..12с (только готовые+по радиусу+canCast, 0.1с задержка после Stop(), NoTarget-всегда), между кастами — **wander**: точка в радиусе 500..1200 от ближайшего героя, leash 1300 (выброс за leash → возврат «на привязи»); ExecuteOrderFromTable MOVE (для них Orders нормальны — это НЕ боссы-нейтралы, у них свои правила). Гейты: stun/channel/silence.
### 6.5 Элита: `modifier_elite_ai` — упрощённый: тик 1с, ready-фильтр (CD+range), random из готовых, каст по behavior.
### 6.6 Атака-таргетинг: `modifier_monster_attack_target_sync` — тик 0.25с: `GetAttackTarget() or GetAggroTarget()` (агро = threat-система в зашифрованном menedzhere; у normal-мобов KV `aggroRange/leashRange`), валидация враждебности, фолбэк `GetMinDistanceUnit(3500)`, смена цели → явный `DOTA_UNIT_ORDER_ATTACK_TARGET` (иначе мобы «залипают» на мёртвом).
### 6.7 Отладка: глобальный тумблер `_G.__debug_monster_ai_enabled__ = false` глушит все AI-тики (readme-style debug).

---

## 7. Физика «живости» (расширения юнитов; реализации в зашифрованном enhance/cdota_basenpc.lua, интерфейсы реконструированы по 200+ вызовам)

| API | Семантика (уверенность high, см. §10) |
|---|---|
| `unit:Mover(point, time, onTick?, ?, ?)` | покадровый линейный транспорт SetOrigin; onTick(pos, elapsed) → `true` = стоп; флаги 4/5 = (ignore navmesh?/face?) |
| `unit:Bezier2Mover({p0,p1,p2}, time, cb?,...)`, `CircleMover`, `StartLightweightMover` | дуга/орбита |
| `unit:KnockBack(caster, ability, {duration, distance, height, direction, heightType="parabola", destroyTreesType, removeOnDeath})` | унифицированный откидыватель (дуга, снос деревьев) |
| `unit:LockTargetForSpeed(target, duration[, turnSpeed])` | плавный доворот «лицом» на время (скорость deg-шаг; без = статы) — 207 файлов |
| `unit:SetForwardVectorWithoutInterrupt(v)` | разворот без сброса канала/атаки |
| `unit:GetMinDistanceUnit(range[, center])` | ближайший ВРАГ (фильтр команды), точка отсчёта опциональна |
| `unit:GetAggroTarget()` / threat | агро из damage-manager (кто сколько ударил) |
| `unit:IsMonsterCasting()` | флаг фреймворка (есть cast_pre_progress/controller) — AI не лезет |
| `unit:GetSpawnPoint()` | «домой» (леash/转阶段 возврат) |
| `unit:SetPostureLocked(bool)` / `IsPostureLocked` | поза/лок набора постуры |
| `unit:SetCustomValue(key,val)` / Get | per-unit хранилище → nettable `custom_value` (синк счётчиков в HUD, ключи на китайском: «绝影斩击» = комбо-счётчик) |
| `unit:MonsterDamage({victim,damage_rate,ability?,damage_type?,effectName?,attack_damage_override?,expected_damage_health_pct?})` | урон монстра: `damage_rate` = % от ИТОГОВОЙ атаки кастера (MyGameAttribute total_attack_damage) |
| `unit:GetIdealSpeed()` |desired move speed; `unit:SetAnimation(name)` — activity-секвенция модели |
| `AddDeBuffStatus(nil, victim, caster, ability, DebuffStatusType.*, {duration, stack, effect_name, status_effect_name, merge_by_ability, pool_damage, source_final_damage})` | единый дебафф-каталог: STUN/POISON/ICE_SLOW/BURN/BLEED/VULNERABLE (реализация менеджера зашифрована — тип-реестр в type/debuff_status.lua) |
| `CreateProjectile(nil, {...})` | свой снаряд-менеджер: типы `linear`/`tracking`/`collideground`, **on_hit return true = снаряд гаснет, false = летит дальше** (pierce через hit-history в extra_data!), fields: speed/distance/range(ширина)/end_range(конус)/direction/break_destructibles(сносит деревья)/enable_projectile_count_bonus/extra_data/on_think |
| `SafelyCall/CheckTag/GetDistance/GetDirection(a→b нормаль)/IsValidAlive/RotateVector2D/GetRotateVectors(base,count,angle)` | глобал-утилиты (globalfunctions, зашифрован; сигнатуры 100% по callsites) |
| `SlowDownServerRate(nil, 0.3, 0.2)` | server slow-mo на 0.2с с timescale 0.3 (драма! — на сломай постуру) |
| `ScreenShake(pos, a, b, dur, radius, dir, bool)` / `EmitSoundOnLocationWithCaster` | обёртки движка |
| `MyGameUnit:CreateSummonedUnitAsync({unitName, position, team, owner, summoner, summonTag, maxSummons, destroyWithSummoner, findClearSpace, roomId, onSpawn, onDeath, replaceOldestWhenFull})` | пул саммон с лимитом по тегу (зашифрован) |

**Тактическая пере-позиция (phantome_ab1, «OnPrePhaseMove»)** — образец: до закл.стойки босс ОТХОДИ от цели на ~500 (до потолка дистанции 1200): спиро-поиск кандидатов (4 дистанции × 11 углов), валидация: дальность выросла, ≤макс, `GridNav:IsTraversable/IsBlocked/CanFindPath`; жест RUN×1.35, `Mover` с arrival-колбэком + timeout-гард; отмена по стану; при недостижимости — каст с места.
**Таран-наказание (boss_beast_5)**: разгон 130 ед/фрейм по forward с `GridNav:DestroyTreesAroundPoint(400)`; врезался в блок → `modifier_stunned` 0.3с + Mover назад на 250 (босс «тупой и виноватый» — комедийность = жизнь); задел цель → схват → серию slam-ов по дуге «руки» (радиус 250, подъём 45°, высота-синус, покадровый SetAbsOrigin жертвы), инерционный dosкол bосса после серии (eased), каждый шлём — 35% AD урон в 500 + стан 1с; всё на таймерах с токенами и null-guard.
**boss_002 (Skywrath)** — комбо-цепочка в одном касте: канал с RE-АЙМ телеграфом (getDirection=forward) → снаряд-волна (piercing on_hit=false) + отдача Mover назад → через 0.5с поиск ближайшего в конусе 60° → dash-телепорт к нему (кольцо-телеграф на время дэша) → если в точке ровно 1 жертва: захват (визуал arcana) → жертва ВИСИТ над головой босса (тик 1.5с пере-позиционирование + тик-урон 20%), босс с винной-анимацией → смерть захвата: KnockBack параболой + ScreenShake.
**collision_effect** (интринзик у юнитов): тик 0.03с — расталкивать союзников/цели в 100 на 5 юнитов (+FindClearSpace) — стаи не слипаются, в мили-комбо врагов «разносит».

---

## 8. Фазы, постура, энрейдж

### 8.1 转阶段 — `BossPhaseTransitionAbility_CS` (открыт)
- Помеченные скиллы AI separate-массивом `phaseTransitionSkills`; `CanTriggerBossPhaseTransition = не срабатывал && HP% ≤ GetBossPhaseTransitionHealthThresholdPct()` (дефолт **60**).
- `StartBossPhaseTransition`: mark triggered → `SetBossPhaseTransitionState(TRANSITIONING)` → **Mover домой за 0.8с** → через delay: окно `modifier_boss_phase_transition_window` {duration=6с}: INVULN+STUN+ROOT+DISARM+COMMAND_RESTRICTED+NO_HEALTH_BAR + **скрытие боссбара** (MyGameBossBarManager.bossBar[ent]=nil + SyncNetTabel; restore в OnDestroy) + зацикленный ACT-жест с playback rate.
- Параллельно `OnStart` наследника (напр. `boss_simple_phase_summon`): через 0.65с — круг саммонов (5 шт, радиус 620, пул по тегу, ACT_DOTA_SPAWN×0.8, loop FX+звук каждые 1.5с в центр), в `OnFinish` — `SetBossPhaseTransitionState(AFTER)` (скиллы кита считывают состояние и меняются; чтение — в зашифрованной базе) + авто-бафф `phase_two_buff`: +10% исходящего, +10% входящего DR, +20% MS, +20 AS.
- Геттеры для тюнинга наследником: порог %, длительности, жест, отключение дефолтных окна/баффа.

### 8.2 Энрейдж: `modifier_cs_boss_low_health_enrage` (открыт): HP<10% → +10% all attack dmg, +10% DR (тик-скан 0.1с, RefreshAttributes по изменению).

### 8.3 Heat/Exhaust (Lina): stacks 5 (+5% dmg each), decay −1 за 6с не-каста, at max — ульт «Звезда»; после — exhaust: silence+disarm+−30% MS+−15% DR, AI-блок по списку модификаторов (CanThink).

### 8.4 Постура-бар (открыт: modifier_cs_posture_bar + PostureBarRules) — «Sekiro»
- StackCount = позад (0..threshold 100). **Набор**: за каждый % макс.HP урона +1×multiplier (мультипликатор = 1/число игроков рядом в 2500 — в мультиплеере barre растёт медленнее на персону); **стан-накопление**: пока цель в нативном стане, +2 каждые 0.03с (!) — контроль приближает стан-лок; **контр-хит**: событие `ON_POSTURE_COUNTER_HIT` (破招) → +15% порога; **разложение**: −3% порога за полностью прокастованный скилл; decay 0/сек.
- **СTAGGER** при 100: `modifier_generic_stunned` 8с + `SlowDownServerRate(0.3,0.2)` + звук «Sounds.Ability.Broken» + стекло-частица; **сокращение стан-лока уроном**: −1с за каждые 5% HP урона (punish window!); стек во время stagger = обратный отсчёт (визуал урона). `IsPostureLocked` — скилл-флаг immune к набору.
- Клиент (React-панель, minified JS — имя переменной `posturePhase: broken|normal`): бар из StackCount мода + нелинейный HP ((hp/hpmax·100)^1.3/3.981) + shield/nuqi/posture/fennu(debuffs) из неттэйбла `boss_bar` + entity-полей; фильтр PlayerIDs (персональные фазы-лорды), максимум 2 бара на экран, `.broken` класс + звон стекла.
- Неттэйблы: `boss_bar` (`show_bars`), `unit_attributes`, `custom_value`, `unit_custom_value_sync` (custom_net_tables.txt).

---

## 9. Боссбар и «перцепция» (неттэйбл `boss_bar`)
Сервер (зашифрован) пишет: `MyGameBossBarManager.bossBar[tostring(entindex)] = {BossID, PlayerIDs}` + SyncNetTabel() → клиент React hud. Открытые точки интеграции: HideBossBar/Restore в 转阶段 (модификатор окна), tiny_ab1 (рост босса). Поля клиента — см. §8.4.

---

## 10. Реконструкция зашифрованного: статус и уверенность

| Подсистема | Реконструировано | Уверенность |
|---|---|---|
| enhance/cdota_basenpc (Mover, KnockBack, LockTargetForSpeed, MonsterDamage, GetMinDistanceUnit, IsMonsterCasting, GetSpawnPoint/RoomId, SetCustomValue, Set/GetBossPhaseTransitionState, SetForwardVectorWithoutInterrupt, GetAggroTarget, SetPostureLocked, GetIdealSpeed, HasAvailableThreshold*) | сигнатуры+семантика по 200+ callsites (H1) | high (все, кроме флагов Mover 4/5 — low) |
| custom_projectile_manager | полный формат CreateProjectile (3 типа, on_hit true/false!, extra_data, on_think, break_destructibles, end_range) (H1+H2) | high |
| debuffstatusmanager + type/debuff_status | 6 типов дебаффов, поля params, merge_by_ability, pool_damage (H1) | high |
| attributesmanager | полный алфавит ~90 атрибутов, GetAttribute/HasAttributes/AddAttribute(+source op)/RemoveAttribute/RunAttributeBatch/реген-хендлер; статы = скрытый модификатор `_base_attribute` (transmitter) + nettable unit_attributes (H2) | high |
| monstercounterbreakmanager | интерфейс: GetInterruptWindowDuration (дефолт-кривая не видна), Enter/ClearWindow, TriggerThunderizedCounterBreak → ON_POSTURE_COUNTER_HIT (из открытых cast-модификаторов + item_thunder_grass) | medium (дефолтные окна по юнит-типам — оценка) |
| eventmanager (MyGameEvent/BusinessEvents) | 40+ имён событий, scope {entity/global}, приоритеты, диспатч `<Event>_CS` в модификаторах (H2) | high (интерфейс), medium (дефолты) |
| damagemanager | ApplyMonsterDamage: rate→% атаки, damage_type 1=phys 2=mag (4=pure?) (H1) | medium (формулы MR/armor — тёмные) |
| attackmanager | системные passive-пустышки monster_melee_special_attack / monster_linear_projectile_attack: хуки на автоатаку юнита спавнят снаряды/удары из KV-полей; internals = тёмные | low-medium |
| room/comp/monster.lua, boss.lua | ECS-компоненты комнаты: спавн из data, привязка roomId/агро, босс-триггеры, лут, рес | low (поведенчески) |
| unitmanager | CreateSummonedUnitAsync/DestroyUnit/CreateUnitAsync (поля H2) | high (API) |
| boss_bar_manager | формат записей + SyncNetTabel (H2 из окна + клиента) | medium |
| magic_tower_monster_ai_controller (25KB), secondaryheroaicontroller (54KB) | только существование (другие режимы мобов/союзников-героев) | — не восстановимо без дампа |
| globalfunctions | сигнатуры (H1) | high |
| type/*.lua (UnitType, DebuffStatusType, BossPhaseTransitionState, BusinessEvents...) | значения видны по callsites (BossPhaseTransitionState: TRANSITIONING/AFTER observed; BEFORE — inference) | medium |

---

## 11. Статистика приёмов по 455 открытым скиллам мобов

elite 185, normal 58, boss-киты ~170 (25 наборов), common 13, roshan 5, totem 5.
canCast — 82 (79 файлов) · WarningEffect — 147 (108) · WarningRing — 100 (91) · LockTargetForSpeed — 251 (207) · StartGestureWithPlaybackRate — 206 (141) · Mover — 178 (114) · ScreenShake — 216 (131) · animationPlaybackRate — 124 (123) · SetAnimation — 119 (62) · EmitSoundOn — 357 (190) · Bezier — 33 (26) · SetCustomValue — 26 (15) · OnPrePhaseMove — 11 (7) · castProgressBarColor — 12 · castColor — 21 · thunderizedCounterBreak — 4.
damage_rate диапазон: 1.5..40 (% атаки). Топ-навороченные: elite_103, tide_hunter_ab5, boss_abyssal_3 (10/9 приёмов из чарта).

---

## 12. Сравнение с нашим battlearena (для понимания, без портирования)

| Их приём | Наш эквивалент | Статус у нас |
|---|---|---|
| ИИ как intrinsic-модификатор слота | `boss_ai`-паттерн/GetIntrinsicModifierName | ✅ та же архитектура |
| Взвешенный пул + анти-повтор | AIController правила с приоритетом + Augments DrawWeighted (30/(1+picks)) | ◐ ideas те, у боссов — детермин. приоритеты, не рандом |
| Телеграфы линейные/кольцевые + ре-айм | `lib/duel_bosses/boss_warning.lua` (тот же range_finder/ability_warning_ring!) | ✅ уже перенесено (08-31) |
| «Окно破招» + self-stun 4с при прерыве | `modifier_duel_boss_cast_protection` (−80% DR + само-стан 4с) | ◐ есть ядро, НЕТ окна (последние N сек) и кастбара |
| Каст-бар (стек-прогресс + report_max сегменты) + finish cue звук | — | ❌ нет |
| Постура/стан-лок (Sekiro) | — | ❌ нет |
| 转阶段: возврат к спавну + invuln-окно + скрытие HP-бара + бафф фазы | travaler phases (кламп HP+purge+invuln 1.5с) | ◐ похожее, без «шоу-окна» и без bar-hide |
| Дистанционные коридоры скиллов (AI-ротации) | — | ❌ (правила только по порогам HP/кулдаунов) |
| Тактический отход/подход ДО каста (OnPrePhaseMove + спиро-поиск) | — | ❌ |
| Tаран с наказанием за стену; схват-slam-дуга; вис-захват | boss_motion (Mover/Bezier/KnockBack — восстановлены оттуда же) | ◐ механики есть в duel_bosses, «провал/наказание» — нет |
| Расталкивание мобов (collision_effect) | — | ❌ |
| 1/N урона по nearby players | — | ❌ |
| CSV→KV data-driven (юниты, киты) | npc_units_custom + augments catalog | ◐ формат у нас KV-ручной |

Что они НЕ используют (наш плюс): у нас `AbilityKV:Get` обход сломанного GetSpecialValueFor; у них родной GetSpecialValueFor на KV-мобов тоже работает (AbilityValues у unit KV — только 3 скилла, им не пользовались — у них каст-значения в Lua).

---

## 13. Карта файлов (куда смотреть при уточнении)

> Полный каталог китов/элит/таймингов с картой файлов — `docs/boss_liveliness_analysis.md` §6-§11.

- Каст-машинa: `abilities/monster/monster_base.lua` (701 л.) + `modifiers/monster/monster_cast_modifiers.lua` (373 л.)
- Телеграфы: `modifiers/monster/monster_warning_effects.lua` + `abilities/monster/elite/elite_showcase_utils.lua`
- AI: `modifiers/modifier_boss_ai.lua`, `abilities/monster/_monster_ai.lua`, `abilities/monster/boss/_boss_ai.lua`, `abilities/monster/boss_brewmaster/boss_brewmaster_ai.lua`, `abilities/monster/boss_lina_soul/boss_lina_soul_ai.lua` (+shared), `modifiers/modifier_elite_ai.lua`, `modifiers/monster/modifier_monster_attack_target_sync.lua`, `utils/pool.lua`
- Фазы/постура/энрейдж: `abilities/monster/boss/boss_phase_transition_ability.lua`, `.../boss_simple_phase_summon.lua`, `modifiers/state/posturebarrules.lua`, `modifiers/state/modifier_cs_posture_bar.lua`, `modifiers/state/modifier_cs_boss_low_health_enrage.lua`, `utils/boss_encounter_scaling.lua`
- Демонстрации скиллов: `boss_kez/boss_kez_1.lua` (pull-канал), `elite/elite_103.lua` (tracker+blink+counter-break), `boss_phantom/phantome_ab1.lua` (pre-phase отход+веер снарядов), `boss_beast/boss_beast_5.lua` (таран/схват/slam), `boss/boss_002.lua` (полная комбо-цепочка с захватом), `boss/boss_003,004` (canCast-условия)
- Базы/пайплайн: `abilities/_base/base_ability.lua`, `modifiers/class/modifier_base.lua`, `modifiers/monster/monster_modifier_cs.lua`, `abilities/special.lua`, `scripts/npc/ak_monster.txt` (юниты), `scripts/npc/ak_monster_abilities.txt` (KV скиллов), `scripts/custom_net_tables.txt`
- Шифровка бутстрап: `utils/decrypt.lua` (открыт!), `utils/aeslua/*` (AES-CBC библиотека открыта)

## 14. Что осталось «за завесой» (нужен runtime-дамп, если вскрывать)
Формулы damagemanager/armor и дефолт-кривые windows, internals attackmanager (автоатака-проки), room/comp-спавн боссов (Init, боссбар-создание, SetLevel), threat-агро (GetAggroTarget источник), magic tower AI (25KB) и secondary hero AI (54KB), body `RandomPool`-использований вне пула скиллов, ruleset-зависимые числа (json/ak_monster*.lua), `modifier_generic_stunned` internals — ок, это открыто.
Возможный путь (НЕ выполнен, требует согласия): патч открытого `utils/decrypt.lua` (dump `plain` chunks в console через `print`) + запуск `dota_launch_custom_game <их аддон> s1-2`; если `GetDedicatedServerKeyV3` не резолвится без авторского ключа — игра не поднимется и статическое вскрытие невозможно.
