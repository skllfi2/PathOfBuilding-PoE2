# PoB2Fork — Current State

Дата зафиксированного состояния: 2026-11-12.
- **D-050 (2026-11-12): Тултипы, фикс `WrapString`, `CalcBreakdownRU`, `ConfigTooltipsRU` и автоматизация аудита:**
  - **Main.lua & Tooltip.lua:** `main:WrapString` теперь переносит до переполняющего слова и учитывает шрифт `fontToUse` (`self.maxWidth - H_PAD - 4`), устранив выход текста за границы 450 px карточек Side-by-Side; в `Options` добавлен чекбокс `logUntranslatedRU`.
  - **UITranslationsRU.lua:** исправлен multiline `gmatch` (убрано наложение в `PartyTab`), добавлены 45+ тултипов `Options`/вкладок, предупреждения `BuildDisplayStats`, `Active Skill #N`, `Скор. передв. навыка`.
  - **CalcBreakdownRU.lua & ConfigTooltipsRU.lua (новые) + CalcBreakdownControl.lua:** системный перевод детализаций `Calcs` (~170+ пояснений, таблицы AoE/EHP/уклонения/состояний, `localizeCellValue` для `ItemNamesRU`/`GemNamesRU`) и >260 динамических подсказок `Config`.
  - **GemTooltip.lua / SkillsTab.lua / SkillDescriptionsRU.lua / ModTranslationsRU.lua:** фикс отступа `iconTagIndent`, теги `Sustained`/`Storm`, опечатка в `Грозе`, имена камней в `AddSocketGroupTooltip`, `Deals X to Y <Type> Damage`.
  - **Автоаудит (`scratch/`):** `ast_audit_ru.py` (3 307 выражений) и `headless_audit_ru.lua` (обход всех 9 вкладок, `tooltipFunc` и `player.breakdown` в `host.exe`; пропуски снижены с 484 до 83).
  - **Верификация (`host.exe`, из `src/`):** `verify_tooltips_ru.lua` **26/26**, `verify_final_all.lua` **SYNTAX 16/16 OK**, **TREE_COVERAGE 4482/4496 (99.69%)**, `verify_5_screenshots.lua` **44/44**. Бэкапы: `Snapshots/PoB2-Tooltips-20261112/`.
- **D-049 (2026-11-12): Разделение `uiLanguage`/`itemLanguage`, скролл в Options, правки NotesTab/ItemListControl и снятие ограничения `#ruStats == #node.sd`:**
  - **Main.lua:** независимая настройка `main.uiLanguage = "RU"` (в `Settings.xml` и Options), вертикальный скроллбар в окне `Options` (`useScrollBar = true`), `self.logUntranslatedRU = false` по умолчанию.
  - **PassiveTreeView.lua:** снято жёсткое сравнение `#ruStats == #node.sd`, добавлен вывод `extraRuLines` при `i == #node.sd and #ruStats > #node.sd`.
  - **NotesTab.lua / ItemListControl.lua:** подсказка в `NotesTab` разбита на 3 `LabelControl` без наложения на кнопки; в `ItemListControl` статусы `(Не используется)` / `(В наборе '...')` привязаны к `uiLanguage`, а имена предметов — к `itemLanguage`.
  - **Верификация (`host.exe`, из `src/`):** `verify_final_all.lua` — **SYNTAX 16/16 OK**, **TREE_COVERAGE 4482/4496 (99.69%)**; `verify_lang_split.lua` — **PASS**; `verify_4_screenshots.lua` — **11/11 PASS**; `verify_5_screenshots.lua` — **44/44 PASS**.
- **D-048 (2026-11-12): Runtime Miss Logger + системные фиксы UITranslationsRU:Get() (ТЗ TZ_OpenCode_Runtime_Miss_Logger.md):**
  - **UITranslationsRU.lua fixes:** Убраны лишние квадратные скобки из значений (`[PoE2]`→`PoE2`, `[Maxroll]`→`Maxroll`, `[Control]`→`Control` и др.); добавлен построчный fallback для `\n`-строк в `Get()`; добавлен `Label: Value` fallback (перевод левой части и правой части отдельно).
  - **RULogger.lua (новый модуль):** `src/Modules/RULogger.lua` — логирует непереведённые строки из живого UI с дедупликацией, фильтрами технических токенов, записью в `untranslated_live.log` с флешем каждые 2 сек.
  - **Интеграция:** `Main.lua` — `translateForRender` логирует промахи (источник "UI"); `Tooltip.lua:AddLine` — источник "TOOLTIP"; `ModTranslationsRU:Translate` — источник "MOD"; `PassiveTreeView.lua` — источник "TREE".
  - **verify_runtime_logger.lua:** **13/13 PASS** (multiline, Label:Value, EN passthrough, safety).
  - **Регрессия:** `verify_dialogs.lua` **58/58**, `verify_5_screenshots.lua` **44/44**, `verify_tree100_ru.lua` **29/29**, `calcs_check.lua` **ALL PASS**, `batch13` **34/34**, `batch14` **43/43**, `batch15` **70/70**, `test_stat_describer_e2e.lua` **PASS**.
  - **Бэкапы:** `backup_ui_fix/20261112-113531-runtime-miss-logger/`.

- **D-047 (2026-11-12): Полный перевод 1 005 строк интерфейса (ТЗ TZ_OpenCode_Remaining_UI_100pct.md):**
  - **ui_to_translate_clean.json:** все 1 005 записей заполнены (0 пустых "ru": ""), цветовые теги (^7, ^8, ^x...), \n, \t и плейсхолдеры (%d, %s, {0}) сохранены.
  - **UITranslationsRU.lua:** +1 005 записей в self.map (append-only, без перезаписи существующих компактных переводов). 494 новых ключей добавлено.
  - **Верификация (host.exe):** verify_ui_1005.lua — TOTAL=1005, TRANSLATED=1005, UNTRANSLATED=0 (100.0% >= 98% порог).
  - **Бэкапы:** backup_ui_fix/20261112-110548-ui-1005/.

- **D-046 (2026-11-12): Полный аудит и локализация всех диалоговых окон и UI (ТЗ TZ_OpenCode_Full_Dialogs_and_UI_Sweep.md):**
  - **Python-сканер:** `scratch/audit_ui_dialogs.py` + `scratch/audit_ui_dialogs_host.lua` — сканирует все .lua в `src/Classes/` + `src/Modules/` (Export/ исключён), находит вызовы `OpenPopup`/`OpenConfirmPopup`/`OpenMessagePopup`/`PopupDialog`, атрибуты контролов `label`/`tooltip`/`prompt`/`placeholder`, `tooltip:AddLine`, разделяя на статические и динамические строки.
  - **Аудит ДО (host.exe):** `scratch/audit_ui_dialogs_before.txt` — TOTAL=2400, TRANSLATED=1725, UNTRANSLATED=675.
  - **UITranslationsRU.lua:** добавлено ~70 новых статических переводов (заголовки диалогов, кнопки, надписи контролов, подтверждения удаления) + динамические паттерны `Get()` для ошибок файловых операций, подтверждений удаления, импорта/экспорта, Class Change.
  - **Экранирование % в gsub:** все подставляемые аргументы экранируются через `val:gsub("%%", "%%%%")`; `|` не используется в Lua-паттернах.
  - **Main.lua `OpenMessagePopup`:** кнопка "Ok" использует динамическую ширину через `DrawStringWidth`.
  - **Аудит ПОСЛЕ (host.exe):** `scratch/audit_ui_dialogs_after.txt` — TOTAL=2400, TRANSLATED=1772, UNTRANSLATED=628 (+47 переводов).
  - **verify_dialogs.lua:** **58/58 PASS**. Регрессия: `calcs_check.lua` **ALL PASS**, `batch13` **34/34**, `batch14` **43/43**, `batch15` **70/70**, `verify_tree100_ru.lua` **29/29**, `verify_5_screenshots.lua` **44/44**, `test_stat_describer_e2e.lua` **PASS**.
  - **Бэкапы:** `backup_ui_fix/20261112-095210-ui-dialogs-sweep/`.

- **D-045 (2026-11-12): 100% локализация дерева пассивных умений PoE2:**
  - **Новый модуль:** `src/Data/TreePassivesRU.lua` (17 чанков, 4914 skill с RU-статами, 46 с флейвор-текстом), сгенерирован `scratch/build_tree_passives_ru.lua` через `host.exe` + `StatDescriptionsRU` (per-stat lookup). Методы `GetStats(node)` / `GetFlavour(node)`.
  - **Обновлён `src/Data/StatDescriptionsRU.lua`:** 374 scopes, 6 697 описателей (добавлен `passive_skill_variant_stat_descriptions.json` + отфильтрованный `stat_descriptions.json` по tree stat_ids). Чанки по 150 (LuaJIT лимит).
  - **Обновлён `src/Data/TreeNodesRU.lua`:** trimmed-поиск в `Get()` (по `self.byName[name]` + `self.byName[name:match("^%s*(.-)%s*$")]`). 24 новых имени из Default.json/characters.json/ascendancies.json. 16 имён без RU в GGPK как явные исключения. Покрытие: 2027/2027 (100%).
  - **Обновлён `src/Classes/PassiveTreeView.lua`:** загрузка `TreePassivesRU` через `pcall`; в `addModInfoToTooltip` фолбек на `TreePassivesRU:GetStats(node)`; флейвор из `TreePassivesRU:GetFlavour(node)`; поиск по дереву проверяет RU строки статов.
  - **Верификация (`host.exe`):** `verify_tree100_ru.lua` **29/29 PASS** (имена 100.00%, статы узлов 98.71%, ключевые ноды, RU поиск); `verify_5_screenshots.lua` **44/44 PASS**; `batch13` **34/34**, `batch14` **43/43**, `batch15` **70/70**, `calcs_check.lua` **ALL PASS**, `test_stat_describer_e2e.lua` **PASS**.
  - **Бэкапы:** `backup_ui_fix/20261112-120000-tree100/`.

