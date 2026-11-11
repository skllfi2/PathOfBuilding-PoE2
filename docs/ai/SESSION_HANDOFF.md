# Session Handoff

Дата: 2026-11-11. Заполнил: OpenCode (Nemotron-3.5-Super-VL). Последнее обновление: часть 15 — Item Names Russian Localization.

## 15. Item Names Russian Localization (2026-11-11)

### Что сделано
1. **Новый модуль `src/Data/ItemNamesRU.lua`** — маппинг `["English Name"] = "Русское название"` (679 записей: 441 уники, 238 базовых предмета оружия/брони). Генерируется скриптом `gen_itemnames_ru_v2.py` из экспортов `base_items_ru_validation_retry8/base_items.json` и `uniques_ru_validation1/uniques.json`. `ItemNamesRU:Get(en)` с фолбеком на оригинал.
2. **Настройка `main.itemLanguage` (src/Modules/Main.lua):**
   - `self.itemLanguage = "DUAL"` в `Init()`.
   - Чтение `node.attrib.itemLanguage` в `LoadSettings()` с валидацией (EN/RU/DUAL).
   - Запись `itemLanguage = self.itemLanguage or "DUAL"` в `SaveSettings()` (`<Misc>`).
   - Добавлен в `savedState`, `currentState` (resize), `controls.cancel` (откат).
   - DropDown «Item Names Language:» в Options (Build-related): English (Original) / Русский (RU) / Dual (Русский + English).
3. **Локализация в `AddItemTooltip` (src/Classes/ItemsTab.lua):**
   - EN: только английское название (как было).
   - RU: русское название из словаря (фолбек на оригинал).
   - DUAL: русская строка первой строкой крупно, вторая строка серым (`^8`) — английский оригинал.
   - Покрывает и вторичную карточку Side-by-Side (рекурсивный `AddItemTooltip`).
   - Внутренние идентификаторы (`item.baseName`, `item.title`, ...) остаются на английском.
4. **Снапшот:** `Snapshots/PoE2-ItemLocalization-20261111/` (Main.lua, ItemsTab.lua до правок).
5. **Харнес:** `build-SimpleGraphic-Next\smoke\pob2lua\harness_batch12_itemloc.lua` + `run_batch12_itemloc.lua`.

### Результаты верификации
- `harness_batch12_itemloc.lua` (host.exe): **38/38 PASS** — модуль ItemNamesRU, wiring Main.lua, локализация ItemsTab.lua, компиляция 3 файлов.
- Регрессия: batch8 60/60, batch9 67/67, batch10 67/67, batch11 100/100 — **все PASS**.
- `git diff --check` — без whitespace-ошибок. Коммиты не выполнены (ветка dev).

### Живая проверка владельцем (предложено)
- Options → Item Names Language → RU / DUAL / EN; проверить тултипы предметов (оружие, броня, бижутерия, флаконы, чармы, уники).
- Проверить сохранение `itemLanguage` в `Settings.xml` и восстановление при переоткрытии Options.
- Проверить DUAL-режим: русское название крупно, английское серым (`^8`) второй строкой.
- Проверить Side-by-Side карту: локализация適用ется ко вторичной карточке.
- Решения — DECISIONS.md D-023; статус — CURRENT_STATE.md.

## 14. Side-by-Side Item Comparison (2026-11-10)

### Что сделано
1. **Новая настройка (`src/Modules/Main.lua`):** независимая boolean-опция
   `main.sideBySideItemComparison` (default `true`): Init-дефолт, чтение и запись
   `sideBySideItemComparison` в `<Misc>` файла `Settings.xml`, CheckBox
   `^7Side-by-Side Item Comparison:` в Options; wiring в `savedState`,
   `currentState` (resize) и Cancel. `LoadSettings` сбрасывает опцию в `true`
   перед чтением `Settings.xml` — отсутствующий атрибут оставляет опцию
   включённой. Опция не зависит от `compactTooltips`.
2. **Выбор слота (`src/Modules/ItemComparison.lua`):** новый чистый helper:
   семейство слота строится без ` Swap` и без конечного номера; в compact-режиме
   SHIFT переключает первые два слота семейства (Ring 1↔2, Weapon 1↔2), при
   hover экипированного предмета выбирается исходный слот, а SHIFT — парный.
   Swap-варианты следуют за активным weapon set. Сокеты `{ nodeId = ... }`
   разрешаются через `itemsTab.sockets`; `orderedSlots` сохраняют numerский
   порядок узлов.
3. **Параллельная карточка (`src/Classes/ItemsTab.lua`):**
   `AddSideBySideComparisonTooltip` строит тултип экипированного предмета через
   рекурсивный `AddItemTooltip` с `skipComparison`, `skipStatDifferences`,
   `skipChildTooltips`, `cardWidthLimit = ItemComparison.MAX_TOOLTIP_WIDTH`;
   вторичная карточка привязана к `tooltip.comparisonTooltip` и получает
   заголовок `Currently Equipped (SlotName)`. Если слот пуст, показывается
   только основной тултип. Обе карточки имеют лимит 450 px. Дельты остаются
   под основной карточкой и ограничиваются тем же слотом
   (`compareSlots = { sideBySideSlot }`), поэтому compact SHIFT синхронно
   меняет карточку и дельты. Флаконы и чармы сравниваются через
   `calcFunc({ [activationMode] = item })` (
   `ItemComparison.GetActivationComparisonMode(base)`) — состояние активации,
   а не замена слота.
4. **Layout (`src/Classes/Tooltip.lua`):** `Tooltip:Draw` рисует
   `comparisonTooltip` параллельно через `ItemComparison.GetSideBySideLayout`:
   справа, если хватает `viewPort`, иначе слева; зазор между карточками 12 px
   (`ItemComparison.CARD_GAP`); при невозможности разместить ни справа, ни
   слева вторичная карта не рисуется (без наложения). `maxCardWidth` — жёсткий
   cap ширины карты (включая header-буст `title + 50`) и запрет переезда во
   вторую колонку; `GetCardWidth()` возвращает фактическую внешнюю ширину;
   `GetDynamicSize(viewPort)` возвращает pair-aware width/height
   (primary + 12 px gap + secondary ≈ 912 px при двух картах по 450) для
   content bounds в `ItemsTab:Draw`.
5. **Persistent tooltip:** `ItemsTab:UpdateDisplayItemTooltip` фиксирует
   `displayItemTooltipOptionState` (`compactTooltips`, `sideBySideItemComparison`);
   `ItemsTab:Draw` перестраивает отображение при изменении любой из опций
   (включая путь Cancel).
6. **Снапшот до правок:** `Snapshots\PoE2-SideBySide-ReviewFix2-20261110\`
   (`Main.lua`, `ItemsTab.lua`, `Tooltip.lua`, `ItemComparison.lua`,
   `PassiveTreeView.lua`, копии `docs/ai`).
7. **Харнесс:** `build-SimpleGraphic-Next\smoke\pob2lua\
   harness_batch11_sidebyside.lua` (перезаписан под интеграционные тесты с
   реальной интеграцией `Tooltip`) + `run_batch11_sidebyside.lua`; результат —
   `batch11_sidebyside_results.txt`.

### Результаты верификации
- `harness_batch11_sidebyside.lua` (host.exe): **100/100 PASS** — выбор
  семейства и SHIFT, сокеты/orderedSlots, Settings.xml round-trip + сброс
  дефолта в `LoadSettings`, viewport-арифметика (`GetSideBySideLayout`
  right/left/hidden, точный зазор 462 px DrawString-анкоров), реальный
  `Tooltip.Draw` (к wider/left/скрытой карте, ширина карты ровно 450 px,
  `maxCardWidth` запрещает вторую колонку, `GetDynamicSize` pair = 912 px),
  `CheckForUpdate` сброс при изменении опций, статические wiring-проверки и
  компиляция 5 файлов (`Main.lua`, `ItemComparison.lua`, `ItemsTab.lua`,
  `Tooltip.lua`, `PassiveTreeView.lua`).
- Регрессия: batch10 67/0, batch9 67/0, batch8 60/0, batch7 80/0 PASS.
- `git diff --check` — без whitespace-ошибок (только предупреждение Git о
  LF→CRLF для `Main.lua`). Коммиты не выполнялись.

### Живая проверка владельцем
- Options → включить/выключить чекбокс, перезапустить приложение и проверить
  сохранение `sideBySideItemComparison` в `Settings.xml`.
- Проверить обычный и compact-режим на реальных кольцах/оружии: SHIFT должен
  одновременно менять вторичную карточку и дельты.
- Проверить положение карточек у правого/левого края окна и на узком viewport
  (вторичная карта скрыта, без наложения).
- Решения — DECISIONS.md D-021 (включая блок «финальное состояние post-review»);
  статус — CURRENT_STATE.md.

## Current goal (сессия 2026-11-09, часть 10: Window State Persistence)

Задача владельца: сохранять и восстанавливать между запусками PoB2 геометрию
окна (X, Y, Width, Height, Maximized). Реализовано в двух независимых
Git-репозиториях, **без коммитов**.

1. **Движок — `PathOfBuilding-SimpleGraphic-Next` (ветка `feat/modern-runtime`):**
   - `engine/system/sys_video.h`: в `sys_IVideo` добавлены `GetWindowPos`,
     `SetWindowPos`, `GetWindowSize`, `SetWindowSize`, `IsMaximised`,
     `SetMaximised`, `GetMonitorBounds`.
   - `engine/system/win/sys_video.cpp`: реализация через GLFW
     (`glfwGetWindowPos/SetWindowPos/GetWindowSize/SetWindowSize`,
     `glfwGetWindowAttrib(GLFW_MAXIMIZED)`, `glfwMaximizeWindow/RestoreWindow`).
     `GetMonitorBounds` возвращает объединение всех мониторов (`mon[]`).
     Добавлен `#include <algorithm>` для `std::min/std::max`.
   - `ui_api.cpp`: 7 функций Lua API + `ADDFUNC` + doc-строки:
     `GetWindowPosition`, `SetWindowPosition`, `GetWindowSize`, `SetWindowSize`,
     `IsWindowMaximized`, `SetWindowMaximized`, `GetMonitorBounds`.
   - Функции движка намеренно не клампят позицию (контракт «как есть»);
     проверку видимости выполняет клиент.
