# PoB2Fork — Current State

Дата зафиксированного состояния: 2026-11-07.

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