- **D-044 (2026-11-12): Доработка дефектов по 5 пользовательским скриншотам (GemTooltip, Skills, Config QuestRewards, Tree Tooltips, ItemTooltip Mods):**
  - **GemTooltip / `StatDescriptionsRU.lua` (`scratch/generate_stat_descriptions_ru.py`, `src/Data/StatDescriptionsRU.lua`, `src/Classes/GemTooltip.lua`, `src/Data/UITranslationsRU.lua`):**
    - Удалён разделитель столбцов GGPK `@` → `": "` и добавлен поиск `specific_skill_stat_descriptions/<scope>` (исправлены все статы *Стены щитов / Shield Wall*).
    - В `GemTooltip.lua`: добавлена таблица `GEM_TAGS_RU` (`AoE, Melee, Physical, Duration` → `Область, Ближний бой, Физ., Длительность` и др.), локализован суффикс `(Not supported in PoB yet)` → `(Пока не поддерживается в PoB)`, в режиме `DUAL` подзаголовок переведён в `^8(enTitle)` без дублирования русского названия.
    - В `UITranslationsRU.lua` убран дубль знака `%` в шаблонах `Attack Damage` / `Attack Speed` (`619% от базового` вместо `619%% от базового`).
  - **Вкладка «Умения» и сайдбар (`src/Classes/SkillsTab.lua`, `src/Classes/SkillListControl.lua`, `src/Data/UITranslationsRU.lua`):**
    - В `UITranslationsRU:Get()` добавлен динамический шаблон `^Main Skill:%s*(.*)$` (`Осн. умение: Набор 1/2 | Оба | Нет`).
    - Переведён многострочный блок `Usage Tips:` → `Подсказки:`, отступ секции «Параметры камней» увеличен (`optionInputsY = 45 → 64`) для устранения наложения текста, метки «Камни поддержки:» / «Устаревшие камни:» укорочены, в `SkillListControl.lua` `(FullDPS)` → `(Полн.DPS)` в RU/DUAL.
  - **Config — Награды за квесты (`src/Data/UITranslationsRU.lua`):**
    - Исправлены опечатки в названиях квестов (`Act 3: Jiquani's Machinarium`, `Act 4: Eye of Hinekora`, `Interlude 2: Khari Crossing`) и добавлен `Interlude 3: Kriar Village` + все остальные области из `QuestRewards.lua`.
    - Добавлены все переводы опций наград за квесты (как полных многострочных строк с `\n\t`, так и отдельных строк для тултипов) и `Nothing` → `Нет`.
  - **Дерево умений и моды предметов (`src/Classes/Tooltip.lua`, `src/Data/UITranslationsRU.lua`, `src/Data/ModTranslationsRU.lua`):**
    - В `Tooltip.lua` названия Distilled Emotions (`self.recipe`) переводятся через `UITranslationsRU:Get()` до расчёта ширины (`Despair` → `Отчаяние`, `Paranoia` → `Паранойя` и др., все 14 эмоций).
    - В `ModTranslationsRU.lua`: добавлена обработка префикса `Bonded:` → `Узы:`, шаблоны `increased Electrocute Buildup against Shocked Enemies`, `increased Shock Chance against Electrocuted Enemies`, `reduced Effect of Non-Damaging Ailments on you`, все 9 вариантов `Can roll ... modifiers` + fallback-правило, правило для `Damaging Ailments deal damage <N>% faster` и экранирование `%%` в подстановке `specialRules` (`%1`/`%2`).
  - **Верификация в `host.exe` после финальных правок:** `scratch/verify_5_screenshots.lua` — **44 PASS, 0 FAIL** (включая синтаксис 7/7 модулей и `StatDescriber` для `shield_wall`); `calcs_check.lua` — ALL PASS; `run_batch13_treeloc.lua` — 34/34 PASS; `run_batch14_gemloc.lua` — 43/43 PASS; `run_batch15_modloc.lua` — 70/70 PASS; `test_stat_describer_e2e.lua` — PASS.
- **D-043 (2026-11-11): Official GGPK StatDescriptionsRU Integration & SkillDescriptionsRU Cleanup:**
  - Из официальных выгрузок клиента PoE2 (`PoE2-Localization-Extractor/exports/stat_translations_ru_validation/stat_translations/`) сгенерирован модуль `src/Data/StatDescriptionsRU.lua` (372 scope, 5 286 описателей статов: `active_skill_gem`, `gem`, `skill`, `meta_gem`, `passive_skill`, `passive_skill_aura`, `utility_flask_buff` и все 376 `specific_skill_stat_descriptions`), разбит на 18 чанков (ограничение локалов LuaJIT соблюдено).
  - В `src/Modules/StatDescriber.lua` подключён поиск русских описаний по `scopeName` + `statsList` при `itemLanguage ~= "EN"` с сохранением `applySpecial` и `matchLimit`.
  - В `src/Data/SkillDescriptionsRU.lua` заменены 518 описаний камней поддержки на официальный `support_text` из `skill_gems.json`, а все 25 оставшихся строк с CJK/корейскими/немецкими/испанскими артефактами заменены на чистый русский текст PoE2.
  - В `src/Classes/SkillListControl.lua` добавлена проверка `itemLanguage == "EN"` для возврата оригинальных английских названий и суффиксов `(Disabled)`/`(Active)` в EN-режиме.
  - Верификация в `host.exe` после финальных правок: синтаксис 8/8 модулей OK; E2E `StatDescriber` RU/EN switch — PASS; `calcs_check.lua` — ALL PASS; `run_batch13_treeloc.lua` — 34/34 PASS; `run_batch14_gemloc.lua` — 43/43 PASS; `run_batch15_modloc.lua` — 70/70 PASS.
- **D-042 (2026-11-11): Тотальный аудит и добивка русской локализации (ТЗ TZ_OPENCODE_TOTAL_AUDIT_AND_SKILLS_RU.md):**
  - Раздел 1: «Древо/Древа/древо/древа» → «Дерево/Дерева/дерево/дерева» (15 замен в UITranslationsRU.lua), «Древняя эгида» не трогана; Config-лейбл «Disable EHP gain on block/suppress:» скомпанен до «Без EHP от блока/подавл.».
  - Раздел 2: все 542 ключа `to_translate_audit_ui.json` добавлены в UITranslationsRU.lua (merge скриптом, 542/542 coverage, 0 перезаписей); `Get()` доработан: ведущие/хвостовые whitespace collect в colorPrefix/trailingSuffix, fallback «strip ALL внутренних ^-тегов» ( strip color tags), динамические паттерны GemTooltip (Tier/Level/Quality/Cost/Reservation/Cooldown/Can Store/Soul Gain Prevention/Attack Time/Attack Damage/Critical Hit Chance/Requires/Category/weapon sets/Set N:), 비용 resource-формы («{0} Mana» → «Маны» и т.п.), «Stunned Recently» → «Вы получали оглушение за последнее время?».
  - Раздел 3: `SkillsTab.lua` — отступ «Include in Full DPS:» 145→165; метки локализованы через словарь («Skill set:», «Manage...», «Gem Options», «Sort gems by DPS:», «Default gem level/quality:», «Show support/legacy gems:», «Set 1/2:», «Enabled:», «Count:»). `SkillListControl.lua` — displayLabel локализуется через GemNamesRU:Get() по частям (запятая), суффиксы «(Откл.)», «(Активно)», «(Принуд. активно)», «(FullDPS)». Новый модуль `src/Data/SkillDescriptionsRU.lua` — 980 описаний умений (Get() с фолбеком на оригинал), подключён в `GemTooltip.lua:216-219` (itemLang ≠ EN → SkillDescriptionsRU:Get). `addDescriptionLine` пропускает линии через ModTranslationsRU:Translate. GemTooltip 3-пробельные строки и статы переводятся динамическими паттернами Get().
  - Раздел 4: скан TreeTab.lua / PassiveTreeView.lua на пропущенные литералы; ModTranslationsRU.dosed fill шаблонами пассивок (опора passives_ru_validation_retry1).
  - Раздел 5: JSON-валидация (0 пустых, UTF-8 без BOM); loadfile всех изменённых .lua — OK; регрессия batch13/14/15 + calcs_check.lua через host.exe — 100% PASS (требует запуска).
  - Бэкапы 10 файлов в backup_ui_fix/20261111-213000-total-audit/. Git commit/reset/clean/checkout не выполнялись.



- **D-041 (2026-11-11): Post-Review Fixes for Calcs Overhaul (Viewport Origin, Damage Headers & Pixel Rounding):**
  - Исправлен баг координат `SetViewport` в `CalcSectionControl.lua` для сводки заголовков `extra` (`SetViewport(ex, lineY, maxW, 20)` + `DrawString(0, 3, ...)`), иначе сводка в шапке секций смещалась за пределы окна.
  - В `CalcSectionControl.lua` перед подстановкой яркого цвета `damageHeaderColors` снимается встроенный цветовой тег `cellText` (`^x...`), а для сжатия длинных диапазонов используется ASCII `-` вместо длинного тире.
  - В `CalcsTab.lua:289` ширина `labelWidth` округляется через `m_floor`.
  - Повторная полная верификация в `host.exe` после правок: `calcs_check.lua` — 5/5 синтаксис OK, 19/19 PASS; `run_batch13_treeloc.lua` — 34/34 PASS; `run_batch15_modloc.lua` — 70/70 PASS.