2. **Lua-слой — `PathOfBuilding-PoE2` (ветка `dev`):**
   - Новый модуль `src/Modules/WindowState.lua`: `Read`, `Write`, `GetBounds`,
     `IsOnScreen`, `Clamp`, `Capture`, `Apply` — чистая логика, тестируется
     без окна.
   - `src/Modules/Main.lua`: `WindowState = LoadModule("Modules/WindowState")`;
     чтение `windowX/windowY/windowWidth/windowHeight/windowMaximized` из
     `<Misc>` в `main:LoadSettings()`; `main:ApplyWindowState()` (вызывается
     из `main:Init()` и `main:ChangeUserPath()`, защищён флагом
     `windowStateApplied`); запись состояния в `main:SaveSettings()` (при
     максимизации сохраняется последний «нормальный» размер).
   - `src/_SimpleGraphic.def.lua`: сигнатуры 7 новых функций.
3. **Правила guard check:** позиция недействительна, если окно оставляет на
   экране меньше 64 px по оси; полностью за экраном → центрирование;
   частично → подтягивание к видимой области; размер клампится по виртуальному
   рабочему столу. Минимальный размер окна 1080×720 задаёт сам движок
   (`CFG_VID_MINWIDTH/HEIGHT`) — GLFW увеличивает меньший запрос.