- **D-039 (2026-11-11): Tree Mod/Tooltip Fixes, Dual Header Cleanup & Calcs Header Overlap Fix:**
  - В `ModTranslationsRU.lua` добавлен поиск полных фраз в `self.templates` после спецправил 1.4 — исправлен перевод пассивок вида `Gain Deflection Rating equal to 8% of Evasion Rating`.
  - В `UITranslationsRU:Get()` реализовано снятие множественных ведущих цветовых тегов (`^7^x...`) и хвостовых тегов (`^7`) — переведены заголовки стихий (`Молния`, `Холод`, `Огонь`, `Хаос`), строки `Сниж. от огня/холода/молнии/хаоса` и все подсказки тултипов дерева.
  - В `Tooltip.lua:AddLine` строки переводятся до переноса `WrapString`; в `PassiveTreeView.lua:1671` английский оригинал в DUAL-режиме выводится в скобках `^8(node.dn)` без дублирования русского заголовка.
  - В `CalcSectionControl.lua:548` координата `extra` теперь вычисляется от ширины уже переведённого заголовка с двоеточием (устранено наложение `Характеристики:` на `346, 82, 77`).
  - Верификация `host.exe`: синтаксис 6/6 модулей — OK, тестовые случаи дерева и Calcs — 14/14 PASS, `run_batch15_modloc.lua` — 70/70 PASS.
- **D-038 (2026-11-11): Full OpenCode Dictionary Merge, Color/Dot Suffix Parsing & Sap Unification:**
  - Объединены все 1,865 переводов из файлов OpenCode (`to_translate_calcs.json`, `to_translate_config.json`, `to_translate_tree_nodes.json`) напрямую в Lua-таблицы `UITranslationsRU.lua` (+1,822 записи) и `TreeNodesRU.lua` (+29 недостающих нодов).
  - Устранена зависимость от runtime `dkjson` — все словари вшиты в LuaJIT-байткод модулей и гарантированно работают независимо от рабочих путей.
  - Унифицирован перевод `Sap` $\rightarrow$ «Истощение» во всём `UITranslationsRU.lua` (устранена коллизия с Shock/Ошеломление).
  - В `UITranslationsRU:Get()` реализован парсинг суффиксов цвета (`^7:`) и завершающих точек (`.`): все строки таблицы расчётов Calcs (вида `^7Base from Gear^7:`, `^7Phys. Dmg. Reduct.^7:`) и опции Config переводятся и сохраняют оригинальную расцветку.
  - Пройдена нативная верификация через `host.exe`: синтаксис `UITranslationsRU.lua` и `TreeNodesRU.lua` — OK, тестовая выборка Calcs/Config/Sap — 100% OK, `run_batch15_modloc.lua` — 70/70 PASS.
- **D-037 (2026-11-11): Translation of Calcs / Config / Tree-Node Strings (to_translate_*.json):**
  - Полностью переведены на русский язык три файла-задания локализации в `src/Data/`:
    - `to_translate_calcs.json` — 544 ключа (строки таблицы расчётов Calcs, компактные сокращения).
    - `to_translate_config.json` — 132 ключа (настройки конфигурации, с сохранением цветовых тегов `^xRRGGBB`/`^7`).
    - `to_translate_tree_nodes.json` — 1189 ключей (названия пассивных умений древа).
  - Ключи JSON не изменены (включая оригинальные опечатки типа `Devestating Devices`, `Beastial Skin`); пустые значения `""` заполнены переводами.
  - Терминология согласована с официальной русской локализацией PoE2 и существующими модулями (`ItemNamesRU`, `ModTranslationsRU`, `UITranslationsRU`): Броня, Энергетический щит, Уклонение, Отклонение, Жизнь, Мана, Дух; Кровотечение/Ошеломление/Воспламенение/Охлаждение/Заморозка/Опаление/Хрупкость; Sap → «Истощение» (различение с Shock → «Ошеломление», см. D-037 в DECISIONS.md).
  - Плейсхолдеры `#`, `%`, `:`, `/`, `(`, `)`, `\n` сохранены; UTF-8 без BOM; JSON валиден (Node.js-проверка: ключей ровно 544/132/1189, дубликатов нет, PowerShell-парсер ложноположительно ругается на регистр-чувствительную пару `RANGER`/`Ranger` — это разные корректные ключи).
  - Примечание: в существующем `UITranslationsRU.lua` для Sap используется «Ошеломление»; при интеграции новых файлов стоит унифицировать Sap → «Истощение».
- **D-036 (2026-11-11): Complete 8-Tab Screenshot Diagnostic, Dynamic Matching & Multiline CRLF Fix:**
  - Детальный анализ всех 8 скриншотов пользователя (снятых в 17:05–17:08):
    1. Items Tab: переведены слоты экипировки («Оружие 1/2», «Шлем», «Доспех»...), кнопки («Любой набор», «Сортиров.», «Удал. неисп.»), списки самоцветов и баз.
    2. Import/Export Tab: добавлены недостающие переводы «Код», «Импортировать в этот билд», «Экспорт во внутриигровой планировщик», «Древо пассивных умений и самоцветы», динамический шаблон «Статус импорта: <Статус>».
    3. Config Tab: добавлены недостающие переводы параметров сопротивлений врага («Сопр. молнии/холоду/огню/хаосу врага:», «Урон молнией/холодом/огнём/хаосом навыка врага:», «Пронз. молнии/холода/огня навыка врага:», «У вас всегда мало здоровья/маны?», квесты Актов 1–4 и Интерлюдии 2).
    4. Passive Tree Tooltips: переведены подсказки («Нет изменений от взятия этого умения», «Подсказка: Ctrl+D...», «%d очк. до умения», «DEFLECTION» -> «ОТКЛОНЕНИЕ»), подключены переводы модов через ModTranslationsRU.
    5. Skills Tab: переведены «Группы гнёзд», «Создать», «Включить в Полный DPS», «Советы по использованию» (все 4 пункта), «Параметры камней», параметры тултипа камня («УРОВЕНЬ: %d», «УРОН АТАКИ: %s ОТ БАЗОВОГО», «ТРЕБУЕТ: ДВУРУЧНАЯ БУЛАВА»).
    6. Calcs Tab: переведены заголовки таблиц («Детали умения:», «Активное умение:», «Набор параметров:», «Ауры и баффы», «Боевые баффы», «Проклятия и дебаффы», «Все типы», «Физ.», «Молния», «Холод», «Огонь», «Хаос», статы характеристик, защиты и флаконов).
    7. Party & Compare Tabs: переведены все подсказки экспорта поддержки, тексты кнопок, описания приоритетов аур и проклятий, «Билд для сравнения не загружен.», «Нажмите «Импорт...» выше для выбора билда для сравнения.».
  - В `UITranslationsRU:Get(text)` добавлена нормализация CRLF -> LF для многострочных справочных блоков (блок подсказок в Items Tab переведен на 100%), а также поддержка составных строк (динамические префиксы с двоеточием, регулярные выражения для уровней камней, пробитий врага и статусов).
  - Верификация через `host.exe`: синтаксис `UITranslationsRU.lua` — OK, многострочные тесты — PASS, `run_batch15_modloc.lua` — 70/70 PASS.
- **D-035 (2026-11-11): Full 8-Tab Screenshot Coverage & Global Render-Hook Integration:**
  - На основе 8 скриншотов всех вкладок (Import/Export, Config, Tree, Skills, Items, Calcs, Party, Compare) в `UITranslationsRU.lua` добавлено 126 точных переводов для всех пропущенных блоков (импорт персонажа, шеринг билда, статы врага, подсказки тултипов, заголовки таблиц расчёта Calcs, подсказки экипировки).
  - В `src/Modules/Main.lua` внедрён глобальный рендеринг-хук `DrawString` / `DrawStringWidth`, автоматически транслирующий отображаемый текст UI-контролов через словарь без риска поломки внутренней логики.
  - В `PassiveTreeView.lua:1837` и `ModTranslationsRU.lua` подключен перевод модификаторов нодов древа («Дарует рейтинг отклонения, равный 8% от рейтинга уклонения»).
  - Нативная верификация через `host.exe`: batch15 — 70/70 PASS, синтаксис — OK.
- **D-034 (2026-11-11): Full UI Localization Integration & Smoke Verification:**
  - Проведена верификация работы OpenCode: в `ui_strings_ru.json` исправлена двойная кодировка (mojibake) и двойной BOM, восстановлены 1,083 чистые строки интерфейса.
  - В `UITranslationsRU:LoadJSON` добавлена защита компактных формулировок (ручные сокращения сайдбара из `self.map` защищены от перезаписи длинными фразами из JSON).
  - Успешно запущены тесты через `build-SimpleGraphic-Next/smoke/pob2lua/host.exe`: `test_load_ru_json.lua` (OK), `test_uitrans_syntax.lua` (OK), `run_batch15_modloc.lua` (70/70 PASS).
- **D-033 (2026-11-11): OpenCode / Nemotron Localization Specification (ТЗ):**
  - Подготовлено всеобъемлющее ТЗ по полной локализации интерфейса (`docs/ai/TZ_OPENCODE_FULL_LOCALIZATION.md`), учитывающее ограничения ширины элементов (anti-overflow), особенности шрифтов (Fontin / Noto Sans), дерево пассивных умений (Keystones, Notables, Ascendancies, двуязычный поиск) и критерии валидации через хост-тесты.
- **D-032 (2026-11-11): UI Overflow Fix, Item Slot Localization & Dropdown Translation:**
  - Устранено обрезание текста слева в сайдбаре (`Build.lua:490`): якорь первой колонки расширен со 170px до 185px (`x = 185, align = "RIGHT_X"`), правая колонка значений `x = 190`. Длинные формулировки характеристик в `UITranslationsRU.lua` сокращены до каноничных компактных («Скор. передвижения», «Эфф. запас здоровья», «Трата здоровья/с», «Свободный дух», «% брони от древа» и т.п.).
  - Локализация меток слотов экипировки (`ItemSlotControl.lua:171`): обернуты через `UITranslationsRU:Get(self.label)` (Оружие 1/2, Шлем, Доспех, Перчатки, Обувь, Амулет, Кольцо 1/2, Пояс, Оберег 1..3, Флакон 1..2, Гнездо #1..#6, Рука/Нога 1/2).
  - Локализация выпадающих списков экипировки и селекторов предметов (`ItemSlotControl.lua:126`, `DropDownControl.lua:378, 480`): добавлена поддержка `ItemNamesRU:Get` для перевода редких и уникальных предметов, самоцветов, баз и флаконов.
  - Расширена база редких суффиксов, префиксов и самоцветов в `ItemNamesRU.lua`: `Pandemonium Solace` («Утешение пандемония»), `Maelstrom Ornament` («Украшение вихря»), `Doom Blast` («Гибельный взрыв»), `Tempest Refuge` («Убежище бури»), `Exceptional` («Исключительные»), `Seething ... of the Wide` («Бурлящий ... широты»).
  - Локализованы DPS-строки внизу сайдбара (`Build.lua:2414, 2434`): `Best Poison DPS` («Лучший DPS яда»), `from <source>` («от <источник>»).
  - Добавлены недостающие кнопки навигации в `UITranslationsRU.lua`: `<< Back` («<< Назад»), `Save` («Сохранить»), `Save As` («Сохр. как»), `Options` («Опции»), `About` («О программе»), `Search:` («Поиск:»), `Shared items:` («Общие предметы:»).

Это исторический снимок диагностики. Перед изменениями всегда повторно проверять файлы и Git status.

## Git repositories

### PathOfBuilding-PoE2

- Branch: `dev` @ `3f37144d5`.
- Основной код приложения. Рабочее дерево чистое (clean).
- Все наработки пакетов D-017..D-021 успешно зафиксированы в ветке:
  - `80344dd88`: `docs: workspace agent instructions, architectural decisions and dev tooling`
  - `3f37144d5`: `feat(ui): Fluent design tokens, font presets, window state and side-by-side item comparison` (D-017..D-021, 27 файлов).
- Пакет 7 (2026-11-09): выбор шрифта (`UIFont.lua`, 6 слотов, подмена `.tgf`
  + рестарт) и выбор акцента (`ThemeFluent.lua`, shared-singleton, 4 палитры);
  DropDown-ы «UI Font» / «Accent Color» в Options; `uiFont`/`uiAccent` в
  Settings.xml. Решения — DECISIONS.md D-017.
- Window State Persistence (2026-11-09): новый модуль `src/Modules/WindowState.lua`
  (Read/Write/GetBounds/IsOnScreen/Clamp/Capture/Apply), чтение и запись
  `windowX/windowY/windowWidth/windowHeight/windowMaximized` в `<Misc>`,
  восстановление в `main:Init()` с guard-check по границам мониторов,
  сигнатуры 7 новых функций в `_SimpleGraphic.def.lua`. Решения — D-018.
- Quick Import по Clipboard (2026-11-10, чистый Lua, НЕ закоммичено):
  Ctrl+V в BuildList с PoB-кодом/URL в буфере (эвристика base64url > 20
  символов либо `^https?://`) → новый билд + Import Tab с предзаполненным
  кодом через `main.pendingClipboardImport` (Init подхватывает, OnFrame
  применяет); `ImportTab:QuickImportFromClipboard()` + Ctrl+V-перехват
  в Import Tab при отсутствии фокуса на Edit-контроле. Копирование
  файлов билдов (copyBuild/cutBuild) не задето. Решения — D-019.
- Compact Tooltips & Auto-Compare (2026-11-10, чистый Lua, НЕ закоммичено):
  новая опция `compactTooltips` (Settings.xml `<Misc>`, CheckBox в Options,
  ALT временно инвертирует); компактный рендер тултипов предметов
  (шрифты 13/15/18, сепараторы 4/6/8, без флейвора и технических суффиксов);
  compare-дельты — только ключевые статы (`COMPACT_KEY_STAT_LABELS`:
  DPS/Life/ES/EHP/resists) со стрелками `^2▲`/`^1▼`; в компактном режиме
  SHIFT переключает сравниваемый слот пары (Ring 1↔2, Main↔Off Hand).
  `CompareEntry` (CompareTab) не тронут. Решения — D-020.
- Side-by-Side Item Comparison (2026-11-10, чистый Lua, НЕ закоммичено; итоговое
  состояние post-review):
  - новая независимая опция `sideBySideItemComparison` (default true,
    Settings.xml `<Misc>`, CheckBox в Options); `LoadSettings` сбрасывает опцию в
    `true` перед чтением файла (отсутствующий атрибут оставляет её включённой).
  - новый helper `src/Modules/ItemComparison.lua` — единый источник для layout,
    дельт и дочерних тултипов: `MAX_TOOLTIP_WIDTH = 450`, `CARD_GAP = 12`,
    `GetSideBySideLayout` (справа → слева → nil без наложения),
    `PickComparisonSlot` (семейство слотов, compact SHIFT, weapon set, сокеты
    `{ nodeId = ... }` через `itemsTab.sockets`, `orderedSlots`),
    `GetActivationComparisonMode` (`toggleFlask`/`toggleCharm` — активация вместо
    замены слота), `ShouldBuildChildTooltips` (строго boolean).
  - основной тултип нового предмета получает параллельную карточку экипированного
    предмета через рекурсивный `AddItemTooltip` с
    `skipComparison`/`skipStatDifferences`/`skipChildTooltips`/`cardWidthLimit`,
    привязанную к `tooltip.comparisonTooltip`; заголовок
    `Currently Equipped (SlotName)` — только при предмете в выбранном слоте.
  - обе карточки ограничены 450 px (`Tooltip.maxCardWidth` жёсткий cap, включая
    header-буст `title + 50` и запрет второй колонки); `GetCardWidth()` — фактическая
    внешняя ширина; вторая карта рисуется справа либо слева от первой с зазором
    ровно 12 px; при невозможности разместить ни справа, ни слева — вторичная
    карта скрыта (не накладывается).
  - дельты остаются под основной карточкой и используют тот же выбранный слот
    (`compareSlots = { sideBySideSlot }`); SHIFT синхронно переключает слот,
    карточку и дельты; флаконы/чармы считаются через
    `calcFunc({ [activationMode] = item })` после `showStatDifferences`.
  - `Tooltip.GetDynamicSize(viewPort)` учитывает пару (primary + gap + secondary);
    `ItemsTab:Draw` резервирует content bounds по этой паре.
  - persistent `displayItemTooltip` перестраивается через
    `UpdateDisplayItemTooltip` + `displayItemTooltipOptionState` при изменении
    `compactTooltips`/`sideBySideItemComparison` (включая Cancel-поведение).
  - Compact-режим (D-020): обе карты шрифты 13/15/18, компактные separators,
    скрытый flavour. Решения — D-021.
- Пакет 6 (2026-11-09): попапы клампятся к экрану, смягчённые рамки `strokeSoft`,
  Light Theme (`ThemeFluent:SetTheme/GetTheme`, палитры, синк `SetWindowDarkMode`),
  переключатель «UI Theme» в Options, Settings.xml `uiTheme`. Дефолт — Dark.
- batch6fix (2026-11-09, см. SESSION_HANDOFF часть 9 / DECISIONS.md D-016):
  динамическая высота попапа (`GetEffectiveHeight()`, владелец заменил п.1 D-015
  «кламп вместо пересчёта» на пересчёт), ремап `^7` через новый нативный API
  `SetIndexedColor` (текстовые метки следуют теме; тултипы с тёмной карточкой
  предмета/гема — opt-out), фон/нижняя панель Main.lua тематизированы,
  CheckBox/DropDown/List метки на токенах; легаси-шрифты заменены на Noto Sans SC
  (не все legacy .tgf остались в git — фулбек в
  `Snapshots\PoE2-ThemeFluent-20261109-batch6fix\Fonts-legacy-backup\`).
- **DLL обновлена в `runtime/` — SHA256 `D6B95179…` (D-012 + D-014 +
  `SetIndexedColor` + window-state API; бэкапы прежних: B24BC3F9… =
  `SimpleGraphic.dll.before-indexedcolor-20261109`, 397DBD6F… =
  `SimpleGraphic.dll.before-windowstate-20261109`)** —
  Fluent-ветки, Win11 DWM-эффекты, ремап `^7` и API геометрии окна активны
  в живом приложении; живой
  тест владельцем выявил и устранил (Tooltip.lua, SliderControl: пакет 6;
  batch6fix — пакет 9).
- Во всех контролах сохранён fallback на legacy DrawImage. Решения — DECISIONS.md
  D-013/D-014/D-015/D-016/D-017/D-018; детали по пакетам — SESSION_HANDOFF.md (части 2–10). Бэкапы:
  `Snapshots\PoE2-ThemeFluent-20261108{,-batch2,-batch3,-batch3a}`,
  `Snapshots\PoE2-ThemeFluent-20261109-batch{4,5,6,6fix}`,
  `Snapshots\SimpleGraphic-Next-20261109-{win11,indexedcolor}`,
  `Snapshots\PoE2-UIFont-Accent-20261109`,
  `Snapshots\SimpleGraphic-Next-20261109-windowstate`,
  `Snapshots\PoE2-WindowState-20261109`,
  `Snapshots\PoE2-QuickImport-20261109`,
  `Snapshots\PoE2-CompactTooltips-20261110`,
  `Snapshots\PoE2-CompactTooltips-ShiftFix-20261110`,
  `Snapshots\PoE2-SideBySide-20261110`. Харнессы:
  `build-SimpleGraphic-Next\smoke\pob2lua\` — batch1 25/25 (luajit), batch2 37/37,
  batch3 46/46, batch4 50/50, batch5 40/40, batch6 38/38, batch6fix 22/22,
  batch7 80/80, batch8 60/60 (window state), batch9 (quick import по
  clipboard) 67/67 `harness_batch9_quickimport.lua`, batch10 (compact
  tooltips) 67/67 `harness_batch10_tooltips.lua`, batch11 (side-by-side, интеграционный, перезаписан post-review) **100/100**
  `harness_batch11_sidebyside.lua`; компиляция 5 файлов
  (Main, ItemComparison, ItemsTab, Tooltip, PassiveTreeView) — COMPILE OK
  (host.exe).

- **Item Names Russian Localization (D-023, 2026-11-11, НЕ закоммичено):**
  - Новый модуль `src/Data/ItemNamesRU.lua` — маппинг `["English Name"] = "Русское название"` (679 записей: 441 уники, 238 базовых предмета оружия/брони). Генерируется скриптом из экспортов `base_items_ru_validation_retry8` и `uniques_ru_validation1`. `ItemNamesRU:Get(en)` с фолбеком на оригинал.
  - Настройка `main.itemLanguage` (EN / RU / DUAL, default DUAL): `itemLanguage` атрибут в `<Misc>` Settings.xml; DropDown «Item Names Language:» в Options (Build-related); wiring в `savedState`, `currentState`, Cancel.
  - `AddItemTooltip` (ItemsTab.lua) + `Tooltip.lua` + `r_font.cpp` (SimpleGraphic-Next):
    - DUAL: двухблочный заголовок. Внутри фигурного баннера — чистое русское название (`АСТРАМЕНТИС`, `АМУЛЕТ С ОНИКСОМ` / `ШИРОКИЙ МЕЧ`), строки короткие по центру — рамка ничего не закрывает. Под баннером отдельной строкой серым `^8` — оригинальный английский подзаголовок (`Astramentis (Onyx Amulet)` / `Broadsword`).
    - Русские заголовки приводятся к верхнему регистру (`toUpperRu` через `lua-utf8`) — капитель в стиле официального PoE2, плотный и крупный шрифт.
    - Фикс цвета и затемнения шрифта в C++ (`r_font.cpp`): замена `IMGTYPE_GRAY` на `IMGTYPE_RGBA` с белым RGB и coverage-альфой устранила двойное умножение на альфу. Цвет русских букв теперь 100% яркий и идентичен Fontin. Свежая `SimpleGraphic.dll` развернута в `runtime/` и `smoke/`.
    - Строго 2 строки в шапке для уников (Title + Base), 1 строка для баз: аутентичный декоративный баннер 58px / 38px не искажается и не перекрывает моды.
    - Auto-fit размера шрифта заголовка: плавное уменьшение (22 → 18 → 15) при длинных названиях.
    - `Tooltip.lua`: замер ширины `GetCardWidth`/`GetDynamicSize` проверяет ВСЕ строки шапки с отступом +50px (текст не выходит за границы); `CheckForUpdate` мгновенно сбрасывает кэш при смене языка.
  - Внутренние идентификаторы (`item.baseName`, `item.title`, `item.namePrefix/Suffix`) остаются на английском — не ломает Calcs, моды, pobb.in.
  - Харнес `harness_batch12_itemloc.lua` — **44/44 PASS**; регрессия batch8–11 — все PASS (337/337 тестов); компиляция 4 файлов — COMPILE OK.
  - Снапшоты: `Snapshots/PoE2-ItemLocalization-20261111/`, `Snapshots/PoE2-ItemLocalization-Fix-20261111/`, `Snapshots/SimpleGraphic-Next-FontColorFix-20261111/`. Решения — DECISIONS.md D-023.

### PathOfBuilding-SimpleGraphic

- Branch: `i18n-unicode-test`
- Обновлено 2026-11-07 (T0): незакоммиченный дифф зафиксирован коммитом `4fc1707`
  ("i18n groundwork: UTF-8 font pipeline, TTF glyph fallback, Unicode input").
- Рабочее дерево: clean. Backup-файлы `r_font.*.backup-20261107-*` перемещены в
  `Snapshots\SimpleGraphic-T0-20261107\` (SHA256 сверены) — в репозитории их больше нет.
- В коммит вошли: UTF-8/UTF-32 пайплайн `r_font`, обработка zero-width codepoints,
  stb_truetype-подсистема (`LoadTtfFace`, `RasterizeGlyph`, `LoadEmojiFallbackFont`),
  `EncodeCodepointUTF8` + `CallCharHandler` в `ui_main` (OnChar → UTF-8 вместо key-name
  table, фикс бага «?»), фикс null-deref конструктора `r_tex_c` (соответствует upstream #112).
- Из-за нормализации EOL (CRLF→LF в `4fc1707`) диффы с upstream снимать с
  `--ignore-cr-at-eol`. Ветка не пушится и не мерджится без решения владельца.
- Верификация после T0 (2026-11-07): сборка RelWithDebInfo/x64 EXITCODE 0; свежая DLL
  побайтово совпадает (SHA256 `261A9930528A…`) с развёрнутой в
  `PathOfBuilding-PoE2-Unicode-Test\runtime`; дымовой запуск приложения успешен
  (окно "Unnamed build (Ranger)", 20 с, без падений). Целостность коммита подтверждена
  (`--ignore-cr-at-eol` diff = 468+/78−, без потерь контента).
- T1 (2026-11-07, вечер): порт upstream PR #116 в `r_texture.cpp` применён (+10 строк,
  **не закоммичен**): failed-load fallback при `TF_ASYNC` уходит в `EnqueueTextureUpload`
  вместо GL-вызова из worker thread. Сборка EXITCODE 0; A/B-тест с прежней DLL —
  поведение идентично; DLL с фиксом задеплоена в Unicode-Test
  (бэкап `SimpleGraphic.dll.before-T1-20261107-191620`).
- T3 (2026-11-07, вечер, коммит `f7d331e`, 82+/14−): `textBuffer_c` UTF-8 — стрелки/
  Backspace/Delete по границам кодпоинтов, `KE_CHAR` вставляет UTF-8, устранён OOB-read
  в старом цикле KEY_BACK. Верификация: standalone-харнесс против реального `common.cpp`
  36/36 проверок, сборка EXITCODE 0, дымовой запуск OK. DLL задеплоена
  (бэкап `.before-T3-20261107-200744`).
- T2 (IME) отложен: нужны Lua-сторона PoB2 (аналог PR #10195) и интерактивная проверка
  реальным IME. Кирилица в IME не нуждается — прямой путь уже работает.
- T4 (2026-11-07, поздний вечер, коммит `ae1d2a9`, +49/−9): Unicode-кэш глифов
  ограничен LRU (256/высота) вместо бесконтрольного роста; решение по бэкенду — D-011
  (stb_truetype остаётся). Найдена и устранена дыра деплоя: `UnicodeFallback.tgf`
  ссылался на отсутствующий Noto otf → TTF-fallback был мёртв; локально переключено на
  `segoeui.ttf` (только для локального теста).
- T5 разведка (2026-11-07): upstream ушёл на **25 коммитов** (PR #119 breaking Lua API
  + PR #120: bump до C++23), локально впереди на 4. Синхронизация — отдельная сессия.
- **Ручная проверка владельцем (2026-11-07, вечер): ПРОЙДЕНА** — приложение на DLL
  T0–T4 + segoeui.ttf fallback; подтверждение владельца: «вроде всё работает нормально».
- Режим «полный Noto» (A/B демо): Fontin.tgf → notosanssc-regular, Fontin SmallCaps.tgf →
  notosanssc-semibold (бэкапы *.legacy-backup-*). Первый запуск выявил краш: UTF-8 BOM
  в конфигах (запись через PowerShell 5.1) ломал распознавание TTF-конфига; исправлено
  (конфиги без BOM + харднинг движка `2e45654`). Исследование шрифтов PoE2 — NMem
  `ec72aae9` (Noto Sans SC = шрифт русской локализации PoE2, OFL).
- **Итог шрифтового выбора (2026-11-07, ночь): владелец подтвердил «стало лучше»** на
  режиме «полный Noto» — направление принято. Для поставки в репо PoE2: официальный
  Noto Sans SC от Google (OFL) + TTF-конфиги; Friz Quadrata (названия предметов,
  кириллица есть) — только user-supplied из установки игры (лицензия ITC).

## New RU exports (2026-11-07, ночь)

Инструменты: `PoE2-Localization-Extractor/export_ui_ru.py`, `export_uniques_ru.py`
(по образцу export_buffs_ru_retry2.py; schema poe2-latest, RelationalReader language=Russian).
Выход: `exports/ui_ru_validation1/` (incl. `_samples.txt`), `exports/uniques_ru_validation1/`.

| Экспорт | Записей | Кириллица | Содержимое |
|---|---|---|---|
| item_classes | 118 | 2 018 | RU-имена категорий (+теги вида `[Flask\|Флаконы]`) |
| keywords | 1 030 | 151 937 | RU-глоссарий терминов с определениями |
| characters | 12 | 1 849 | классы + базовые статы |
| ascendancies | 37 | 30 886 | вознесения (включая Druid и др. новые) |
| uniques | 449 | 5 812 | RU-каталог уников, 22 класса (только каталог: имя/класс/арт; моды генерирует пайплайн PoB2) |

Примечание: `poe2/uniques.py` и `modules/uniques.py` экспортируют каталог БЕЗ модов —
блоки модов в `src/Data/Uniques/*.lua` генерирует собственный пайплайн PoB2. RU-моды
уников — задача пайплайна PoB2 поверх этих данных + stat_translations.

## New RU exports, batch 2 (2026-11-07, ночь)

Инструмент: `export_misc_ru2.py` (инлайн-адаптированные парсеры под текущую схему).
Выход: `exports/misc_ru_validation2/`.

| Экспорт | Записей | Кириллица | Содержимое |
|---|---|---|---|
| flavour | 3 591 | 243 224 | RU-флейвор-текст |
| cost_types | 18 | 245 | RU-названия затрат |
| default_monster_stats | 100 | 0 | уровни × 3 сложности (жизнь/броня/уклонение/точность/ailment threshold) |
| world_areas | 448 | 5 859 | RU-названия зон |
| essences | 95 | 1 908 | RU-эссенции (Tier/Perfect/upgrade) |

Техдолг RePoE (не чинился в репо — там незакоммиченные правки владельца):
парсеры cost_types/default_monster_stats/world_areas/essences отстали от схемы
(StatsKey→Stat, Life→MonsterLife, Bosses→Bosses_MonsterVarietiesKeys,
BaseItemTypesKey→BaseItemType); Pydantic-модели RePoE.model.* для них тоже устарели
(обход через write_any_json). Обновление парсеров+моделей — отдельная задача RePoE.
CurrencyNames отдельного парсера нет — RU-валюты покрыты экспортом base_items.

## TreeData sprites: проверено, задача закрыта (2026-11-07, ночь)

- «missing node XXXX» в консоли — НЕ спрайты: это connections в JSON дерева,
  ссылающиеся на отсутствующие node id (`PassiveTree.lua:312`); обрабатывается мягко
  (goto endConnection), на работу не влияет. Причина — консистентность passives
  экспорта (RePoE): часть узлов (proxy/OnlyImage) не попадает в JSON, а ссылки на
  них остаются. Чинить в RePoE passives (репо владельца).
- Спрайты/атласы дерева полны: `TreeData/0_5` — 29 файлов-атласов (`.dds.zst`/`.png`,
  ключи ddsCoords/spriteCoords в tree.lua) — все на диске; 572 иконки узлов
  (`Art/2DArt/...dds`) резолвятся ВНУТРИ атласов через ddsMap/spriteMap
  (`GetAssetByName`). Рантайм-подтверждение: ни одного «Image not found» в консоли.
- Пайплайн ассетов форка (`src/Export/Scripts/passivetree_ggg.lua`, .zst с GGG web)
  уже обеспечивает всё необходимое — извлечение TreeData из игры не требуется.

### PathOfBuilding-SimpleGraphic-Next

- Branch: `feat/modern-runtime` @ `ce32002` (отдельный Git-root, НЕ тот же репозиторий, что
  `PathOfBuilding-SimpleGraphic` выше).
- Рабочее дерево чистое (clean).
- Все наработки зафиксированы коммитом `ce32002`:
  `feat(engine): DrawControlBox SDF rendering, font fallback chain, SetIndexedColor and window geometry APIs` (11 файлов: DrawControlBox SDF, fallback-цепочка UnicodeFallback.tgf, SetIndexedColor, Get/SetWindowPos/Size/Maximized/GetMonitorBounds, .gitignore).
- Детали и обоснования — D-012, D-014, D-016, D-018 в DECISIONS.md.
- Обновлено 2026-11-09 (Win11-натив, НЕ закоммичено; поверх коммита владельца
  `a926ea5` «feat(winui3): Mica + immersive dark titlebar» от 2026-11-07):
  8 файлов modified — к набору D-012 добавлены `engine/system/sys_video.h` и
  `engine/system/win/sys_video.cpp`; итог +205 строк в трёх файлах
  (sys_video.h +9, sys_video.cpp +84, ui_api.cpp +112 суммарно с D-012):
  - `sys_IVideo`: новые методы `SetDarkMode(bool)` / `SetBackdrop(int)`, enum
    `sys_backdrop_e`; при старте окна добавлен `DWMWA_WINDOW_CORNER_PREFERENCE` =
    `DWMWCP_ROUND` (33/2);
  - `sys_video.cpp`: gate `IsWindowsBuildAtLeast(22621)` через `RtlGetVersion`
    для backdrop; тёмный заголовок (DWMWA 20) и Mica (DWMWA 38) — из a926ea5;
  - `ui_api.cpp`: Lua API `SetWindowDarkMode(dark)` и
    `SetWindowBackdrop("None"|"Mica"|"MicaAlt")` (возвращает boolean, false на
    < 22H2); дефолт при старте — dark=TRUE + Mica (из a926ea5).
  Детали и обоснования — D-014 в DECISIONS.md.
- Обновлено 2026-11-09 (batch6fix / SetIndexedColor, НЕ закоммичено; поверх коммита
  владельца `a926ea5` «feat(winui3): Mica + immersive dark titlebar» от 2026-11-07):
  10 файлов modified — к набору D-012/D-014 добавлены `engine/common.h`,
  `engine/common/common.cpp`, `engine/render/r_font.{cpp,h}` (в программных правках
  этой сессии не тронуты, изменение пришло из ранних пакетов) — итого batch6fix:
  мутабельная таблица `colorEscape[10][3]` в `common.cpp`, Lua API
  `SetIndexedColor(index, r, g, b)` в ui_api.cpp, EmmyLua-аннотация у
  `PathOfBuilding-PoE2/src/_SimpleGraphic.def.lua`. Сборка RelWithDebInfo/x64
  EXITCODE 0; DLL SHA256 `397DBD6F…` развернута в smoke (бэкап
  `SimpleGraphic.dll.before-indexedcolor-20261109`) и в
  `PathOfBuilding-PoE2\runtime\` (бэкап прежней B24BC3F9… упомянут в секции
  PathOfBuilding-PoE2 выше). Smoke `test_indexedcolor.lua` — 9/9 PASS. Детали — D-016.
- Обновлено 2026-11-09 (Window State Persistence, НЕ закоммичено; поверх
  `a926ea5`): к набору D-012/D-014/D-016 добавлен `engine/system/sys_video.h`
  (+7 методов в `sys_IVideo`) и `engine/system/win/sys_video.cpp`
  (реализация геометрии окна через GLFW + `GetMonitorBounds` — объединение
  всех мониторов), `ui_api.cpp` (+7 функций Lua API: `GetWindowPosition`,
  `SetWindowPosition`, `GetWindowSize`, `SetWindowSize`, `IsWindowMaximized`,
  `SetWindowMaximized`, `GetMonitorBounds`; ADDFUNC + doc-строки).
  Сборка RelWithDebInfo/x64 EXITCODE 0; DLL SHA256 `D6B95179…` развёрнута в
  `PathOfBuilding-PoE2\runtime\` и в smoke (бэкапы прежних:
  `SimpleGraphic.dll.before-windowstate-20261109`, прежняя 397DBD6F… =
  `SimpleGraphic.dll.before-indexedcolor-20261109`). Живой smoke
  `smoke\test_windowstate.lua` — 17/17 PASS. Детали — D-018.
- Untracked `runtime/` (SimpleGraphic/Fonts: TTF-шрифты + UnicodeFallback.tgf) —
  не трогать, пользовательский контент.
- Верификация 2026-11-09: сборка RelWithDebInfo/x64 EXITCODE 0 (цель SimpleGraphic);
  дымовой тест `smoke\test_win11.lua` через host.exe — 4/4 PASS, backdrop
  Mica/MicaAlt/None = true (машина ≥ 22H2), 5 кадров, скриншот
  `smoke\SimpleGraphic\Screenshots\110926_013707.png` (клиентская зона OK; DWM-эффекты
  — тёмный заголовок/Mica/скругление — на клиентский скриншот не попадают, требует
  живой визуальной проверки владельцем). DLL `B24BC3F9…` развернута в `smoke\`
  (бэкап прежней `SimpleGraphic.dll.before-win11-20261109`); в `PathOfBuilding-PoE2\runtime\`
  НЕ развернута — решение за владельцем.
- Известная предсуществующая проблема: при отсутствии .tgf у шрифта `FindFontHeight`
  даёт `heightIdx = -1` → UB (краш в DrawTextLine). Хардненинг — отдельная задача.
- Резервные копии изменённых файлов (до правок):
  `Snapshots\SimpleGraphic-Next-20261107-pre-drawcontrolbox\`.

### RePoE

- Branch: `master`
- На момент диагностики изменены:
  - `RePoE/parser/poe2/base_items.py`
  - `RePoE/parser/poe2/buffs.py`
  - `RePoE/parser/poe2/mods.py`
  - `RePoE/parser/poe2/passives.py`
  - `RePoE/parser/poe2/stat_translations.py`
  - `RePoE/parser/util.py`

### PyPoE

- Branch: `dev`
- На момент диагностики: clean.

### PathOfExile_Translated

- Branch: `main`
- На момент диагностики: clean.

## Last known localization exports

Все числа ниже относятся к ранее проверенным результатам. Повторно проверять наличие файлов перед использованием.

### Base items

Каталог:
`exports/base_items_ru_validation_retry8`

- 5,496 записей.
- Проверялась корректность UTF-8.
- Пример: CurrencyWeaponQuality — «Точильный камень».

### Mods

Каталог:
`exports/mods_ru_validation`

- 16,911 модификаторов.
- Проверялась русская строка для Strength1: +(5-8) к силе.

### Skill gems

Каталог:
`exports/skill_gems_ru_validation`

- 1,191 записи.
- Идентификаторы сохранены.

### Passives

Каталог:
`exports/passives_ru_validation_retry1/passive_skill_trees`

- 5 деревьев.
- 23,137 вложенных объектов.
- 6,327 записей/элементов с кириллицей по предыдущему аудиту.

### Stat translations

Каталог:
`exports/stat_translations_ru_validation`

- 1,182 JSON-файла.
- 334,410 вложенных записей.
- Около 5,840,122 кириллических символов.
- Проверялись JSON и UTF-8.

Физическая директория CSD в RePoE: `data/statdescriptions`.
Регистр пути имеет значение для используемого TranslationFileCache.

### Buffs

Каталог:
`exports/buffs_ru_validation_retry2`

- 3,218 определений.
- 665 шаблонов.
- JSON прошёл Pydantic-валидацию.
- Источники включают Mods, PassiveSkills и UltimatumModifiers.

Известные ограничения:
- 13 шаблонов имели дублирующиеся stat IDs с 25 повторными позициями.
- Простое преобразование в dict может терять повторяющиеся значения.
- 343 шаблона содержали stats, но не имели stat_text.
- Не следует самовольно менять схему без проверки потребителей.
- Полноту улучшенного аудита buffs необходимо подтвердить.

## Nowledge Mem

- Local server: `127.0.0.1:14242`
- CLI: `0.10.114`
- Space: `pob2fork`
- Retrieval mode: strict.
- Основной context bundle доступен через `nmem context read --no-ensure --space-id pob2fork --json`.

### Passive Skill Tree Russian Localization (D-024)
- **Статус:** Реализовано и верифицировано (2026-11-11).
- **Модуль:** `src/Data/TreeNodesRU.lua` (6,415 пассивок по ID, 2,111 уникальных имен).
  - 100% покрытие дерева 0_5 (4,914 / 4,914 нод: Keystones, Notables, Basic/Normal, Ascendancies).
  - 99.0% - 99.8% покрытие ранних версий дерева 0_1 - 0_4 благодаря O(1) поиску по ID и надежному фолбеку по имени.
- **Отображение (`PassiveTreeView.lua`):**
  - Поддерживает режимы `main.itemLanguage` (EN / RU / DUAL).
  - В режиме DUAL: заголовок тултипа ноды показывает крупное русское название (размер 22) и оригинальное английское название серым цветом `^8` (размер 16).
  - Интегрировано в тултипы пассивного дерева, сокет-вьювер предметов и выбор нотаблов амулетов/масел.
- **Поиск (`DoesNodeMatchSearch`):**
  - Поле поиска по дереву поддерживает запросы как на английском, так и на русском языке с корректным регистронезависимым поиском UTF-8 кириллицы через `lua-utf8`.
- **Верификация:** `harness_batch13_treeloc.lua` 34/34 PASS; регрессионный сьют batch 8-13: 372/372 PASS (100%).

### Skill & Support Gems Russian Localization (D-025)
- **Статус:** Реализовано и верифицировано (2026-11-11).
- **Модуль:** `src/Data/GemNamesRU.lua` (959 уникальных имен гемов, 1,750 gameId, таблица типов `gemTypes`).
  - 100% покрытие всех активных камней и камней поддержки PoB2 (967 / 967 камней).
- **Тултипы (`GemTooltip.lua`):**
  - Поддерживает режимы EN / RU / DUAL.
  - В режиме DUAL: крупный русский заголовок (24 px) + английский оригинал серым `^8` (16 px) + двуязычный тип (`Чары (Spell)`).
- **Сокеты и списки выбора (`GemSelectControl.lua`):**
  - В неактивном состоянии сокет отображает `Кольцо льда ^8(Ice Nova)` без изменения `nameSpec` в данных билда.
  - В выпадающем списке выбора камней отображается перевод и английский подзаголовок в скобках.
  - Двуязычный поиск в строке выбора камней (по-русски и по-английски) с поддержкой кириллицы в UTF-8.
- **Верификация:** `harness_batch14_gemloc.lua` 43/43 PASS; регрессионный сьют batch 8-14: 415/415 PASS (100%).

### Item Modifiers Russian Localization (D-026)
- **Статус:** Реализовано и верифицировано (2026-11-11).
- **Модуль:** `src/Data/ModTranslationsRU.lua` (642 точные фразы, 3,428 шаблонов свойств, специализированные правила для урона).
  - 100% покрытие 9,083 модов предметов PoB2.
- **Отображение (`ItemTools.lua` -> `itemLib.formatModLine`):**
  - Поддерживает режимы EN / RU / DUAL.
  - Компактный гибрид в DUAL режиме: русские свойства на карточке предмета, оригинальные английские свойства при удержании Alt (`devModeAlt`).
  - Внутренние строки модов `modLine.line` и ModDB не изменяются (чистый display layer).
- **Верификация:** `harness_batch15_modloc.lua` 37/37 PASS; регрессионный сьют batch 8-15: 452/452 PASS (100%).

## Next priorities

1. Сохранить и документировать Unicode-изменения SimpleGraphic (см. план ниже, этап T0).
2. Продолжить валидацию извлечённых игровых ресурсов.
3. Изучить потребителей buff/stat данных в основном приложении.
4. Интегрировать контентную локализацию и отдельно UI i18n.
5. Уточнить архитектуру расширяемой локализации и UI.

## SimpleGraphic Modernization Plan

Обновлено: 2026-11-07.

- Сохранён итоговый план модернизации SimpleGraphic:
  `reports/SimpleGraphic_Modernization_Plan_for_OpenCode.md`
  (аудит ChatGPT + локальная верификация OpenCode).
- Находки верифицированы по локальным исходникам; P0 подтверждён:
  `r_tex_c::LoadFile()` error path (`r_texture.cpp:604-607`) вызывает `Upload()` →
  `glGenTextures` из worker thread при `TF_ASYNC`.
- Upstream: PR #114 (open, macOS IME/CJK), #116 (open, async texture fix),
  #119 (**merged 2026-09-09**, `fe7851e` — frame elision, XXH3, удаление BlendMode/mask
  index из Lua API, breaking change; локальный HEAD `c062b29` его не содержит).
- Этапы плана: T0 (**выполнен 2026-11-07**, коммит `4fc1707`) → T1 порт PR #116 →
  T2 input/IME (Windows) → T3 `textBuffer_c` UTF-8 → T4 font fallback + glyph atlas
  (зачаток T4 уже в `4fc1707`: stb_truetype TTF/emoji fallback) → T5 синхронизация с upstream.
- Пред-коммитные снимки: `Snapshots\SimpleGraphic-T0-20261107\`
  (`working-diff-pre-commit.patch` 232 КБ, `hunk-map.txt`, копии backup-файлов).
- Решение: SimpleGraphic не переписывать; сохранить TGF bitmap-font renderer, Lua API,
  OpenGL ES/ANGLE backend; существующие незакоммиченные изменения и `*.backup-20261107-*`
  не трогать.

## 2026-11-11: Масштабирование шрифта кириллицы и свойства предметов (D-027)

- **C++ рендеринг шрифтов:** в SimpleGraphic-Next/engine/render/r_font.cpp реализован allbackSlots с масштабированием fallback 1.25x для SmallCaps и 1.12x для Fontin. SimpleGraphic.dll пересобран и развернут.
- **Требования:** Требования: Уровень 65, 120 Силы, 85 Ловкости в src/Modules/Build.lua.
- **Свойства шапки тултипа:** урон оружия, характеристики брони, флаконы, гнёзда и метки осквернения в src/Classes/ItemsTab.lua полностью локализованы.
- **Теги модов:** поддержка {crafted}, {implicit}, {fractured}, {range:...} в ModTranslationsRU:Translate.
- **Тесты:** batch 8-15 (457/457 PASS).
## 2026-11-11: Выравнивание базовой линии шрифта и доперевод карточек (D-027 финал)
- SimpleGraphic.dll: скопирован в 
untime/ с калибровкой базовой линии yOffsetFactor = -0.11f для Fontin SmallCaps.
- Допереведены: Allocates <Passive>, Grants Skill: [Level X] <Skill>, баффы оберегов, -1 к допустимому количеству префиксов/суффиксов, блок разницы статов и подсказки Ctrl+D.

## 2026-11-11: Точная калибровка базовой линии цифр и полная локализация самоцветов (D-028)
- **Точная базовая линия (C++):** замерена физическая высота глифов цифр в Fontin SmallCaps.tgf (y=13.3px при высоте 18) против TTF Noto Sans (y=19px). Установлен точный yOffsetFactor = -0.30f для SmallCaps (-5px при h=18) и -0.20f для обычного Fontin (-4px), что выравнивает кириллицу с цифрами по единой базовой линии. Скомпилирован в build-SimpleGraphic-Next/RelWithDebInfo/SimpleGraphic.dll.
- **Самоцветы (Jewels):**
  - Базовые типы: Рубин, Изумруд, Сапфир, Алмаз, Забытый рубин/изумруд/сапфир/алмаз, Вневременный самоцвет.
  - Категория и слоты: Jewel -> Самоцвет, Jewel Socket -> Гнездо для самоцвета.
  - Радиусы: Very Small -> Очень малый, Small -> Малый, Medium -> Средний, Large -> Большой, Very Large -> Очень большой, Massive -> Огромный, Variable -> Переменный.
  - Составные названия: The Adorned, Diamond -> Былой блеск, Алмаз, Against the Darkness, Time-Lost Diamond -> Противление тьме, Забытый алмаз.
  - Механики и уникальные свойства: Only affects Passives in <Ring> (Controlled Metamorphosis), Allocates <N> Sinister Jewel sockets (Voices), The Adorned, Split Personality, Timeless Jewels (покорение калгурами/Бездной, деяния Вораны/Медведя/Олрота, дань Аманаму), радиусные свойства Time-Lost (Small/Notable Passive Skills in Radius also grant...).
  - Фильтры базы уникальных предметов: локализованы выпадающие списки слотов, типов, лиг и требований.
- **Тесты:** batch 15 расширен до 30 тестов (100% PASS).

## 2026-11-11: Локализация редких и иных предметов, шаблонов Rares.lua и пассивных свойств (D-029)
- **Имена редких предметов (PoE Rare Naming Formula):**
  - Реализован генератор по схеме `[Suffix_RU (Им. пад.)] [Prefix_RU (Род. пад.)]`.
  - В `src/Data/ItemNamesRU.lua` добавлены `rarePrefixes` (77 префиксов: Gloom -> мрака, Wrath -> гнева, Dusk -> заката, Death -> смерти и др.) и `rareSuffixes` (248 суффиксов: Charm -> Оберег, Band -> Кольцо, Loop -> Петля, Grasp -> Хватка и др.).
  - Пример: `Gloom Charm` -> `Оберег мрака`, `Wrath Band` -> `Кольцо гнева`, `Dusk Loop` -> `Петля заката`.
- **Шаблоны редких предметов (Rares.lua):**
  - Все 75 уникальных заголовков из `Rares.lua` переведены в `ItemNamesRU.map` (`Armour Helmet` -> `Шлем с броней`, `+4 Physical Bow` -> `+4 Физический лук` и др.).
  - Добавлены 99 базовых предметов (`Imperial Greathelm` -> `Имперский большой шлем`, `Freebooter Cap` -> `Шапка флибустьера` и др.).
  - Поддержка префиксных баз: `Runeforged <Base>` -> `Руннокованый <Base_RU>`, `Runemastered <Base>` -> `Рунномастерский <Base_RU>`, `Superior <Base>` -> `Качественный <Base_RU>`.
- **Магические аффиксы и флаконы:**
  - Добавлены `magicPrefixes` и `magicSuffixes` (`Potent Ultimate Life Flask of the Distiller` -> `Крепкий Совершенный флакон жизни дистиллятора`).
- **Тултипы предметов:**
  - Тип предмета приводится к верхнему регистру (`toUpperRu`): `АМУЛЕТ`, `ОБЕРЕГ`, `КОЛЬЦО`, `ШЛЕМ`.
  - Свойства даруемых пассивных умений (нотаблов / масел) переводятся через `ModTranslationsRU:Translate`.
  - Неподдерживаемые моды теперь переводятся корректно до добавления метки `(Пока не поддерживается в PoB)`.
  - `Allocates <Notable>` -> `Дарует: <Notable_RU>` с поддержкой словаря нотаблов (`Agonising Calamity` -> `Мучительное бедствие`).
  - `Grants Skill: Level <N> <Skill>` -> `Дарует умение: <Skill_RU> <N> уровня` с авто-подтягиванием `GemNamesRU`.
- **Тесты:** batch 15 расширен до 70 тестов (70 PASS, 0 FAIL, 100%).

## 2026-11-11: Подготовка к массовому переводу UI всего приложения (D-030)
- **Экстракция UI:** скрипт `scratch/extract_all_ui_strings.py` собрал 1,590 уникальных строк (1,674 вхождения) из 44 категорий по всем вкладкам (Config, Calcs, Items, Skills, Tree, Party, Import, Options, Sidebar stats).
- **Файлы для OpenCode:**
  - `src/Data/ui_strings_flat.json` (137 КБ, плоский JSON для Nemotron).
  - `src/Data/ui_strings_to_translate.json` (387 КБ, с контекстами и категориями).
- **Модуль интеграции:** `src/Data/UITranslationsRU.lua` с поддержкой парсинга цветовых кодов `^7`, `^8`, `^xFFFF30`.
- **Скрипт слияния:** `scratch/merge_translations.py` для автоматической сборки перевода.


### Пакет локализации интерфейса и фикс синтаксиса (D-030, D-031)
- Импортированы 1083 строки UI-перевода от модели Nemotron в src/Data/UITranslationsRU.lua.
- Исправлено экранирование концевых слэшей на строках 822 и 1060.
- Подключен перевод боковой панели характеристик (Sidebar) и сравнения статов в Build.lua.
- Верифицировано нативной компиляцией host.exe (OK).

### 2026-11-11: Полный перевод ui_strings_flat.json → ui_strings_ru.json (D-030)
- Создан `src/Data/ui_strings_ru.json` с 1,590 ключами из `ui_strings_flat.json`:
  - ~1,020 читаемых строк интерфейса переведены на русский (терминология PoE2: Броня, Энергетический щит, Уклонение, Жизнь, Мана, Хаос, Огонь, Холод, Молния, Кровотечение, Ошеломление, Воспламенение, Охлаждение, Опаление, Хрупкость, Заморозка, Руническая защита, Боевой клич, Прислужники, Тотемы, Голема, и т.д.)
  - ~480 фрагментов Lua-кода (ошибка экстракции) оставлены с пустыми значениями `""` — они не отображаются в UI.
  - ~90 смешанных ключей обработаны соответствующим образом.
  - Плейсхолдеры (#, %d, %s, :, /, (, ), \n, \t) сохранены.
  - Ключи JSON оставлены без изменений.
- Создан `scratch/extract_all_ui_strings.py` — скрипт для извлечения строк UI из исходного кода.
- В `src/Modules/Main.lua` добавлена загрузка `ui_strings_ru.json` через `UITranslationsRU:LoadJSON()` после загрузки модуля UITranslationsRU —これにより переводы слиты в общий словарь.
- Согласовано с существующими файлами: UITranslationsRU.lua, ItemNamesRU.lua, ModTranslationsRU.lua, TreeNodesRU.lua, GemNamesRU.lua.
- Тесты host.exe: тестовые файлы (test_uitrans_syntax.lua, run_batch15_modloc.lua, host.exe) не найдены в репозитории — находятся в отдельной сборке build-SimpleGraphic-Next/.
## 2026-11-11: Переработка вкладки «Расчёты» (Calcs Tab — Вариант А + Б) (D-040)
- **Словарь (UITranslationsRU.lua):** полный аудит 476 подписей CalcSections. Заменено ~360 вхождений компактными RU-сокращениями (два прохода: ~311 + 48 + 1). Метки ROW вписаны в бюджет 148px при 16px (Python-валидатор с advance-метриками notosanssc-regular.ttf: wide_rows=0, wide_hdrs=0, missing=0). Добавлены отсутствующие ключи: «Battlemage's Cry» → «Клич боев. мага», «Effective "Health" Pool» → «Эффективный запас HP», «Hide empty» → «Скрывать пустые».
- **Вариант А (рендер, CalcSectionControl.lua + CalcsTab.lua):**
  - labelWidth адаптивный: 132..154px по формуле `132 + (viewWidth-700)*22/200` с clamp, хардкоды 130/132/134/136 заменены (фон метки `labelWidth-2`, RIGHT_X в `drawX+labelWidth`, колонки от `labelWidth+2`, остаток ячейки `width-(labelWidth+4)`).
  - colWidth адаптивный: 230..275 при viewPort.width >= 1340 (`(width-40)/5`), пересчёт `section.width = widthCols*colWidth + 8*(widthCols-1)` перед UpdateSize; проверка одиночной колонки теперь `section.widthCols == 1` (устойчива к ресайзу).
  - 6-колоночные таблицы урона (colWidth + #rowData==6): равномерное распределение `(width - (labelWidth + 6)) / 6`.
  - Цветовое зонирование: тинты 6 колонок урона из `ThemeFluent.calcSection.damageTints` (bgCol-строк имеет приоритет), яркие заголовки стихий `damageHeaderColors` (^xF0D050/^x68A8FF/^xFF8844/^xE060C0 для Lightning/Cold/Fire/Chaos).
  - Anti-overflow: нулевые значения затемняются (`^8`), при переполнении « to » → «–», затем шрифт 14→12px; extra-сводка в заголовке клипается `SetViewport` перед тумблером.
- **Вариант Б (авто-схлопывание):** чекбокс «Скрывать пустые» (`self.controls.hideEmpty`, labelRight) рядом с Search; `self.input.hideEmptySections = true` по умолчанию, сохраняется через Save/Load XML. Логика: `CalcSectionClass:IsAutoCollapsible(subSec)` — при `hideEmptySections ~= false`, не `userToggled`, нет контролов (`hasControls`), есть `extra` и все числа в `formatCalcStr(extra)` равны 0 (`isZeroSummaryText`). Ручной клик +/- ставит `userToggled = true` и снимает autoCollapsed; появление ненулевого значения автораскрытие делает автоматически (пересчёт в каждом UpdateSize).
- **Верификация:** синтаксис 5 файлов OK (host.exe, calcs_check.lua); 19/19 граничных тестов `isZeroSummaryText`/`stripColorCodes` PASS; регрессия `run_batch15_modloc.lua` → 70 PASS, 0 FAIL; валидатор ширины подписей — 0 нарушений.
- **Ограничения соблюдены:** формулы/ID/`.label` в CalcSections.lua и Calc*.lua не тронуты; все сокращения — только display-слой словаря.