Резервные копии: `Snapshots\SimpleGraphic-Next-20261109-windowstate\`
(sys_video.h, sys_video.cpp, ui_api.cpp), `Snapshots\PoE2-UIFont-Accent-20261109\`
(Main.lua, ThemeFluent.lua), `Snapshots\PoE2-WindowState-20261109\`
(Settings.xml и SimpleGraphic.cfg перед живыми прогонами). Бэкапы DLL:
`runtime\SimpleGraphic.dll.before-windowstate-20261109` (PoE2) и
`smoke\SimpleGraphic.dll.before-windowstate-20261109`.

Верификация (2026-11-09):
- Сборка движка RelWithDebInfo/x64 — EXITCODE 0; DLL SHA256 `D6B95179…`
  развёрнута в `PathOfBuilding-PoE2\runtime\` и в `build-SimpleGraphic-Next\smoke\`.
- `harness_batch8.lua` — **60/60 PASS** (luajit и host.exe): парсинг/запись
  атрибутов, guard check, кламп позиции/размера, capture/apply, старый DLL без
  API, статическая проверка wiring.
- Живой smoke рантайма `smoke\test_windowstate.lua` — **17/17 PASS**
  (позиция/размер/максимизация/границы мониторов читаются и применяются).
- Живой прогон PoB2 (`runtime\Path{space}of{space}Building-PoE2.exe`): обычное
  восстановление (300,200,1400×900 → 300,180 — Y подтянут к экрану);
  out-of-bounds (5000,5000 → центрирование 260,90); `windowMaximized="true"` →
  окно развёрнуто; при выходе приложение само записало атрибуты в `Settings.xml`.
- Компиляция в рантайме (`host.exe`): Main.lua, WindowState.lua, UIFont.lua,
  ThemeFluent.lua — COMPILE OK (16/16 в `compile_results.txt`).

Важно для владельца:
- `Settings.xml` парсится только **без BOM** — при записи вручную через
  PowerShell 5.1 (`Set-Content -Encoding UTF8`) добавляется BOM, и настройки
  (включая состояние окна) перестают читаться.
- Собственный механизм движка (`vid_resizable=3` → cvar `vid_last`) продолжает
  работать параллельно: он восстанавливает окно раньше, чем Lua-слой, и
  перезаписывается при следующем выходе приложения.
- Решения — DECISIONS.md D-018; статус — CURRENT_STATE.md.

## Current goal (сессия 2026-11-09, часть 9: PoB2 — batch6fix, живой тест владельца)

Исправление трёх дефектов, выявленных живым тестированием владельца после пакета 6.
В `PathOfBuilding-PoE2` (ветка `dev`, НЕ закоммичено) и `PathOfBuilding-SimpleGraphic-Next`
(ветка `feat/modern-runtime`, НЕ закоммичено):

1. **Попапы: динамическая адаптация высоты** (замена D-015 п.1 «кламп вместо
   пересчёта» — владелец осознанно выбрал пересчёт):
   - `PopupDialog.lua`: новый метод `GetEffectiveHeight()` = `m_min(height, main.screenH - 20)`;
     y = `m_max(10, m_floor((main.screenH - effectiveH) / 2))`; Draw рисует карту с
     effectiveH и ресинхронизирует `controls.scrollBar` (height + `SetContentDimension`);
     scrim синхронизирован с эффективной высотой.
   - `Build.lua` resizeFunc (Similar Builds) зеркалит тот же кламп.
   - Константы «минимум y = 10» и «запас экрана 20px» — точки калибровки для владельца.
2. **Ремап `^7` для Light-темы через нативный API** (вместо правок сотен `^7`-меток):
   - `SimpleGraphic-Next`: мутабельная таблица `colorEscape[10][3]` в `common.cpp`,
     новый Lua API `SetIndexedColor(index, r, g, b)` (ui_api.cpp), EmmyLua-аннотация
     в `_SimpleGraphic.def.lua`.
   - `ThemeFluent:SetTheme` вызывает `SetIndexedColor(7, textPrimary)` при
     переключении темы.
   - **Opt-out для тултипов с тёмной карточкой предмета/гема** (`self.tooltipHeader`):
     Tooltip.lua на время Draw переключает `^7` обратно в белый и восстанавливает
     после; базовый цвет plain-строк обычных тултипов в Light =
     `ThemeFluent.colors.textPrimary`, тёмная карточка сохраняет белый базовый.
   - `Main.lua`: фон (`main:DrawBackground` → `ThemeFluent.colors.background`) и нижняя
     левая панель (312×58, border + background) тематизированы в Fluent-ветке.
   - `CheckBoxControl`/`DropDownControl` (вкл. строки списка, strikethrough,
     «No matches»)/`ListControl` (строки + defaultText) — метки на
     `colors.textPrimary/textSecondary/textDisabled`, legacy-ветки байт-в-байт.
3. **Шрифты: устаревшие Fontin/Liberation Sans → Noto Sans SC** (OFL, официальный
   релиз Google; Noto Sans SC = шрифт русской локализации PoE2):
   - Все 6 legacy `.tgf`-слотов переписаны в TTF-конфиги на notosanssc-regular.ttf
     (Fontin/Fontin Italic/Liberation Sans) и notosanssc-semibold.ttf
     (Fontin SmallCaps/SC Italic/Liberation Sans Bold); ttf-файлы скопированы в
     `runtime\SimpleGraphic\Fonts\`, legacy .tgf забэкаплены. Слоты захардкожены в
     `r_main.cpp`, поэтому замена через .tgf-конфиги; F_FIXED (Bitstream Vera Mono,
     консоль) не тронут.
   - Движок собран заново (RelWithDebInfo, EXITCODE 0); DLL SHA256 `397DBD6F…`
     (с наработками D-012/D-014 + `SetIndexedColor`) — **развернута в
     `PathOfBuilding-PoE2\runtime\SimpleGraphic.dll`** (бэкап прежней B24BC3F9… =
     `SimpleGraphic.dll.before-indexedcolor-20261109`) и в smoke.
4. **Инфраструктура харнессов**: харнессы требуют АБСОЛЮТНЫХ путей (относительные
   CWD нестабильны); стаб `main` в harness_batch4 дополнен `screenW/screenH`
   (крэш прогонов); smoke-окружение выровнено — патченная lua51.dll (89244909…,
   диалект `+=`) скопирована на место ванильной (бэкап `lua51.dll.vanilla-backup-20261109`).

Pre-commit бэкапы: `Snapshots\PoE2-ThemeFluent-20261109-batch6fix\` (9 Lua-файлов +
`Fonts-legacy-backup\`), `Snapshots\SimpleGraphic-Next-20261109-indexedcolor\`
(common.h/common.cpp/ui_api.cpp).

Верификация (2026-11-09): smoke `test_indexedcolor.lua` — 9/9 PASS (золотой `^7`
после ремапа на скриншоте; дифлексы baseline/remapped по SHA256); компиляция
15/15 OK; харнессы — batch6fix (новый) **22/22**, batch6 38/38 (ожидания клампа
обновлены), batch4 50/50, batch3 46/46, batch2 37/37, batch5 40/40, batch1 25/25
(luajit; харнесс `Temp\opencode\pob2-themefluent-test\harness_themefluent.lua` —
в smoke его никогда не было, результаты `batch1_results.txt`). Решения — DECISIONS.md
D-016. Живая проверка владельцем: Light-тема (фон/текст/тултипы), шрифты, ресайз Options.

## Current goal (сессия 2026-11-08: SimpleGraphic-Next)

Выполнены три задачи в `PathOfBuilding-SimpleGraphic-Next` (ветка `feat/modern-runtime`,
отдельный Git-root; `PathOfBuilding-SimpleGraphic` не тронут):

1. `engine/render/r_font.cpp`: `LoadFallbackFont()` парсит массив `"fonts"` из
   `runtime/SimpleGraphic/Fonts/UnicodeFallback.tgf` и грузит цепочку
   FrizQuadrataITC → SegoeUI → NotoSansCJK; глиф ищется последовательно.
   Faces шарятся между шрифтами через `GetSharedFallbackFace` (кэш по пути,
   Noto CJK ~17 МБ). `LoadFallbackFont()` теперь вызывается и для TTF-конфиг шрифтов.
2. `engine/render/r_main.cpp`: SDF-программа скруглённого прямоугольника
   (radius до 16px, 1px рамка, мягкая drop shadow) — новая команда слоя `ROUNDED_BOX`,
   немедленный drawcall после flush пакета; culling и frame-elision совместимы.
3. `ui_api.cpp`: Lua-функция `DrawControlBox(x, y, w, h, radius[, bgColor[, borderColor[, borderWidth[, shadowBlur]]]])`
   (цвета — `{r,g,b,a}` или nil→текущий drawColor; DPI-скейлинг как в DrawImage).

Статус: изменения **не закоммичены** (6 файлов, +493/−2); `runtime/` по-прежнему
untracked. Сборка RelWithDebInfo/x64 EXITCODE 0 (`build-SimpleGraphic-Next`).
Верификация: дымовой тест minimal-host (`RunLuaFileAsWin`) + Lua-скрипт; скриншот
подтверждает рендер боксов (radius 0/8/12/16, рамки, тени blur 3/6/16, полупрозрачный
фон) и цепочку фолбэков (кириллица/CJK/символы без tofu). Скриншот и тестовый стенд:
`build-SimpleGraphic-Next\smoke\` (вне репозитория). Детали и обоснования — D-012.

Инфраструктура сборки: cmake 4.3.1 из
`C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\...\CMake\bin`;
vendored vcpkg в репо Next забутстраплен, зависимости восстановлены из бинарного кэша.
Генератор — «Visual Studio 18 2026».

## Current goal (сессия 2026-11-08, часть 2: PoB2 — Fluent-тема контролов)

В `PathOfBuilding-PoE2` (ветка `dev`, изменения НЕ закоммичены):
1. **Новый модуль** `src/Modules/ThemeFluent.lua` — токены WinUI 3 Fluent (Windows 11 Dark):
   фоны #1F1F21 (окно/инпут) и #292B30 (карточки/контролы), акцентное золото PoE2
   #D4AF37, radius control=4 / card=8 / tooltip=8, тени small=3 / medium=6 / large=10.
   Цвета — позиционные таблицы `{r,g,b,a}` (напрямую совместимы с DrawControlBox
   и `SetDrawColor(unpack(...))`); компонентные группы button/edit/card/tooltip/dialog.
2. **`src/Classes/ButtonControl.lua`**: `Draw()` при наличии глобальной `DrawControlBox`
   рендерит скруглённую кнопку (radius 4, рамка 1px, тень 3; hover → золотая рамка,
   pressed/disabled — токены темы); при `DrawControlBox == nil` — прежний путь
   DrawImage байт-в-байт. Цвет метки вынесен в общий хвост (`textCol`) с учётом
   того, что блок `self.image` перебивает draw color.
3. **`src/Classes/EditControl.lua`**: аналогично — скругление 4, тёмный инпут #1F1F21,
   золотая рамка при фокусе; `borderFunc` (валидация) имеет приоритет над фокус-рамкой;
   fallback на legacy-путь сохранён.
4. **`src/_SimpleGraphic.def.lua`**: добавлены EmmyLua-аннотации `DrawControlBox`.

Pre-commit бэкапы: `Snapshots\PoE2-ThemeFluent-20261108\` (ButtonControl, EditControl,
_SimpleGraphic.def; SHA256 исходников зафиксированы в логе сессии).

Верификация (2026-11-08): синтаксис 4 файлов через luajit loadfile — OK; токены
ThemeFluent проверены скриптом (позиционность 1..4, диапазон 0..1, hex-значения
#1F1F21/#292B30/#D4AF37, резолв групп) — OK; интеграционный харнесс с заглушками
рантайма и РЕАЛЬНЫМИ классами (`luajit`, Temp\opencode\pob2-themefluent-test\):
**25/25 PASS** — обе ветки (Fluent/legacy), состояния normal/hover/pressed/disabled/
focus, borderFunc, корректность аргументов DrawControlBox.

Примечание: текущая поставляемая DLL (SimpleGraphic v2.5.5) не содержит DrawControlBox —
в рантайме сейчас активна legacy-ветка; Fluent включится автоматически с DLL из
SimpleGraphic-Next (feat/modern-runtime).

## Current goal (сессия 2026-11-08, часть 3: PoB2 — Fluent-тема, пакет 2)

Вторая партия контролов в `PathOfBuilding-PoE2` (ветка `dev`, НЕ закоммичено):
1. **`src/Classes/CheckBoxControl.lua`**: radius=3; checked → золотая заливка
   accent (+hover/pressed оттенки) и контрастная тёмная галочка; unchecked → тёмный
   фон #1F1F21 с тонкой рамкой; borderFunc (валидация) приоритетнее hover/фокуса;
   `checkImage`-спрайты работают в обеих ветках.
2. **`src/Classes/DropDownControl.lua`**: поле radius=4, золотая рамка при открытии
   (self.dropped); popup — radius=6, фон surface, рамка, тень 6px, единый
   DrawControlBox-проход вместо legacy-пары «рамка + заливка» (второй проход в
   Fluent-ветке пропущен); hover-строка списка — скруглённая подсветка surfaceHover
   (radius 4) в координатах viewport.
3. **`src/Classes/ScrollBarControl.lua`**: Fluent-ветка ТОЛЬКО для ползунка —
   плашка radius=3, цвета thumb/thumbHover/thumbDrag (белые 0.35/0.55/0.65);
   кнопки/стрелки/трек не тронуты в обеих ветках.
4. **`src/Classes/Tooltip.lua`** (фактическое место отрисовки карточки тултипа;
   DrawTooltip в TooltipHost.lua лишь делегирует): карточка radius=8, фон surface,
   тонкая рамка stroke (кастомный self.color сохраняется), выразительная тень 10px;
   интерьерные разделители многоколоночных тултипов сохранены, внешние границы
   карточки в Fluent-ветке не дублируются.

Токены `ThemeFluent.lua` расширены: палитра переименована `color` → `colors`,
добавлены группы `checkbox`, `dropdown` (с `popup`), `scrollbar`; tooltip.shadowBlur
6 → 10; добавлены radius.checkbox/scrollThumb/popup. **Исправлен баг `shade()`**
(при t<0 цвет светлел вместо затемнения — surfacePressed/accentPressed были
неверными с batch-1; тест поймал).

Pre-commit бэкапы: `Snapshots\PoE2-ThemeFluent-20261108-batch2\` (4 контрола +
ThemeFluent.lua). Известный визуальный нюанс: item-header арты (rarity headers,
только при showFlavourText) квадратные и на 8px-скруглении карточки слегка
перекрывают углы — оценено как приемлемое, правка хедера не выполнялась.

Верификация (2026-11-08): синтаксис — luajit loadfile 6/7 OK (Tooltip.lua не
парсится ванильным LuaJIT из-за ПРЕДСУЩЕСТВУЮЩЕГО `+=` в AddBuildPlannerNote —
диалект PoB2 его поддерживает); компиляция всех 7 файлов РОДНЫМ рантаймом PoB2
(runtime/lua51.dll через minimal-host) — 8/8 OK, включая compound_test с `+=`.
Интеграционный харнесс в среде рантайма (заглушки + реальные классы,
`build-SimpleGraphic-Next\smoke\pob2lua\harness_batch2.lua`): **37/37 PASS** —
обе ветки, состояния checked/unchecked/hover/pressed/disabled/drag/open, borderFunc,
геометрия и токены всех DrawControlBox-вызовов. Batch-1 харнесс после рефакторинга
палитры: 25/25 PASS. Важно: глобальные API-функции рантайма (LoadModule и др.)
переопределяются в харнессе свободно; функции-значения индексировать нельзя
(IsKeyDown.force → ошибка).

**ВАЖНО (обновление 2026-11-08, ночь — ВОССТАНОВЛЕНО):** правки `Tooltip.lua`
были восстановлены по спецификации ThemeFluent (radius 8, surface, stroke border,
expressive shadow 10, поддержка мультколонки без дублирования внешних рамок).
Pre-commit бэкап: `Snapshots\PoE2-ThemeFluent-20261108-batch3a\Tooltip.lua.pre-batch3a-20261108`.
Результаты batch-2 харнесса: **37/37 PASS**, batch-3 харнесса: **46/46 PASS**.

## Current goal (сессия 2026-11-08, часть 4: PoB2 — Fluent-тема, пакет 3)

Третья партия в `PathOfBuilding-PoE2` (ветка `dev`, НЕ закоммичено) — каркас
интерфейса: панели, верхний бар, кнопки вкладок, списки.

1. **`src/Modules/Build.lua`** (метод `buildMode:Draw`):
   - Топ-бар: в Fluent-ветке фон `colors.background` (#1F1F21) на 0..31px,
     тонкая разделительная линия 1px `colors.border` (#3E4046) на y=31 (граница
     с рабочим пространством), вертикальный разделитель топ-бара сужен 4px → 1px.
     Legacy-ветка (без DrawControlBox) сохранена байт-в-байт.
   - Сайдбар: Fluent — панель `DrawControlBox(0, 32, 312, …, radius 0, surface,
     без рамки)` на всю ширину 312px (включая зону бывшей белой рамки) + правая
     граница 1px `colors.border` на x=311. Контролы сайдбара (4..304) не сдвинуты.
     Legacy — прежняя чёрная заливка + 4px белая рамка без изменений.
   - Файл-scope: добавлен `local ThemeFluent = LoadModule("Modules/ThemeFluent")`.
2. **`src/Classes/ButtonControl.lua`** (Fluent-ветка): кнопка с `locked == true`
   (активная вкладка — modeTree/Skills/Items/Calcs/Party/Compare/Import/Notes/Config,
   саб-вкладки CompareTab, тумблеры ItemsTab/TreeTab) получает стиль Windows 11
   Segmented: приподнятый фон `button.bgActive` (= surfaceHover), ОБЫЧНАЯ рамка
   stroke (раньше при locked рисовалась акцентная — заменено на индикатор) и
   золотой индикатор-полоска `button.indicator` (accent #D4AF37) 3px вдоль нижней
   кромки с отступом 3px от скруглённых углов. Hover без locked — прежний
   (accent-рамка). Legacy-ветка не тронута (белая подсветка locked как раньше).
3. **`src/Classes/ListControl.lua`**:
   - Рамка списка: Fluent — `DrawControlBox` radius 4, фон `colors.background`,
     рамка 1px `colors.border`; фокус списка → золотая рамка (`list.borderFocus`);
     drag-target — функциональные зелёные цвета сохранены (токены
     `list.dragTargetBg/Border`). Legacy-ветка прежняя.
   - Hover-строка: скруглённая подсветка radius 4, `surfaceHover`, без рамки
     (в координатах viewport, как в DropDown batch-2).
   - Выбранная строка: заливка `surface` (список в фокусе) / `surfacePressed`
     (без фокуса) + акцентный индикатор слева: вертикальная золотая полоска 3px
     (токен `list.rowIndicator`), вертикальный инсет 2px, только в первой колонке
     (colIndex == 1). Выбор приоритетнее hover.
   - `showRowSeparators`: в Fluent вместо зебры — волосяные линии 1px
     `colors.stroke` на нижней кромке каждой строки.
4. **`src/Modules/ThemeFluent.lua`**: палитра дополнена `colors.border` = #3E4046
   (непрозрачные волосяные края панелей/разделителей); в `button` добавлены
   `bgActive`, `indicator`, `indicatorHeight=3`, `indicatorInset=3`; новая группа
   `list` (radius 4, bg/border/borderFocus, rowRadius 4, rowHoverBg, rowSelectedBg,
   rowSelectedBgUnfocused, rowIndicator 3px, rowSeparator, dragTarget-цвета).

Pre-commit бэкапы: `Snapshots\PoE2-ThemeFluent-20261108-batch3\` (Build.lua,
ListControl.lua, ButtonControl.lua, ThemeFluent.lua; SHA256 зафиксированы).

Верификация (2026-11-08): синтаксис luajit loadfile 4/4 OK (Build.lua и
ListControl.lua не содержат `+=`, ванильный LuaJIT их парсит). Интеграционный
харнесс `build-SimpleGraphic-Next\smoke\pob2lua\harness_batch3.lua` в среде
рантайма PoB2: **46/46 PASS** — токены, активная вкладка (fill/border/индикатор
13,36,66,3), idle/hover/disabled/legacy кнопки, рамка списка (#3E4046), hover/
selection/selectionUnfocused/selHover, разделители (5 волосяных линий),
многоколоночный список (2 подсветки ячейки, индикатор 1 раз), drag-target,
legacy-ветки. Регрессия batch-2 харнесса после восстановления Tooltip.lua: **37/37 PASS**. Batch-1 харнесс не содержит assertions на locked-состояние —
изменение индикатора на него не влияет.

Техническая ловушка среды: патченный string.format рантайма PoB2 игнорирует
точность `%.4f` (пишет полную точность с обрезкой нулей: `0.83137254901961`, `1`,
`0.08`) — строковые ожидания в харнессах сверять префиксами или isColor-сравнением.

## Current goal (сессия 2026-11-09, часть 5: PoB2 — Fluent-тема, пакет 4)

Четвёртая партия в `PathOfBuilding-PoE2` (ветка `dev`, НЕ закоммичено) — каркасы,
слайдер, модальные диалоги. Решения владельца зафиксированы в DECISIONS.md (D-013):
SectionControl radius 4; слайдер с золотой заливкой; заголовок попапа на прежней позиции.

1. **`src/Classes/SectionControl.lua`** (групповая рамка с заголовком; отдельного класса
   GroupBoxControl в кодовой базе НЕТ — эту роль выполняет SectionControl): Fluent-ветка —
   карточка DrawControlBox radius 4 (плотная компоновка секций), фон surface, рамка
   stroke 1px, тень 0 (секции стоят вплотную); плашка заголовка — фон surface (сливается
   с карточкой, «legend»-разрыв рамки), текст textPrimary; геометрия плашки и позиция
   текста сохранены (x+6, y-8; текст x+9, y-6). Legacy — байт-в-байт.
2. **`src/Classes/SliderControl.lua`**: Fluent-ветка — трек DrawControlBox radius 3,
   фон background, рамка stroke (hover → strokeHover); АКЦЕНТНАЯ золотая заливка трека
   от левого края до ползунка (x+1..knobX+knobSize/2, clamp width-2); knob — светлый
   круг (radius (knobSize-2)/2 ≤ 16, фон textPrimary), рамка stroke, hover/drag → accent;
   disabled — trackDisabledBg/Border (surfacePressed/strokeDisabled), без fill и knob
   (как в legacy); divCount — тики 2px цветом colors.border + стрелки main:DrawArrow
   (Fluent: arrow=textSecondary / arrowActive=textPrimary; legacy: 0.5/1.0 серый/белый).
   Геометрия взаимодействия НЕ тронута (IsMouseOver/drag считают от x+2, knobSize=height-2).
   Тултип значения — уже тематизированный Tooltip (batch 2).
3. **`src/Classes/PopupDialog.lua`** (единая точка всех модальных диалогов: Options,
   About, Update, OpenMessagePopup/OpenConfirmPopup, диалоги вкладок — через
   main:OpenPopup): Fluent-ветка — карточка DrawControlBox radius 8, фон surface,
   рамка stroke, тень 10 (токены `dialog` из пакета 1 впервые получили потребителя);
   заголовок — БЕЗ белой/чёрной плашки, текст textPrimary на прежней позиции
   (titleX+4, y-7; layout контента попапов не сдвигается). Затемнение фона в Main.lua
   (0,0,0,0.5) не тронуто — соответствует ContentDialog-поведению WinUI. ProcessInput
   (ESC/RETURN) не изменён.
4. **`src/Modules/ThemeFluent.lua`**: новые группы токенов `section` (radius 4, bg,
   border, labelBg, labelText) и `slider` (radius 3, trackBg/trackBorder/trackBorderHover,
   trackDisabledBg/trackDisabledBorder, trackFill=accent, tick=colors.border,
   knob=textPrimary, knobBorder/knobBorderActive, arrow/arrowActive); расширение
   `dialog.title` (textPrimary). Только добавления — токены пакетов 1–3 не менялись.

Явно отложено в Пакет 5: `CalcSectionControl` (секции Calcs-вкладки: data-driven цвета
групп, ячейки значений, overlay-режим с перетаскиванием), `RectangleOutlineControl`
(параметризуется вызывающим кодом — трогать незачем). `TimelessJewelSocketControl` и
`PassiveMasteryControl` наследуют уже тематизированные DropDown/List — работ не требуют.

Pre-commit бэкапы: `Snapshots\PoE2-ThemeFluent-20261109-batch4\` (SectionControl,
SliderControl, PopupDialog, ThemeFluent; SHA256SUMS.txt зафиксирован).

Верификация (2026-11-09): нативная компиляция родным рантаймом PoB2 (host.exe +
test_compile.lua) — 11/11 OK. Интеграционный харнесс
`build-SimpleGraphic-Next\smoke\pob2lua\harness_batch4.lua`: **50/50 PASS** — токены,
обе ветки Section/Slider/Popup, hover/drag/disabled/divCount слайдера, аргументы
DrawControlBox, ESC/RETURN попапа. Регрессия: batch1 25/25 (luajit), batch2 37/37,
batch3 46/46.

Ловушки харнесса (batch4): main:DrawArrow / self:DrawTooltip вызываются через двоеточие —
заглушки обязаны срезать self первым аргументом; 4-аргументный SetDrawColor(1,1,1,1)
нельзя искать findCall-префиксом со скобкой — использовать findSetDrawColor с 4-м
префиксом. Хост (host.exe) непригоден для batch1-харнесса (его os.exit даёт
fail-fast 0xC0000409) — batch1 гонять luajit
(`build-SimpleGraphic-Next\vcpkg_installed\x64-windows\tools\luajit\luajit.exe`).

Примечание: Nowledge Mem CLI в этой сессии недоступен (nmem not found) — решения
пакета 4 зафиксированы в этом файле и в DECISIONS.md (D-013).

## Current goal (сессия 2026-11-09, часть 6: живой тест + PoB2 — Fluent-тема, пакет 5)

Между пакетами 4 и 5 — живое тестирование владельцем (итоги сообщены владельцем):

1. **DLL с `DrawControlBox` развернута** в `PathOfBuilding-PoE2/runtime/SimpleGraphic.dll`
   (modified, не закоммичено) — Fluent-ветки тепер активны в живом приложении.
2. Исправления, выявленные живым запуском:
   - `Tooltip.lua`: убран вызов несуществующей `DrawColorFromEscape` (заменен на
     нативный `SetDrawColor`/`GetDrawColor`).
   - `Tooltip.lua`: для карточек предметов и камней (`self.tooltipHeader`) возвращен
     аутентичный глубокий полупрозрачный фон rgba(0,0,0,0.88) radius 4 — не глушить
     игровой арт/иллюстрации гемов; обычные UI-тултипы остались на `ThemeFluent.tooltip`.
   - `SliderControl.lua`: вызов DrawControlBox для заливки трека дополнен недостающими
     аргументами `nil, 0, 0` (граница/ширина/тень).
3. Харнессы batch2/3/4 перепроверены после правок: 37/37, 46/46, 50/50.

### Пакет 5: CalcSectionControl (секции вкладки Calcs)

В `PathOfBuilding-PoE2` (ветка `dev`, НЕ закоммичено):

1. **`src/Classes/CalcSectionControl.lua`**:
   - Карточка секции (Draw): Fluent — DrawControlBox radius 4, фон surface, рамка
     stroke 1px, тень 0 (секции стоят колонкой). Legacy — двойная рамка цветом группы
     (`self.colour` = escape-код colorCodes.OFFENCE/DEFENCE/…) + чёрная заливка,
     байт-в-байт.
   - Контент (DrawContent): топ/боттом линии заголовков подсекций и вертикальные бары
     ячеек СОХРАНЯЮТ групповой цвет `self.colour` (функциональная идентификация
     offense/defence/…), но в Fluent утончаются 2px → 1px (`lineWeight`). Заливки
     `rowData.bgCol` (MAINHANDBG/OFFHANDBG — данные) сохранены без изменений в обеих
     ветках.
   - Подсветка ячеек (WinUI 3): временная displayData (следует за курсором) —
     скруглённая белая вуаль 8% (radius 3) поверх bgCol-заливки; закреплённая
     (`displayPinned`) — золотая вуаль accent 22% + акцентный индикатор-бар 3px
     (вертикальный инсет 2px). Legacy-зелёная подсветка (0.25,1,0.25 + bgCol-инсет)
     сохранена в legacy-ветке.
   - Overlay-панель (DrawOverlay): Fluent — карточка radius 6, фон surface @0.97,
     рамка stroke 1px, тень 6; при перетаскивании (`self.dragging`) рамка становится
     accent-золотой; хедер-полоса surfaceHover, разделитель под хедером colors.border;
     крестик закрытия (DrawImageQuad) не тронут. Legacy — прежний чёрный фон 0.95,
     4 линии-рамки цветом группы, серый хедер 0.18.
2. **`src/Modules/ThemeFluent.lua`**: новая группа токенов `calcSection` (radius 4,
   cellRadius 3, cellHoverBg = white 8%, cellSelectedBg = accent 22%, cellIndicator,
   overlayRadius 6, overlayShadow 6, overlayBg = surface 0.97, overlayBorderDrag,
   overlayHeaderBg, overlaySeparator). Только добавления.

Pre-commit бэкапы: `Snapshots\PoE2-ThemeFluent-20261109-batch5\` (CalcSectionControl,
ThemeFluent; SHA256SUMS.txt).

Верификация (2026-11-09): нативная компиляция (host.exe + test_compile.lua) — 12/12 OK.
Харнесс `harness_batch5.lua`: **40/40 PASS** — токены, карточка, 1px линии/бары,
bgCol-заливки, hover/pinned подсветка, hover-report SetDisplayStat, overlay (idle/drag/
legacy). Регрессия: batch1 25/25 (luajit), batch2 37/37, batch3 46/46, batch4 50/50.

Примечание по дизайну: нейтральная карточка (surface+stroke) + сохранение группового
цвета на внутренних линиях — компромисс «WinUI-карточка + функциональная
цветокодировка Calcs»; если владелец захочет полную нейтрализацию — токен не нужен,
достаточно заменить `self.colour` на `ThemeFluent.calcSection.border` в DrawContent.

## Current goal (сессия 2026-11-09, часть 7: SimpleGraphic-Next — Win11 натив: Mica + тёмный заголовок)

Задача в `PathOfBuilding-SimpleGraphic-Next` (ветка `feat/modern-runtime`,
отдельный Git-root; `PathOfBuilding-SimpleGraphic` не тронут). Изменения НЕ закоммичены.

**Отправная точка**: обнаружен коммит владельца `a926ea5` (2026-11-07)
«feat(winui3): enable Windows 11 Mica backdrop and immersive dark titlebar» —
уже сделаны: линковка `dwmapi.lib` (CMakeLists), `DWMWA_USE_IMMERSIVE_DARK_MODE`=TRUE
и `DWMWA_SYSTEMBACKDROP_TYPE`=DWMSBT_MAINWINDOW при старте окна в `Apply()`
(прямая линковка, `engine/system/win/sys_video.cpp`). Дельта задачи выполнена поверх:

1. **`engine/system/sys_video.h`** (+9): enum `sys_backdrop_e`
   (SYS_BACKDROP_NONE/MICA/MICA_ALT) и два чисто виртуальных метода интерфейса
   `sys_IVideo`: `SetDarkMode(bool)`, `SetBackdrop(int)` (bool-результат).
2. **`engine/system/win/sys_video.cpp`** (+84):
   - define-константы `DWMWA_WINDOW_CORNER_PREFERENCE`(33)/`DWMWCP_ROUND`(2);
   - helper `IsWindowsBuildAtLeast(DWORD)` через `RtlGetVersion` (ntdll, GetProcAddress —
     независимо от манифеста);
   - при старте окна в `Apply()` добавлен corner preference `DWMWCP_ROUND`
     (молча игнорируется на Win10; Mica-gate тоже добавлен комментарием);
   - реализации: `SetDarkMode` — DWMWA 20 (Win10+); `SetBackdrop` — gate build ≥ 22621
     (Win11 22H2), маппинг None→DWMSBT_NONE(1)/Mica→DWMSBT_MAINWINDOW(2)/
     MicaAlt→DWMSBT_TABBEDWINDOW(4), возвращает SUCCEEDED(HRESULT).
3. **`ui_api.cpp`** (в составе +112 суммарно с незакоммиченным D-012): Lua API
   `SetWindowDarkMode(dark)` (assert на boolean) и
   `SetWindowBackdrop("None"|"Mica"|"MicaAlt")` (`luaL_checkoption`, возвращает
   boolean — false вместо ошибки на неподдерживаемых системах); строки документации
   API-шапки; регистрация `ADDFUNC` рядом с SetWindowTitle.
4. **`PathOfBuilding-PoE2/src/_SimpleGraphic.def.lua`**: EmmyLua-аннотации обеих
   функций (SetWindowBackdrop задекларирован с `@return boolean applied`).

Технические решения: прямая линковка dwmapi сохранена (лад владельца в a926ea5),
динамическая загрузка не понадобилась; gate 22621 ТОЛЬКО для backdrop (dark mode
работает с Win10 1809+, corner preference безопасно игнорируется старым DWM);
`SetWindowBackdrop` возвращает false вместо Lua-ошибки — скрипты не обязаны проверять
ОС; дефолт при старте остался от a926ea5 (dark=TRUE + Mica) + добавлен round corners.

Ограничение (задокументировано): клиентская область GLFW/ANGLE-окна непрозрачна
(обычный swapchain), поэтому Mica видна на DWM-рамке и заголовке; в клиентской зоне
фон задаёт приложение (SetClearColor/DrawImage). Полупрозрачный клиент под Mica —
отдельная задача (extend frame / DwmExtendFrameIntoClientArea + прозрачный клир).

Верификация (2026-11-09): сборка цели SimpleGraphic RelWithDebInfo/x64 EXITCODE 0
(cmake из VS 18 BuildTools, не в PATH — полный путь в CURRENT_STATE); DLL
`B24BC3F9…` развернута в `build-SimpleGraphic-Next\smoke\` (бэкап прежней
`SimpleGraphic.dll.before-win11-20261109`). Дымовой тест `smoke\test_win11.lua`
через host.exe: EXITCODE 0, 4/4 PASS (API presence, toggle без ошибок, backdrop
boolean для всех значений), Mica/MicaAlt/None = true (машина ≥ 22H2), 5 кадров,
скриншот `smoke\SimpleGraphic\Screenshots\110926_013707.png` (клиентская зона
рендерится, DrawControlBox поверх работает; DWM-эффекты требуют живой визуальной
проверки владельцем). def.lua: luajit loadfile OK.

Pre-commit бэкапы: `Snapshots\SimpleGraphic-Next-20261109-win11\` (sys_video.h,
sys_video.cpp, ui_api.cpp, _SimpleGraphic.def.lua; SHA256SUMS.txt).

В `PathOfBuilding-PoE2\runtime\` новая DLL НЕ развернута — развертывание и живая
проверка за владельцем. Часть 2 (нативный стиль): потенциально акриловая
полупрозрачность/цвет заголовка Lua-настройка — в следующих сессиях.

## Current goal (сессия 2026-11-09, часть 8: PoB2 — Fluent-пакет 6: динамика попапов, полиш, Light Theme)

В `PathOfBuilding-PoE2` (ветка `dev`, НЕ закоммичено) — по итогам живого тестирования
владельца (баг layout попапов + «тяжёлый» перегруженный UI):

1. **Динамическое позиционирование диалогов (баг-фикс)**:
   - `src/Classes/PopupDialog.lua`: x/y-функции попапа центрируются по живым
     `main.screenW/H` (было и так) с КЛАМПОМ от отрицательных координат:
     `m_max(0, m_floor((main.screenW - self:GetSize()) / 2))` — при уменьшении окна
     ниже размера диалога тот прижимается к левому/верхнему краю вместо улёта за
     экран (Options: height = screenH-20, зафиксированный на момент открытия, давал
     отрицательный y). Размер берётся через `self:GetSize()` — корректно и для
     resizeFunc-диалогов.
   - `src/Modules/Build.lua` (Similar Builds resizeFunc): перезаписываемая y-функция
     тоже получила `m_max(0, ...)` — иначе кламп конструктора перетирался.
2. **Облегчение визуального шума** (`src/Modules/ThemeFluent.lua`): новая палитровая
   константа `strokeSoft` (Dark: white 5%, Light: black 7%) для рамок карточек —
   `section`, `calcSection` (+overlayBorder), `card`, `tooltip`, `dialog`. Интерактивные
   контролы (button/edit/checkbox/dropdown + dropdown.popup) сохраняют обычный
   `stroke` (Dark 8%) — им нужна читаемость. `list.border` НЕ тронут (#3E4046 opaque).
   Внутренние отступы — layout-уровень (не тема), не менялись.
3. **Светлая тема**: палитры вынесены в `local palettes = { Dark, Light }`;
   `Theme.colors` указывает на активную; резолв токенов — функция `Resolve(theme)`,
   вызывается при загрузке (Dark) и в `SetTheme`. Light (Windows 11 Light):
   background #F3F3F3, surface #FFFFFF, stroke black 10%, strokeSoft black 7%,
   border #E5E5E5, accent #9E7D1E (золото, затемнённое под светлый фон),
   textPrimary #1B1B1B, textSecondary #5C5C5C; палитровые детали: checkbox.check
   (Dark #1F1F21 / Light #FFFFFF), scrollbar.thumb (white/black альфы),
   veil для calcSection (Dark white 8% / Light black 5%), cellSelected, overlay
   (Dark #292B30@0.97 / Light #FFFFFF@0.97). Функциональные drag-target-зелёные
   сохранены в обеих палитрах.
   **API**: `ThemeFluent:SetTheme("Dark"|"Light")` → bool (неизвестное имя — false,
   no-op при том же имени), `ThemeFluent:GetTheme()`. При РЕАЛЬНОМ переключении
   вызывается рантаймная `SetWindowDarkMode(theme == "Dark")` (guard по типу —
   на старой DLL просто пропускается) — системный заголовок окна синхронен.
4. **Переключатель в Options** (`src/Modules/Main.lua`): file-scope
   `local ThemeFluent = LoadModule(...)`; LoadSettings парсит атрибут `uiTheme`;
   SaveSettings пишет `uiTheme = self.uiTheme`; применение при старте —
   `ThemeFluent:SetTheme(self.uiTheme or "Dark")` в `ChangeUserPath` после
   `LoadSettings`; в Options (после DPI override) добавлен DropDown «UI Theme:
   Dark/Light» (onchange: `self.uiTheme = value.theme; ThemeFluent:SetTheme(...)`,
   tooltip; SelByValue по "theme"); savedState дополнен `uiTheme`; Cancel
   восстанавливает сохранённую тему (переключение применяется live).

Pre-commit бэкапы: `Snapshots\PoE2-ThemeFluent-20261109-batch6\` (PopupDialog, Main,
ThemeFluent, Build; SHA256SUMS.txt).

**Обновления ожиданий старых харнессов** (сознательные изменения дизайна, не подгонка):
смягчение рамок 0.08 → 0.05 сломало ассерты границ секций/карточек — обновлены:
batch2 (tooltip border), batch4 (theme.section + section/popup fluent borders),
batch5 (calcSection card/overlay borders). Всё остальное в этих харнессах не тронуто.

Верификация (2026-11-09): нативная компиляция — 14 файлов OK (включая Main.lua,
Build.lua с диалектными `+=`). Новый `harness_batch6.lua`: **38/38 PASS** — палитры,
SetTheme/GetTheme (вкл. invalid/no-op), SetWindowDarkMode-синк, strokeSoft/старый
stroke распределение, Light-пересчёт всех токенов, центрирование+кламп попапа
(5 сценариев ресайза, реальные классы Control/ControlHost/PopupDialog), Draw попапа
обеих веток. Регрессия: batch1 25/25 (luajit), batch2 37/37, batch3 46/46,
batch4 50/50, batch5 40/40.

Примечание: Light-палитра по умолчанию НЕ активна — Dark остаётся дефолтом
(`self.uiTheme or "Dark"`). Для живой проверки: Options → UI Theme → Light.
Скриншоты клиента при Light-теме желательны от владельца (контрасты ячеек Calcs
с data-driven bgCol на белом — целевая проверка).

## Previous session (2026-11-07): SimpleGraphic T0–T4

Ниже — итоги предыдущей сессии в `PathOfBuilding-SimpleGraphic` (ветка `i18n-unicode-test`).

## Previous goal

Передача работы от ChatGPT-сессии выполнена: план модернизации SimpleGraphic сохранён,
верифицирован и зафиксирован. Этап T0 выполнен (коммит `4fc1707`).

## Completed

- Изучены `reports/IDE_TRACE_LATEST.md`, `docs/ai/`, Nowledge Mem Space `pob2fork`.
- Git-статус всех 5 компонентов проверен (трижды за сессию, включая перед коммитом).
- Верифицированы находки аудита ChatGPT по локальным исходникам (детали в §8 плана):
  - P0 подтверждён: `r_tex_c::LoadFile()` error path (`r_texture.cpp:604-607`) вызывает
    `Upload()` → `glGenTextures` из worker thread.
  - P1-2 частично закрыт локально: `EncodeCodepointUTF8` + `CallCharHandler`;
    остался IME (`OnPreedit`/`SetIMECaretRect`).
  - P1-3 подтверждён: `textBuffer_c::KeyEvent` (`common.cpp:118-181`) побайтовый.
- Прочитаны upstream PR: #114 (open), #116 (open), #119 (merged 2026-09-09, breaking Lua API).
- Создан план: `reports/SimpleGraphic_Modernization_Plan_for_OpenCode.md`.
- **T0 выполнен**: дифф SimpleGraphic (5 файлов) закоммичен как `4fc1707` на
  `i18n-unicode-test`; пред-коммитный patch (232 КБ) и hunk-map сохранены в
  `Snapshots\SimpleGraphic-T0-20261107\`; backup-файлы `r_font.*.backup-20261107-*`
  перемещены туда же (SHA256 сверены перед удалением из репо).
- В диффе обнаружен незадокументированный зачаток font fallback на stb_truetype
  (`LoadTtfFace`, `RasterizeGlyph`, `LoadEmojiFallbackFont`) и фикс null-deref
  `r_tex_c` (upstream #112) — отражено в плане (T4) и D-010.
- **T1 выполнен и закоммичен** (`c0b92da`): порт upstream PR #116 в `r_texture.cpp`
  дословно (+10 строк): при `TF_ASYNC` failed-load fallback ставит placeholder в
  `EnqueueTextureUpload` (GL-работа только в главном потоке), sync-путь не изменён.
  Бэкап: `Snapshots\SimpleGraphic-T1-20261107\r_texture.cpp.pre-T1`.
- **T3 выполнен и закоммичен** (`f7d331e`, 82+/14−, только `common.cpp`): `textBuffer_c`
  переведён на UTF-8 — стрелки/Backspace/Delete по границам кодпоинтов, `KE_CHAR`
  вставляет UTF-8 (раньше обрезал codepoint до байта), устранён OOB-read на 1 байт в
  старом цикле сдвига. Верификация: standalone-харнесс против реального `common.cpp`
  (36 проверок, все прошли) + сборка EXITCODE 0 + дымовой запуск.
- **T4 выполнен и закоммичен** (`ae1d2a9`, +49/−9, `r_font.cpp`): Unicode-кэш глифов
  ограничен LRU (256/высота) с вытеснением холодных текстур; D-011 (stb_truetype
  остаётся растеризатором). Найдена и локально устранена дыра деплоя: TTF-fallback был
  мёртв (отсутствующий Noto otf в UnicodeFallback.tgf) → локально переключено на
  `segoeui.ttf`. Сборка EXITCODE 0, дымовой запуск OK.
- Документация обновлена: CURRENT_STATE.md, DECISIONS.md (D-010, D-011),
  SESSION_HANDOFF.md, план.
- Решения сохранены в Nowledge Mem Space `pob2fork`.

## In progress

- Незавершённых операций нет. Рабочие деревья чисты. История `i18n-unicode-test`:
  `c062b29` → `4fc1707` (T0) → `c0b92da` (T1) → `f7d331e` (T3) → `ae1d2a9` (T4) →
  `2e45654` (BOM-толерантность конфигов шрифтов + guard от краша пустого шрифта).
- Инцидент при тесте «полный Noto»: конфиги, записанные PowerShell 5.1, получили UTF-8
  BOM → конструктор шрифта не увидел '{' → 0 высот → access violation в FindFontHeight
  (fontHeights[-1]) при отрисовке билда. Исправлено: конфиги перезаписаны без BOM;
  в движок добавлены StripUtf8Bom на всех путях чтения .tgf и null-guard в
  FindFontHeight/StringWidth/StringCursorIndex/DrawTextLine (край ≤31 строка).
  Урок: PowerShell 5.1 UTF8 = с BOM (ломает и .tgf, и pob2.ps1 — запускать через pwsh).
- T2 (Windows IME) спроектирован, но осознанно отложен: требует Lua-стороны PoB2
  (аналог upstream PR #10195) и интерактивной проверки реальным IME — в автоматическом
  режиме непроверяемо. Контракт-ориентир: `OnPreedit` + `SetIMECaretRect` из PR #114.

## Repository state

- PathOfBuilding-SimpleGraphic: `i18n-unicode-test` @ **`4fc1707`**, рабочее дерево clean,
  untracked отсутствуют. Ветка не пушится.
- PathOfBuilding-PoE2: `dev` @ bb52d6b36; tracked clean; untracked: `AGENTS.md`, `CLAUDE.md`,
  `GEMINI.md`, `.github/copilot-instructions.md`, `docs/ai/`, `tools/pob2.ps1`.
- RePoE: `master` @ aa9fa7c3; M: `parser/poe2/{base_items,buffs,mods,passives,stat_translations}.py`,
  `parser/util.py`.
- PyPoE: `dev` @ 66d1d74, clean. PathOfExile_Translated: `main` @ a5844de, clean.
- Снапшоты сессии: `Snapshots\SimpleGraphic-T0-20261107\` (patch, hunk-map, backup-файлы),
  `Snapshots\docs-ai-20261107-*` (исходные SESSION_HANDOFF/CURRENT_STATE).

## Important findings

- Upstream PR #119 (merged 2026-09-09, `fe7851e`) удаляет BlendMode/mask index из Lua API —
  breaking change при будущей синхронизации (локальный HEAD его не содержит).
- Нормализация EOL в `4fc1707` (CRLF→LF): диффы с upstream снимать с `--ignore-cr-at-eol`.
- P0-патч мал (~10-15 строк, порт PR #116); PR #114/#116 открыты — не мерджить слепо.
- Windows IME не покрыт upstream (PR #114 macOS-only) — T2 проектировать самостоятельно
  по контракту `OnPreedit`/`SetIMECaretRect`.

## Next actions

1. T5: синхронизация с upstream — gap **25 коммитов** (PR #119 breaking Lua API,
   PR #120 C++23 bump), локально впереди на 4. Отдельная сессия, отдельная ветка,
   полный smoke-тест + проверка потребителей BlendMode/mask index в PoB2.
2. T2: Windows IME — согласовать Lua-контракт (`OnPreedit`, `SetIMECaretRect`) с
   PoB2-приложением, затем реализовать в движке (WndProc subclassing, Imm32) и
   проверить интерактивно с реальным IME. Низкий приоритет: кириллица уже работает.
3. Ручная проверка вытеснения LRU (>256 уникальных глифов на высоту, напр. CJK-текст).
4. Портабельность fallback-конфигов: `UnicodeFallback/EmojiFallback.tgf` отсутствуют
   в репо PoE2 (в поставку нужен свободный шрифт — Noto/DejaVu, не Segoe из-за лицензии).

## Validation

- Коммит `4fc1707` проверен `git log -1 --stat` и `git status` (дерево чисто).
- Перенос backup-файлов подтверждён сверкой SHA256 до удаления оригиналов.
- Пред-коммитный дифф сохранён как patch-файл (232 324 байта) в Snapshots.
- Целостность коммита: `git diff HEAD~1 HEAD --ignore-cr-at-eol` = 468+/78− — совпадает с
  пред-коммитным замером; потери контента при нормализации EOL нет.
- Сборка: MSBuild (VS 18 BuildTools), `ALL_BUILD.vcxproj`, RelWithDebInfo/x64, каталог
  `build-SimpleGraphic-i18n-relocated` — EXITCODE 0, все цели собраны
  (SimpleGraphic.dll, cmp_core, imgui, lcurl, lua-utf8, socket, lzip).
- DLL: свежесобранный `RelWithDebInfo\SimpleGraphic.dll` SHA256 `261A9930528A…` побайтово
  совпадает с развёрнутым `PathOfBuilding-PoE2-Unicode-Test\runtime\SimpleGraphic.dll`
  (2:32:23) — deployed runtime == сборка закоммиченного кода.
- Дымовой запуск Unicode-Test (20 с): окно "Unnamed build (Ranger) - Path of Building (PoE2)",
  процесс жив, остановлен чисто — загрузка движка, Lua-бут и UI работают.
- T1: пересборка `SimpleGraphic.vcxproj` EXITCODE 0 (r_texture.cpp перекомпилирован);
  дымовые запуски с новой DLL — жив 20/30/35 с, модальных диалогов нет (EnumWindows);
  **A/B-тест** (T1 DLL vs `.before-T1` на одинаковом состоянии) — поведение идентично,
  «голый» заголовок окна в обоих прогонах — эффект состояния тест-развёртывания
  (принудительные остановки сбросили last-opened-build), не регрессия T1.
- DLL с T1-фиксом (`C9EBC02E2258…`) задеплоена в Unicode-Test runtime; бэкап прежней:
  `SimpleGraphic.dll.before-T1-20261107-191620`.
- T3: standalone-харнесс (`cl /std:c++17` против реального `common.cpp`) — 36/36 проверок:
  вставка кириллицы/CJK/эмодзи через `KE_CHAR`, границы кодпоинтов в стрелках,
  BACK/DELETE целыми символами, ASCII-регрессия, escape-прыжки, U+FFFD, NUL-терминатор.
  Первый прогон отловил ОШИБКУ ОЖИДАНИЙ самого теста (семантика BACK — удаляет кодпоинт
  ПЕРЕД кареткой), не кода; ожидания исправлены, прогон полностью пройден.
- T3: сборка EXITCODE 0; DLL (`B1A3456C2FEE…`) задеплоена в Unicode-Test с бэкапом
  `SimpleGraphic.dll.before-T3-20261107-200744`; дымовой запуск OK (20 с).
- Тест-харнесс сохранён вне репозиториев:
  `C:\Users\dexox\AppData\Local\Temp\opencode\sg-t3-test\test_t3.cpp`.
- T4: сборка EXITCODE 0 (r_font.cpp перекомпилирован); дымовой запуск OK; путь вытеснения
  LRU (>256 уникальных глифов) в рантайме не прогонялся — см. Next actions.
  Деплой: DLL `60F5F90763B9…` в Unicode-Test; UnicodeFallback.tgf → segoeui.ttf
  (бэкап `UnicodeFallback.tgf.before-T4-20261107-203640`).
- T5 разведка: `git fetch origin` выполнен (без изменений дерева);
  `i18n-unicode-test..origin/master` = 25 коммитов, `origin/master..i18n-unicode-test` = 4.
- **Ручная проверка владельцем (2026-11-07, вечер): ПРОЙДЕНА.** Приложение запущено на DLL
  со всеми изменениями T0–T4 + живой TTF-fallback (segoeui.ttf); владелец подтвердил:
  «вроде всё работает нормально» (ввод кириллицы, отрисовка, редактирование).

## 10. Пакет 7 (Batch 7): Выбор шрифта (UI Font) и акцентного цвета (Accent Color) в Options (2026-11-09)

### Что сделано
1. **Модуль `src/Modules/UIFont.lua`:**
   - Пресеты:
     - `authentic` ("PoE2 Authentic (Fontin)") — аутентичные шрифты игры (Fontin, Fontin SmallCaps, Fontin Italic, Liberation Sans) с Unicode-fallback (Noto Sans) для кириллицы/CJK.
     - `noto` ("Modern Sans (Noto Sans)") — чистый современный sans-serif (Noto Sans SC), сквозным образом перенаправляющий ВСЕ слоты интерфейса: VAR, VAR BOLD, FONTIN, FONTIN SC, FONTIN ITALIC, FONTIN SC ITALIC. Bitstream Vera Mono (консоль) остаётся нетронутым.
   - Безопасное управление дисковыми `.tgf` конфигурациями с автоматическим созданием резервных копий `.authentic-bak`.
   - Idempotent sync при запуске приложения (`UIFont.Sync`).
2. **Палитры акцента в `src/Modules/ThemeFluent.lua`:**
   - 4 цветовые схемы: `PoE2 Gold` (#D4AF37), `Fluent Blue` (#0078D4), `Crimson` (#D13438), `Emerald` (#107C41).
   - Живое переключение `ThemeFluent:SetAccent(name)` без перезапуска.
   - Синхронизация состояния через `_G.__THEME_FLUENT_SHARED__` для всех модулей и контролов.
3. **Интерфейс и настройки в `src/Modules/Main.lua`:**
   - DropDown "UI Font" и "Accent Color" в секции `Application options`.
   - Защита диалога `Options` от вылета за границы при изменении размера окна (`resizeFunc` сохраняет значения новых полей `uiFont` и `uiAccent`).
   - Диалог подтверждения перезапуска при смене шрифта.
   - Персистентность в `Settings.xml` (`uiFont`, `uiAccent`).

### Результаты верификации
- `harness_batch7.lua`: **80/80 PASS** (luajit и host.exe; харнесс адаптирован
  к 6 слотам шрифтов).
- Проверка на реальных файлах в песочнице Fonts: **14/14 PASS** — TTF-конфиги
  пишутся без BOM (BOM ломает разбор `.tgf` в рантайме), бэкапы `.authentic-bak`
  содержат оригинальные байты, откат на `authentic` — byte-exact.
- Синтаксис `Main.lua`, `ThemeFluent.lua`, `UIFont.lua`: 100% PASS.

## 11. Window State Persistence: сохранение геометрии окна (2026-11-09)

### Что сделано
1. **Движок `PathOfBuilding-SimpleGraphic-Next` (ветка `feat/modern-runtime`):**
   - `sys_IVideo`: +7 методов (`GetWindowPos`, `SetWindowPos`, `GetWindowSize`,
     `SetWindowSize`, `IsMaximised`, `SetMaximised`, `GetMonitorBounds`).
   - `engine/system/win/sys_video.cpp`: реализация через GLFW;
     `GetMonitorBounds` — объединение всех подключённых мониторов.
   - `ui_api.cpp`: 7 функций Lua API + `ADDFUNC` + doc-строки.
2. **Lua-слой `PathOfBuilding-PoE2` (ветка `dev`):**
   - Новый `src/Modules/WindowState.lua` (чистая логика, тестируется без окна).
   - `Main.lua`: чтение/запись `windowX/windowY/windowWidth/windowHeight/
     windowMaximized` в `<Misc>`; `main:ApplyWindowState()` в `main:Init()`
     и `main:ChangeUserPath()`; запись состояния в `main:SaveSettings()`.
   - `_SimpleGraphic.def.lua`: сигнатуры 7 новых функций.
3. **Guard check:** минимум 64 px видимой части окна; полностью за экраном →
   центрирование; частично → подтягивание; размер клампится по виртуальному
   рабочему столу; минимальный размер 1080×720 задаёт движок.

### Результаты верификации
- `harness_batch8.lua`: **60/60 PASS** (luajit и host.exe).
- Живой smoke `smoke/test_windowstate.lua`: **17/17 PASS**.
- Живой прогон PoB2: обычное восстановление, out-of-bounds (центрирование),
  maximized — подтверждены; приложение само пишет атрибуты при выходе.
- Сборка RelWithDebInfo/x64 — EXITCODE 0; DLL SHA256 `D6B95179…` развёрнута
  в `runtime\` и в smoke.
- Решения — DECISIONS.md D-018.

## 12. Quick Import по Clipboard (Ctrl+V), чистый Lua (2026-11-10)

### Что сделано
1. **`src/Modules/BuildList.lua` (`listMode:OnFrame`, блок `Ctrl+V`):**
   перед логикой `copyBuild`/`cutBuild` добавлена проверка буфера обмена:
   тримминг краёв, эвристика «похож на PoB-код» (длина > 20 и base64url-
   алфавит `A-Za-z0-9+/=_-`) либо `^https?://`. При совпадении —
   `main:SetMode("BUILD", false, "Imported build")` +
   `main.pendingClipboardImport = trimmed`; copy/cut пропускается через
   флаг `quickImportHandled` (вместо `return` — кадр дорисовывается).
2. **`src/Modules/Build.lua`:** `buildMode:Init` подхватывает
   (`viewMode = "IMPORT"`, фокус на `importCodeIn`,
   `SetText(code, true)`). Буфер → Import Tab, без автоимпорта.
3. **`src/Classes/ImportTab.lua`:** публичный
   `ImportTabClass:QuickImportFromClipboard()` (тримминг, `SetText(trimmed,
   true)`, возвращает `importCodeValid`) и перехват `Ctrl+V` в `Draw`, когда
   фокус не на Edit-контроле (проверка `self.selControl` + `_className`, а не
   `IsMouseOver` — см. отклонение в D-019 п.4).
4. **Снапшот до правок:** `Snapshots\PoE2-QuickImport-20261109\`
   (BuildList.lua, Build.lua, ImportTab.lua).
5. **Харнесс:** `build-SimpleGraphic-Next\smoke\pob2lua\
   harness_batch9_quickimport.lua` + `run_batch9_quickimport.lua`;
   результаты: `batch9_quickimport_results.txt`.

### Результаты верификации
- `harness_batch9_quickimport.lua` (host.exe): **67/67 PASS** —
  эвристика base64url/URL (pastebin, pobb.in), негативные кейсы (обычный
  текст, пути, ftp://, короткие строки), приоритет PoB-кода над armed
  copyBuild/cutBuild (и обратно для обычного текста), hand-off
  (`Init` принять/очистить, `OnFrame` применить один раз), статические
  wiring-проверки трёх файлов и их компиляция через loadfile.
- Классическая вставка файлов билдов (`copyBuild`/`cutBuild`) не задета:
  при не-PoB буфере поведение идентично прежнему.
- Коммиты не выполнялись; изменения легли поверх незакоммиченного пакета
  7 + Window State в ветке `dev`.

- Решения — DECISIONS.md D-019.

## 13. Compact Tooltips & Auto-Compare (2026-11-10)

### Что сделано
1. **`src/Modules/Main.lua`:** Boolean-опция `main.compactTooltips`
   (default false): Init-дефолт, чтение `node.attrib.compactTooltips` в
   LoadSettings, запись в SaveSettings; CheckBox `^7Compact Item Tooltips:`
   в Options (Build-related section) с ALT-подсказкой; entry в
   savedState / currentState (resize-переоткрытие) / controls.cancel.
2. **`src/Classes/ItemsTab.lua` (`AddItemTooltip`):** локальный
   `isCompact = main.compactTooltips`, инверсия при `IsKeyDown("ALT")`;
   шрифты 13/15/18; разделители через `sepGapDefault/Large/Header`
   (10→4, 14→6, 30→8; 18 call sites внутри функции, заменены скриптом
   по диапазону якорей `AddItemTooltip`..`CreateUndoState`); флейвор-текст
   скрыт (lookup сохранён ради `itemOrigin`); суффикс «(Not supported…)»
   и Tip «Hold Shift … granted skill» скрыты в компактном режиме.
3. **`src/Classes/ItemsTab.lua` (compare):** в компактном режиме для
   многоместных семейств слотов («Ring», «Weapon») выбирается один слот:
   - без SHIFT в списке/БД: Slot 1 («Ring 1», «Weapon 1»); с SHIFT: Slot 2
     («Ring 2», «Weapon 2» = Off Hand);
   - при ховере экипированного предмета на персонаже: по умолчанию исходный
     слот, с SHIFT — парный слот;
   - Swap-варианты следуют за active weaponSet.
   - Снапшот фикса: `Snapshots\PoE2-CompactTooltips-ShiftFix-20261110\`.
4. **`src/Modules/Build.lua`:** `AddStatComparesToTooltip` вычисляет
   isCompact (опция XOR ALT) и передаёт в `CompareStatList(..., compact)`
   для player-списка; minion-список остаётся полным. `CompareStatList`
   с compact=true фильтрует по `COMPACT_KEY_STAT_LABELS` (Full DPS,
   Combined DPS, Total Life, Energy Shield, Effective Hit Pool, Fire/Cold/
   Lightning/Chaos Resistance) и префиксует дельты стрелками
   `^2▲ +X` / `^1▼ -X` (стрелка = знак дельты, цвет строки = прежняя
   семантика лучше/хуже). TreeTab идёт через ту же функцию → compare-тултипы
   дерева тоже компактные; собственная копия в `CompareEntry.lua`
   (CompareTab) не тронута.
5. **Снапшот до правок:** `Snapshots\PoE2-CompactTooltips-20261110\`
   (Main.lua, Build.lua, ItemsTab.lua).
6. **Харнесс:** `harness_batch10_tooltips.lua` + `run_batch10_tooltips.lua`;
   результаты `batch10_tooltips_results.txt`.

### Результаты верификации
- `harness_batch10_tooltips.lua` (host.exe): **67/67 PASS** — ALT-инверсия
  (4 комбинации), settings round-trip, компактная фильтрация статов и
  стрелки (ключевой набор извлекается из Build.lua live — дрифт исключён),
  SHIFT-фамильный выбор (default Slot 1, SHIFT Slot 2, hover equipped slot),
  статические wiring-проверки (Init/Load/Save/Options/savedState/cancel/currentState;
  14×10→4, 3×14→6, 1×30→8 сепараторов; флейвор/суффикс/Tip; семейства),
  компиляция 3 файлов.
- Существующее поведение в полном режиме не задето (мэппинг верифицирован:
  normal-режим выводит все дельты без стрелок).
- Коммиты не выполнялись.

### Открытые вопросы
- Живая проверка владельцем: чекбокс в Options + сохранение, ALT при
  наведении на предмет, стрелки/фильтр на реальных билдах, SHIFT для
  колец и оружия; рендер глифов ▲/▼ (U+25B2/U+25BC) во FONTIN SC/Noto.
- Nowledge Mem: D-020 сохранена в Space `pob2fork` (memory `44e10386`); встроенные nowledge_mem-инструменты OpenCode в этой сессии падали («nmem CLI not found»), запись сделана напрямую через CLI `nmem` (см. D-019).
- Решения — DECISIONS.md D-020.

## 15. Фиксация наработок в Git (Коммиты D-017..D-021, 2026-11-11)

### Что сделано
По прямому решению владельца все накопленные и проверенные изменения зафиксированы в Git:

1. **`PathOfBuilding-SimpleGraphic-Next` (ветка `feat/modern-runtime`):**
   - Коммит `ce32002`: `feat(engine): DrawControlBox SDF rendering, font fallback chain, SetIndexedColor and window geometry APIs`
   - Зафиксированы 11 файлов: SDF скругления/тени `DrawControlBox`, fallback-цепочка гарнитур, мутабельный `colorEscape[10][3]` (`SetIndexedColor`), API геометрии окна (`Get/SetWindowPos`, `Get/SetWindowSize`, `Is/SetWindowMaximized`, `GetMonitorBounds`), `.gitignore` (`/runtime/`).
   - Рабочее дерево: clean.

2. **`PathOfBuilding-PoE2` (ветка `dev`):**
   - Коммит `80344dd88`: `docs: workspace agent instructions, architectural decisions and dev tooling` (AGENTS.md, CLAUDE.md, GEMINI.md, docs/ai/*, tools/pob2.ps1, .gitignore с правилами игнорирования локальных бэкапов).
   - Коммит `3f37144d5`: `feat(ui): Fluent design tokens, font presets, window state and side-by-side item comparison` (27 файлов: D-017 Fluent тема/акценты/шрифты, D-018 геометрия окна, D-019 quick-import Ctrl+V, D-020 compact tooltips/auto-compare, D-021 side-by-side сравнение, Noto шрифты и DLL).
   - Рабочее дерево: clean.

3. **Верификация:**
   - Интеграционный харнесс `harness_batch11_sidebyside.lua` — **100/100 PASS**.
   - Регрессионные харнессы: batch 7..10 — **все PASS**.
   - Документация синхронизирована.

## 16. Русская локализация названий предметов (D-023) и исправление визуального слоя заголовков (2026-11-11)

### Что сделано
1. **Словарь `src/Data/ItemNamesRU.lua`:** 679 записей (441 уник, 238 базовых предметов).
2. **Настройка `main.itemLanguage` (EN/RU/DUAL, default DUAL):** `Settings.xml` + Options DropDown.
3. **Исправление визуального слоя заголовков (обратная связь владельца):**
   - **Цвет и яркость шрифта (C++):** в `r_font.cpp` заменена растеризация `IMGTYPE_GRAY` на `IMGTYPE_RGBA` с белым RGB и coverage-альфой. Устранено квадратичное двойное затемнение глифов. Свежая `SimpleGraphic.dll` собрана и развернута.
   - **Шрифт русского названия:** русские заголовки приводятся к верхнему регистру (`toUpperRu` через `lua-utf8`) — капитель в стиле игры PoE2, плотные и крупные буквы.
   - **Границы и шапка (фикс перекрытия рамкой):**
     - Внутри декоративного баннера: чистое русское название (`АСТРАМЕНТИС` / `ШИРОКИЙ МЕЧ`), короткие строки по центру с запасом 80-100 px до боковых рамок — рамка ничего не закрывает.
     - Под декоративным баннером: оригинальный английский подзаголовок серым цветом `^8` (`Astramentis (Onyx Amulet)` / `Broadsword`) на всю ширину карточки (438 px).
     - Auto-fit размера шрифта заголовка: плавное масштабирование (22 → 18 → 15) при длинных названиях.
     - `Tooltip.lua`: замер ширины в `GetCardWidth`/`GetDynamicSize` проверяет ВСЕ строки шапки с запасом +50px (карточка резервирует ширину, текст не выходит за границы); `CheckForUpdate` мгновенно сбрасывает кэш при смене языка.
4. **Снапшоты:**
   - `Snapshots/PoE2-ItemLocalization-20261111/`
   - `Snapshots/PoE2-ItemLocalization-Fix-20261111/`
   - `Snapshots/SimpleGraphic-Next-FontColorFix-20261111/`
5. **Верификация:**
   - `harness_batch12_itemloc.lua` — **44/44 PASS** (host.exe).
   - Регрессия: batch 8 (60/60), batch 9 (67/67), batch 10 (67/67), batch 11 (100/100) — все PASS (337/337 тестов).
   - Сборка SimpleGraphic RelWithDebInfo/x64 — EXITCODE 0, DLL развернута.
   - Компиляция 4 файлов (ItemNamesRU, Main, ItemsTab, Tooltip) — COMPILE OK.
   - Рабочая ветка: `dev`, коммиты не выполнялись.
