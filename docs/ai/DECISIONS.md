# PoB2Fork — Architecture Decisions

## D-001: Workspace is not a Git repository

Родительский каталог PoB2Fork объединяет независимые Git-репозитории.
Не выполнять `git init` в корне workspace без отдельного решения.

## D-002: Component repositories remain independent

PathOfBuilding-PoE2, PathOfBuilding-SimpleGraphic, RePoE, PyPoE и
PathOfExile_Translated имеют собственные Git-корни.

Все изменения и проверки выполнять на уровне конкретного компонента.

## D-003: Preserve working tree changes

Незакоммиченные изменения пользователя считаются важными.
Нельзя выполнять reset, clean, checkout с потерей изменений или commit без разрешения.

## D-004: Backups outside repositories

Перед изменением существующих файлов создавать timestamped backups
в отдельной директории вне Git-репозитория.

## D-005: Localization identifiers are stable contracts

При извлечении и переводе ресурсов сохранять оригинальные ID.
Не менять схему, не объединять повторные stat IDs и не отбрасывать
значения без анализа потребителей.

## D-006: Separate game data and application UI localization

Ресурсы Path of Exile 2 и интерфейс Path of Building — разные слои локализации.
Не смешивать их в одну систему переводов.

## D-007: Documentation is the project source of truth

Код и документация в Git являются источником истины.
Nowledge Mem используется для поиска знаний, решений и контекста,
а не как замена репозитория.

## D-008: Dedicated Nowledge Mem Space

Для проектной памяти используется Space `pob2fork` с retrieval mode `strict`.
Личные воспоминания из Default не должны попадать в проектный контекст.

## D-009: Idempotent memory synchronization

Автоматическая синхронизация Markdown-документов выполняется через постоянные IDs.
Повторный sync обновляет записи, а не создаёт новые дубликаты.

## D-010: SimpleGraphic i18n groundwork committed as base (T0, 2026-11-07)

Незакоммиченный дифф SimpleGraphic зафиксирован коммитом `4fc1707` на ветке
`i18n-unicode-test`: UTF-8 font pipeline, stb_truetype TTF glyph fallback, Unicode input
(`EncodeCodepointUTF8`), фикс null-deref `r_tex_c` (upstream #112).

- Ветка не пушится и не мерджится в master без отдельного решения владельца.
- Резервные копии `r_font.*.backup-20261107-*` перемещены в
  `Snapshots\SimpleGraphic-T0-20261107\` (хэши сверены), пред-коммитный patch сохранён там же.
- Из-за нормализации EOL (CRLF→LF) диффы с upstream снимать с `--ignore-cr-at-eol`.
- Обнаруженная в диффе stb_truetype-подсистема (`LoadTtfFace`/`RasterizeGlyph`/
  `LoadEmojiFallbackFont`) принимается как зачаток этапа T4 плана модернизации;
  выбор бэкенда (DirectWrite vs FreeType+HarfBuzz) по-прежнему открытое решение перед T4.

## D-011: Font fallback rasterizer stays stb_truetype (2026-11-07)

Контекст: аудит рекомендовал DirectWrite (Windows) / FreeType+HarfBuzz (кроссплатформа).
Факт: stb_truetype (вендорен через `dep/imgui/imstb_truetype.h` v1.26) уже интегрирован
и проверен (коммит `4fc1707`, ночные emoji/variation тесты).

Решение:
1. **Растеризатор — stb_truetype.** Переход на FreeType/HarfBuzz не оправдан: shaping
   нужен для арабского/индийских письменностей, отсутствующих в PoB UI; DirectWrite дал
   бы только discovery системных шрифтов.
2. **Discovery — конфиг-файлы** (`UnicodeFallback.tgf`/`EmojiFallback.tgf`, поля
   `file`/`scale`). В поставке репо PoE2 этих конфигов нет — вопрос переносимости
   открыт. Будущее улучшение: DirectWrite-энумерация системных шрифтов с авто-генерацией
   fallback-конфига (отдельная задача).
   Развитие (вечер 2026-11-07): исследование 25 шрифтов PoE2 из Bundles2 (NMem
   `ec72aae9`) — Fontin без кириллицы; **Noto Sans SC = шрифт русской локализации PoE2
   (OFL)**; Friz Quadrata имеет кириллицу, но лицензия ITC коммерческая. Владелец
   выбрал режим **«полный Noto»** и подтвердил визуально («стало лучше»): Fontin.tgf →
   Noto Sans SC Regular, Fontin SmallCaps.tgf → Noto Sans SC SemiBold (тест-runtime;
   бэкапы legacy *.legacy-backup-*). Для поставки в репо — официальный Noto Sans SC от
   Google (OFL), не копия из игры.
3. **Glyph cache — ограниченный LRU** (256/высота, коммит `ae1d2a9`); текстурный атлас —
   опциональная будущая оптимизация.

## D-012: Fallback-цепочка гарнитур и SDF DrawControlBox в SimpleGraphic-Next (2026-11-08)

Контекст: репозиторий `PathOfBuilding-SimpleGraphic-Next` (ветка `feat/modern-runtime`) —
отдельный Git-root, развивает модернизацию рантайма (не путать с
`PathOfBuilding-SimpleGraphic`, где выполнены T0–T4). Изменения НЕ закоммичены
(6 файлов, +493/−2); резервные копии: `Snapshots\SimpleGraphic-Next-20261107-pre-drawcontrolbox\`.

Решение:
1. **Fallback-цепочка из массива `fonts`** (`UnicodeFallback.tgf`): `LoadFallbackFont()`
   парсит упорядоченный массив `{name, file, scale}` и грузит цепочку
   FrizQuadrataITC → SegoeUI → NotoSansCJK; `RasterizeGlyph` опрашивает их последовательно
   после собственного face шрифта и до emoji-face. Совместимость: при отсутствии массива
   `fonts` работает старый путь `LoadTtfFaceFromConfig` (одиночный face); собственный
   глиф шрифта всегда имеет приоритет. Дополнительно `LoadFallbackFont()` теперь
   вызывается и для TTF-конфиг шрифтов (раньше — только для legacy .tga; иначе цепочка
   была бы мёртвым кодом для TTF-шрифтов; изменение аддитивное: tofu → глиф цепочки).
2. **Общий кэш фолбэк-гарнитур** (`GetSharedFallbackFace`): faces делятся между всеми
   7 экземплярами `r_font_c` (Noto CJK ~17 МБ; иначе ~120 МБ лишней RAM), ключ — путь
   файла, владение `stbtt_fontinfo` — в деструкторе `FallbackFace`.
3. **SDF rounded-box** (`r_main.cpp`): новая команда слоя `ROUNDED_BOX` + программа
   `roundedBox` (GLES 3.00): один проход — fill, border-ring, drop shadow
   (`sdRoundBox`, покрытие через `0.5 - sd/px`); shadow — smoothstep-размытие SDF,
   offset (0,2), alpha 0.4*bg.a, цвет не параметризован (не нужен Lua API).
   Отрисовка — немедленный drawcall после flush пакета текстур (порядок сохранён);
   culling и frame-elision совместимы (команда попадает в cmdStorage-хэш).
4. **Lua API `DrawControlBox(x, y, w, h, radius[, bgColor[, borderColor[, borderWidth[, shadowBlur]]]])`**:
   radius 0..16 логических px (дополнительно клампится к min(w,h)/2 в рендерере),
   цвета — таблица `{r,g,b,a}` 0..1 или nil (текущий drawColor), borderWidth
   по умолчанию 1, shadowBlur по умолчанию 0; координаты умножаются на dpiScale
   как в DrawImage. Добавлен чисто виртуальный `r_IRenderer::DrawControlBox`
   (единственный реализатор — `r_renderer_c`).

Верификация (2026-11-08): сборка RelWithDebInfo/x64 EXITCODE 0
(`build-SimpleGraphic-Next`, VS 18 BuildTools, CMake 4.3.1); дымовой тест через
minimal-host (`RunLuaFileAsWin`) + Lua-скрипт: скриншот подтверждает скругления
0/8/12/16 px, рамки (в т.ч. nil→SetDrawColor), тени blur 3/6/16, полупрозрачный фон;
кириллица (Friz Quadrata), CJK/hangul (Noto Sans CJK), символы (Segoe UI) — без tofu.

Известная предсуществующая проблема (вне этого диффа): при отсутствии .tgf у шрифта
`FindFontHeight` даёт `heightIdx = -1` → `fontHeights[-1]` (UB, краш в DrawTextLine);
движок требует наличия всех 7 .tgf в runtime. Отдельная задача по хардненингу.

## D-013: Fluent-тема PoB2 — токены + legacy-fallback; решения пакета 4 (2026-11-09)

Контекст: модернизация UI PoB2 под WinUI 3 Fluent (Windows 11 Dark) поверх примитива
`DrawControlBox` (D-012, SimpleGraphic-Next). Тема живёт в `src/Modules/ThemeFluent.lua`
(untracked): палитра — единственный источник, компонентные группы резолвятся в do-блоке.
Контролы используют Fluent-ветку только при наличии глобальной `DrawControlBox`, иначе —
legacy DrawImage путь байт-в-байт (обратная совместимость с текущей DLL v2.5.5).

Решения владельца (пакет 4):
1. **SectionControl** (фактический GroupBox PoB2 — отдельного класса GroupBoxControl
   в кодовой базе нет): radius 4 (уровень control, не card 8) из-за плотной компоновки
   секций; тень 0; плашка заголовка сливается с карточкой («legend»-разрыв рамки).
2. **SliderControl**: акцентная золотая заливка трека слева от ползунка (WinUI-стиль);
   knob — светлый круг с accent-кольцом при hover/drag; геометрия взаимодействия
   (IsMouseOver/drag) не менялась. Тики divCount — цвета colors.border.
3. **PopupDialog** (единая точка всех модальных диалогов): заголовок остаётся НАД
   карточкой на legacy-позиции, без плашки — layout контента попапов гарантированно
   не сдвигается; затемнение фона в Main.lua сохранено (как в WinUI ContentDialog).

Отложено в пакет 5: `CalcSectionControl` (data-driven цвета групп, ячейки значений,
overlay-режим с перетаскиванием), `RectangleOutlineControl` (параметризуется
вызывающим кодом — изменений не требует).

Развитие (пакет 5, 2026-11-09, CalcSectionControl выполнен):
1. Карточка секции — нейтральная (surface + stroke, radius 4, без тени); групповой
   цвет (`self.colour` = escape-коды OFFENCE/DEFENCE/…) СОХРАНЁН на внутренних
   линиях заголовков подсекций и бара́х ячеек, но утончён 2px → 1px — компромисс
   «WinUI-карточка + цветокодировка Calcs».
2. Ячейки (WinUI 3): временная displayData — белая вуаль 8% (radius 3) поверх
   data-driven bgCol; закреплённая (displayPinned) — золотая вуаль accent 22% +
   акцентный индикатор 3px. Legacy-зелёная подсветка сохранена в legacy-ветке.
3. Overlay-панель: карточка radius 6, surface @0.97, тень 6; при drag — accent-рамка;
   хедер surfaceHover, разделитель colors.border.

Верификация: компиляция родным рантаймом 12/12 OK; харнессы batch1–5 —
25/25, 37/37, 46/46, 50/50, 40/40. Бэкапы: `Snapshots\PoE2-ThemeFluent-20261109-batch5\`.

## D-014: Win11 нативный стиль окна SimpleGraphic-Next — DWM-интеграция и Lua API (2026-11-09)

Контекст: отправной точкой стал коммит владельца `a926ea5` (2026-11-07) — уже
подключена `dwmapi.lib` (CMakeLists) и при старте окна задаются
`DWMWA_USE_IMMERSIVE_DARK_MODE`=TRUE и `DWMWA_SYSTEMBACKDROP_TYPE`=DWMSBT_MAINWINDOW
(прямая линковка, `engine/system/win/sys_video.cpp`). Выполненная дельта:

1. **Прямая линковка dwmapi сохранена** (лад владельца), динамическая загрузка
   `DwmSetWindowAttribute` не понадобилась.
2. **Corner preference**: при старте добавлен `DWMWA_WINDOW_CORNER_PREFERENCE`(33) =
   `DWMWCP_ROUND`(2) — нативное скругление окна Win11; на Win10 атрибут молча
   игнорируется DWM (HRESULT-ошибка безопасна).
3. **Версионный gate только для backdrop**: `IsWindowsBuildAtLeast(22621)` через
   `RtlGetVersion` (ntdll/GetProcAddress — независимо от манифеста).
   `DWMWA_SYSTEMBACKDROP_TYPE` требует Win11 22H2 (build 22621+); dark mode
   (`DWMWA 20`) работает с Win10 1809+, corner preference безопасен — gate на них
   не накладывается.
4. **Контракт Lua API**: `SetWindowBackdrop` возвращает boolean (false на
   неподдерживаемых системах) вместо Lua-ошибки — вызывающие скрипты не обязаны
   проверять ОС; `SetWindowDarkMode` — void. Маппинг строк:
   "None"→DWMSBT_NONE(1), "Mica"→DWMSBT_MAINWINDOW(2), "MicaAlt"→DWMSBT_TABBEDWINDOW(4).
5. **Архитектура**: новые методы в интерфейсе `sys_IVideo` (`SetDarkMode`,
   `SetBackdrop` + enum `sys_backdrop_e` в `sys_video.h`), реализация в
   `sys_video_c`; Lua-слой (`ui_api.cpp`) обращается через `ui->sys->video` —
   тот же паттерн, что `SetWindowTitle`. Дефолт при старте: dark=TRUE + Mica +
   round corners.
6. **Известное ограничение**: клиентская область GLFW/ANGLE-окна непрозрачна
   (обычный swapchain) — Mica видна на DWM-рамке/заголовке; полупрозрачный клиент
   под Mica потребовал бы extend-frame (DwmExtendFrameIntoClientArea) и прозрачного
   клира — отдельная задача.

Верификация: сборка SimpleGraphic RelWithDebInfo/x64 EXITCODE 0; дымовой тест
`smoke\test_win11.lua` — 4/4 PASS, backdrop=true на всех значениях (машина ≥ 22H2),
скриншот клиентской зоны OK. DLL развернута только в smoke-окружение; в
`PathOfBuilding-PoE2\runtime\` — решение за владельцем. Бэкапы:
`Snapshots\SimpleGraphic-Next-20261109-win11\`.

## D-015: Fluent-пакет 6 — динамика попапов, смягчение рамок, Light Theme (2026-11-09)

Контекст: живое тестирование владельца выявило (1) баг — PopupDialog уходит за экран
при уменьшении окна; (2) «тяжёлый» UI — избыток контуров («коробки в коробках»);
запрошена Светлая тема.

Решения:
1. **Кламп попапов, а не пересчёт высоты**: x/y-функции PopupDialog центрируются по
   живым `main.screenW/H` с `m_max(0, ...)`. Кламп — минимальный фикс: dialog taller
   than screen прижимается к левому/верхнему краю (контент Options доступен через
   скроллбар). Динамическую адаптацию ВЫСОТЫ диалогов при ресайзе сознательно НЕ
   делали (resizeFunc-механизм остаётся ответственным; Options высоту пересчитывает
   только при переоткрытии). `Build.lua` resizeFunc (Similar Builds) перезаписывает
   y-функцию попапа — туда добавлен тот же кламп.
2. **Смягчение рамок через отдельный токен `strokeSoft`** (Dark white 5% / Light
   black 7%), а не правку глобального `stroke`: интерактивные контролы
   (button/edit/checkbox/dropdown) сохраняют определённость (8%), карточки
   (section/calcSection/card/tooltip/dialog + overlay) переходят на `strokeSoft`.
   `list.border` оставлен opaque #3E4046 — панели списков не участвуют в «шуме».
   Внутренние отступы — layout-уровень, темой не решаются (осознанно).
3. **Light-палитра**: отдельные значения палитровых деталей, а не инверсия —
   checkbox.check (#1F1F21 на золоте Dark / #FFFFFF на затемнённом золоте Light),
   scrollbar.thumb (white/black альфы), veil ячеек Calcs (white 8% / black 5%),
   overlay (surface@0.97 обеих тем). Акцент Light — #9E7D1E (золото, затемнённое
   под светлый фон; Windows Blue #0067C0 не выбран — сохранена PoE2-идентичность).
4. **Контракт SetTheme**: возвращает boolean; неизвестное имя — false без изменений;
   то же имя — true без побочных эффектов (нет лишнего SetWindowDarkMode). Синк
   системного заголовка — `SetWindowDarkMode(theme == "Dark")` c guard по типу
   (старая DLL без Win11-API просто пропускает).
5. **Хранение**: Settings.xml атрибут `uiTheme` (Misc), применение при старте в
   `ChangeUserPath` после LoadSettings; переключение в Options применяется live,
   Cancel восстанавливает savedState-тему; дефолт — Dark (обратная совместимость
   существующих установок).

Обновления ожиданий харнессов batch2/4/5 (границы 0.08 → 0.05) — следствие решения 2,
задокументированы в SESSION_HANDOFF части 8. Верификация: batch6 38/38; регрессия
batch1–5 — 25/25, 37/37, 46/46, 50/50, 40/40; нативная компиляция 14 файлов OK.
Бэкапы: `Snapshots\PoE2-ThemeFluent-20261109-batch6\`.

## D-016: batch6fix — динамическая высота попапов, ремап `^7` через SetIndexedColor, шрифты Noto Sans SC (2026-11-09)

Контекст: живой тест владельца после пакета 6 выявил — (1) Options-попап всё ещё
влезает криво при сильном уменьшении окна; (2) Light-тема неполная:
фон захардкожен, текст через `^7` остаётся белым на светлом фоне; (3) легаси-шрифты
(Fontin/Liberation Sans) с ограниченной кириллицей.

Решения:
1. **Попапы: динамическая высота (замена п.1 D-015)** — владелец осознанно заменил
   «кламп вместо пересчёта»: `PopupDialog:GetEffectiveHeight()`
   = `m_min(height, main.screenH - 20)`; y = `m_max(10, ...)`. Draw рисует карту с
   эффективной высотой и ресинхронизирует скроллбар (`SetContentDimension`);
   `Build.lua` resizeFunc зеркалит кламп. Понесённые константы (`-20`, `10`) —
   точки калибровки владельца. `GetVirtualScreenSize()` обновляет
   `main.screenW/H` каждый кадр — пересчёт на каждый Draw корректен.
2. **`^7` — нативный API, не правкой меток**: сотни `^7`-меток по всему UI не
   переводимы; в `common.cpp` таблица экранирования стала мутабельной
   (`colorEscape[10][3]`), в ui_api.cpp — `SetIndexedColor(index, r, g, b)`;
   `ThemeFluent:SetTheme` вызывает `SetIndexedColor(7, textPrimary)`.
   Плюсы: один хук; карточка предмета/гема в тултипах сохраняет свои
   контрастные правила через opt-out (Tooltip.lua временно возвращает `^7` в белый
   на время Draw). Ограничение: API без отката «из коробки» — согласовано
   (call-site отвечает за восстановление).
3. **Тултипы — opt-out, а не полный ремап** (см. п.2): карточка предмета/гема
   `tooltipHeader` — тёмный полупрозрачный фон; в Light-теме `^7` для неё на время
   Draw переключается
   в белый, после наката — восстанавливается; plain-текст обычных тултипов в Light
   — `textPrimary`.
4. **Fontin → Noto Sans SC** (OFL; Noto Sans SC = официальный шрифт русской
   локализации PoE2): слоты захардкожены в `r_main.cpp`, поэтому замена выполнена
   через .tgf-конфиги (UTF-8 без BOM — прецедент инцидента 2e45654):
   Fontin/Fontin Italic/Liberation Sans → notosanssc-regular; Fontin SmallCaps/
   SC Italic/Liberation Sans Bold → notosanssc-semibold; ttf-файлы скопированы в
   `runtime\SimpleGraphic\Fonts\` PoE2. F_FIXED (Bitstream Vera Mono, консоль) не
   тронут. Согласуется с D-010 (Noto-выбор владельца от 2026-11-07) и D-011
   (stb_truetype может растрировать любой TTF).
5. **Инфраструктура**: host.exe требует АБСОЛЮТНЫХ путей в скриптах; в стаб `main`
   batch4-харнесса добавлены `screenW/H` (крэш прогонов); в smoke скопирована
   патченная lua51.dll из runtime PoE2 (диалект `+=`, бэкап ванильной).

Верификация: компиляция родным рантаймом 15/15 OK; харнессы — batch6fix (новый,
22/22), batch6 38/38 (ожидания клампа обновлены), batch4 50/50, batch3 46/46,
batch2 37/37, batch5 40/40, batch1 25/25 (luajit); smoke `test_indexedcolor` 9/9.
DLL `397DBD6F…` **развернута в `PathOfBuilding-PoE2\runtime\`** (бэкап B24BC3F9… —
`SimpleGraphic.dll.before-indexedcolor-20261109`). Бэкапы:
`Snapshots\PoE2-ThemeFluent-20261109-batch6fix\`,
`Snapshots\SimpleGraphic-Next-20261109-indexedcolor\`.

## D-017: Batch 7 — Выбор UI Font и выбор Accent Color в Options (2026-11-09)

Контекст:
Владелец одобрил реализацию Пакета А кастомизации интерфейса:
1. Выбор шрифта (UI Font Preset): возможность переключения между оригинальным гарнитуром PoE2 ("PoE2 Authentic (Fontin)") с Unicode-fallback и современным гротеском ("Modern Sans (Noto Sans)").
2. Выбор акцентного цвета (UI Accent): выбор из 4 палитр ("PoE2 Gold", "Fluent Blue", "Crimson", "Emerald") с живым переключением без перезапуска приложения.
3. Сохранение и загрузка настроек шрифта и акцента в `Settings.xml` (`uiFont`, `uiAccent`).

Решения:
1. **Шрифты (`src/Modules/UIFont.lua`):**
   - Движок SimpleGraphic инициализирует слоты шрифтов ("VAR", "VAR BOLD" и т.д.) только при старте из файлов `.tgf` в каталоге `runtime/SimpleGraphic/Fonts/`.
   - Модуль `UIFont.lua` управляет конфигурационными файлами слотов шрифтов на диске:
     - `authentic`: оригинальные `Liberation Sans.tgf` и `Liberation Sans Bold.tgf` восстанавливаются из резервных копий `.authentic-bak`, сохраняя оригинальный Fontin для заголовков и fallback на Noto Sans для кириллицы/CJK.
     - `noto`: перенаправляет слоты VAR на `notosanssc-regular.ttf` и VAR BOLD на `notosanssc-semibold.ttf`.
   - При смене шрифта в диалоге `Options` пользователь получает всплывающее подтверждение с предложением перезапустить приложение сейчас или позже (`Restart now` / `Later`).
2. **Акцентные палитры (`src/Modules/ThemeFluent.lua`):**
   - Внедрена система `accents` с палитрами:
     - `PoE2 Gold`: `#D4AF37` (по умолчанию, Dark) / `#9E7D1E` (Light)
     - `Fluent Blue`: `#0078D4`
     - `Crimson`: `#D13438`
     - `Emerald`: `#107C41`
   - Функция `Theme:SetAccent(name)` на лету обновляет все зависимые токены (`accent`, `accentHover`, `accentPressed`, `accentDisabled`, `cellSelected`, `check`).
   - Использован общий объект `_G.__THEME_FLUENT_SHARED__`, гарантирующий, что все независимые вызовы `LoadModule("Modules/ThemeFluent")` во всех контролах мгновенно получают обновлённые цвета акцента.
3. **Сохранение и интеграция (`src/Modules/Main.lua`):**
   - В диалог `Options` добавлены DropDown-контролы `UI Font:` и `Accent Color:`.
   - Настройки читаются в `main:LoadSettings()` и сохраняются в `main:SaveSettings()`.
   - При старте `main:ApplyUICustomization()` синхронизирует состояние дисковых шрифтов и применяет выбранный акцент.

Верификация:
- `harness_batch7.lua`: 78/78 PASS (тесты shared-модуля, SetAccent/GetAccent, всех палитр акцента, дисковой логики смены шрифтов, чтения/записи `Settings.xml`).
- Синтаксическая валидация `Main.lua`, `ThemeFluent.lua`, `UIFont.lua` в рантайме: PASS.

## D-018: Window State Persistence — геометрия окна в Settings.xml (2026-11-09)

Контекст:
Требуется сохранять и восстанавливать между запусками PoB2 положение и размер
окна (X, Y, Width, Height) и флаг максимизации.

Решения:
1. **Движок (`PathOfBuilding-SimpleGraphic-Next`, ветка `feat/modern-runtime`):**
   - В `sys_IVideo` добавлены методы `GetWindowPos/SetWindowPos`,
     `GetWindowSize/SetWindowSize`, `IsMaximised/SetMaximised`; реализация в
     `engine/system/win/sys_video.cpp` (GLFW: `glfwGetWindowPos`,
     `glfwSetWindowPos`, `glfwGetWindowSize`, `glfwSetWindowSize`,
     `glfwGetWindowAttrib(GLFW_MAXIMIZED)`, `glfwMaximizeWindow/glfwRestoreWindow`).
   - Lua API в `ui_api.cpp`: `GetWindowPosition`, `SetWindowPosition`,
     `GetWindowSize`, `SetWindowSize`, `IsWindowMaximized`, `SetWindowMaximized`.
   - Функции движка «тупые»: они не клампят позицию — проверка выходит за
     пределы экрана выполняется в клиенте (см. п.3), иначе `SetWindowPosition`
     не соответствовал бы своему контракту.
   - Дополнительно введён `GetMonitorBounds()` (left, top, right, bottom —
     объединение всех мониторов). Он необходим: существующий `GetScreenSize()`
     возвращает размер клиентской области окна, а не границы экрана, поэтому
     по нему нельзя определить, что окно ушло за пределы монитора.
2. **Хранение состояния:**
   - Собственный механизм движка (`vid_resizable = 3` → cvar `vid_last`
     "size,size,pos,pos,maximised") не отменяется, но PoB2 хранит своё
     состояние в `Settings.xml` — атрибуты `windowX`, `windowY`, `windowWidth`,
     `windowHeight`, `windowMaximized` в элементе `<Misc>` (существующие
     атрибуты не затираются).
   - Логика вынесена в отдельный модуль `src/Modules/WindowState.lua`
     (`Read`, `Write`, `GetBounds`, `IsOnScreen`, `Clamp`, `Capture`, `Apply`) —
     чистые функции, тестируемые без окна.
3. **Guard check (Lua):**
   - Позиция считается непригодной, если окно не оставляет на экране хотя бы
     64 px по каждой оси (`WindowState.IsOnScreen`).
   - Полностью за пределами экрана (например, отключён второй монитор) →
     окно центрируется; частично за пределами → подтягивается к видимой
     области; размер клампится по виртуальному рабочему столу.
   - Восстановление выполняется в `main:Init()` (окно к этому моменту уже
     создано движком) и защищено флагом `windowStateApplied` от повторного
     применения; вызывается также из `main:ChangeUserPath()`.
   - Минимальный размер окна 1080×720 задаёт сам движок
     (`CFG_VID_MINWIDTH/HEIGHT`), GLFW увеличивает меньший запрос — это
     политика движка, а не ошибка API.
4. **Максимизация:** флаг хранится отдельным атрибутом; при сохранении в
   максимизированном состоянии сохраняется последний известный «нормальный»
   размер (размер развёрнутого окна не перезаписывает его).

Верификация (2026-11-09):
- `harness_batch8.lua` — 60/60 PASS (luajit и host.exe): парсинг/запись
  атрибутов, guard check, кламп позиции и размера, capture/apply, поведение
  при отсутствии API в старой DLL, статическая проверка wiring в `Main.lua`
  и `_SimpleGraphic.def.lua`.
- Живой smoke-тест рантайма `smoke/test_windowstate.lua` — 17/17 PASS.
- Живой прогон PoB2: восстановление (300,200,1400×900 → 300,180 — Y подтянут
  к экрану), out-of-bounds (5000,5000 → центрирование 260,90),
  `windowMaximized="true"` → окно развёрнуто. Атрибуты записаны приложением
  в `Settings.xml` при выходе.
- Сборка движка RelWithDebInfo/x64 — EXITCODE 0; DLL SHA256 `D6B95179…`
  развёрнута в `PathOfBuilding-PoE2\runtime\` и в smoke
  (бэкапы `SimpleGraphic.dll.before-windowstate-20261109`).

## D-019: Quick Import по Clipboard (Ctrl+V) в BuildList и Import Tab (2026-11-10)

Контекст:
Владелец запросил возможность открывать Import Tab с предзаполненным кодом
одним Ctrl+V из списка билдов, если в буфере обмена находится PoB-код или
ссылка на билд. Только чистый Lua, без C++ и пересборки DLL. Существующий
Ctrl+V (copy-paste файлов билдов) не должен ломаться.

Решения:
1. **Эвристика (`src/Modules/BuildList.lua`, `listMode:OnFrame`):** строка
   буфера обрезается по краям (`^%s+` / `%s+$`); считается похожей на PoB-код,
   если длина > 20 и символы из base64url-алфавита `A-Za-z0-9+/=_-`, либо если
   начинается с `https?://`. Проверка выполняется ПЕРВЫЙ внутри блока
   `Ctrl+V`: при совпадении — `main:SetMode("BUILD", false, "Imported build")`
   + `main.pendingClipboardImport = trimmed`; существующая логика copy/cut
   пропускается (`quickImportHandled`), но состояния `copyBuild`/`cutBuild`
   НЕ очищаются — копирование/перемещение файла остаётся доступным после.
   Отклонение от исходного снипета: вместо `return` (который пропустил бы
   `ProcessControlsInput`/`DrawControls` кадра) используется флаг
   `quickImportHandled`, чтобы кадр дорисовался полностью.
2. **Передача кода (`src/Modules/Build.lua`):** `buildMode:Init` подхватывает
   `main.pendingClipboardImport` → `self.pendingClipboardImport` и сразу
   очищает глобальный флаг. `buildMode:OnFrame` (после guard-а
   `targetVersion`/`abortSave`) применяет его один раз: `viewMode = "IMPORT"`,
   фокус на `importCodeIn`, `SetText(code, true)` (notify=true → валидация
   через `importCodeHandle`). Автоимпорта нет — пользователь сам жмёт Import.
   Система рабочая, потому что `main:SetMode` лишь ставит очередь
   (`newMode`/`newModeArgs`, Main.lua:543), а `Init` вызывается позже в
   `main:OnFrame` (Main.lua:390–401) — к этому моменту флаг уже установлен.
3. **Прямой API (`src/Classes/ImportTab.lua`):** публичный
   `ImportTabClass:QuickImportFromClipboard()` — читает буфер, отклоняет
   короткий (< 3), обрезает, `SetText(trimmed, true)`, возвращает
   `importCodeValid`.
4. **Ctrl+V внутри Import Tab:** в `ImportTabClass:Draw` перед
   `ProcessControlsInput` перехватывается `KeyDown v + CTRL`; при полном
   отсутствии фокуса (`self.selControl == nil)` или фокусе на не-Edit-контроле
   вызывает `QuickImportFromClipboard()`. Отклонение от снипета («IsMouseOver»):
   используется реальная проверка фокуса `self.selControl` и класс контрола
   (`_className ~= "EditControl"/"ResizableEditControl"`, паттерн
   ConfigTab.lua:1049), иначе перехватили бы вставку у фокусированных полей
   buildPlannerAuthorName (changeFunc = nil) и создали бы двойную вставку
   при фокусе на `importCodeIn`.
5. **Крэх-страховка отсутствует намеренно:** Paste() в среде без буфера
   возвращает nil — обе точки использования это обрабатывают.

Верификация (2026-11-10):
- Снапшот до правок: `Snapshots\PoE2-QuickImport-20261109\` (BuildList.lua,
  Build.lua, ImportTab.lua).
- `harness_batch9_quickimport.lua` (host.exe) — 67/67 PASS:
  эвристика base64/URL/pastebin/pobb.in, негативные кейсы (обычный текст,
  пути Windows, ftp://, короткие строки), приоритет PoB-кода над armed
  copyBuild/cutBuild и наоборот, hand-off через pendingClipboardImport
  (принять/очистить/применить один раз), статические проверки wiring и
  компиляция всех трёх изменённых файлов (loadfile через host.exe).
- Коммиты не выполнялись (по требованию владельца).

## D-020: Compact Tooltips & Auto-Compare — опция `compactTooltips` (2026-11-10)

Контекст:
Владелец запросил компактный режим тултипов предметов (PoB2-тултипы с рунами
и длинными аффиксами слишком высоки) и компактный Auto-Compare сравнение
стат с плотными индикаторами. Чистый Lua, без изменений C++/DLL.

Решения:
1. **Настройка (`src/Modules/Main.lua`):** boolean `main.compactTooltips`
   (default false) — `Init()`, чтение `node.attrib.compactTooltips` в
   `LoadSettings()` (`<Misc>`), запись `compactTooltips = tostring(...)` в
   `SaveSettings()`. В `OpenOptionsPopup()`: CheckBox
   `^7Compact Item Tooltips:` (в секции Build-related, после
   `notSupportedModTooltips`) с тултипом про ALT-инверсию; добавлен во все
   обязательные точки: `savedState`, `currentState` (resizeInfo-переоткрытие
   Options при ресайзе), `controls.cancel` (восстановление).
2. **ALT-инверсия:** в `AddItemTooltip` (ItemsTab.lua) и
   `AddStatComparesToTooltip` (Build.lua):
   `local isCompact = main.compactTooltips; if IsKeyDown("ALT") then
   isCompact = not isCompact end` — ALT временно инвертирует режим.
3. **Компактный рендер тултипа (`ItemsTabClass:AddItemTooltip`):**
   - Шрифты 13/15/18 (Small/Big/Title) при компактном режиме.
   - Разделители через локальные переменные `sepGapDefault` (10→4),
     `sepGapLarge` (14→6), `sepGapHeader` (30→8); замена выполнена скриптом
     строго внутри тела `AddItemTooltip` (якоря: имя функции →
     `CreateUndoState`), 18 call sites (14×10, 3×14, 1×30); разделители за
     пределами функции не тронуты.
   - Флейвор-текст не выводится (`if flavourText and not isCompact`); lookup
     флейвора сохранён — `itemOrigin` (источник типа предмета) остаётся.
   - "(Not supported in PoB yet)" суффикс не добавляется в компактном
     режиме (2 call sites: flask/charm buffModLines).
   - Tip-строка «Hold Shift … granted skill» скрыта в компактном режиме;
     Tips про Ctrl+D оставлены (это управление отображением diff-ов).
4. **Auto-Compare (`Build.lua`):**
   - `CompareStatList(..., compact)`: при compact=true показываются только
     ключевые статы из локального множества `COMPACT_KEY_STAT_LABELS`
     (Full DPS, Combined DPS, Total Life, Energy Shield, Effective Hit
     Pool, Fire/Cold/Lightning/Chaos Resistance). Attributes/mana/regen и
     пр. отфильтрованы; атрибуты в displayStats отсутствуют (iii в PoE2) —
     включение не потребовалось.
   - Дельты получают индикаторы направления: рост `^2▲ +X`, падение `^1▼ -X`
     (стрелка = сырой знак дельты; цвет строки — прежняя семантика
     «лучше/хуже» через colorCodes.POSITIVE/NEGATIVE и lowerIsBetter).
   - Minion-список статов (CompareStatList с compact=nil) остаётся полным.
   - Функция «AddStatComparesToTooltip» используется и TreeTab-ом: compare-
     тултипы пассивных узлов следуют той же опции/ALT. Собственная копия
     `CompareEntry:CompareStatList` (CompareTab) не тронута — out of scope.
5. **SHIFT-переключение слота (`ItemsTab.lua`, только компактный режим):**
   в компактном режиме для многоместных семейств слотов («Ring», «Weapon»)
   выбирается строго **один** слот для сравнения:
   - При ховере в списке предметов / базе (когда слот не привязан):
     по умолчанию сравнивается со слотом 1 (`Ring 1`, `Weapon 1`); при
     зажатом `SHIFT` — со слотом 2 (`Ring 2`, `Weapon 2` / Off Hand).
   - При ховере экипированного предмета на персонаже: по умолчанию
     показывается исходный слот, при зажатом `SHIFT` — парный слот семейства.
   - Одиночные семейства («Helmet», «Body Armour» и т.д.) всегда отображаются.
   - Swap-варианты следуют за активным weapon set.
   - В обычном (не компактном) режиме выводятся все допустимые слоты, как прежде.

Верификация (2026-11-10):
- Снапшот до правок: `Snapshots\PoE2-CompactTooltips-20261110\`
  (Main.lua, Build.lua, ItemsTab.lua), снапшот фикса SHIFT:
  `Snapshots\PoE2-CompactTooltips-ShiftFix-20261110\`.
- `harness_batch10_tooltips.lua` (host.exe) — **67/67 PASS**:
  ALT-инверсия (4 комбинации), чтение/запись settings-атрибута, компактная
  фильтрация статов и стрелки (мэппинг `CompareStatList`, ключевой набор
  извлекается из Build.lua live, дрифт исключён), SHIFT-фамильный выбор
  слота (default Slot 1, SHIFT Slot 2, hover equipped slot + alternate on SHIFT),
  статические wiring-проверки (Init/Load/Save/Options/savedState/
  cancel/currentState, 18 compacted separators, стрелки, флейвор, суффикс,
  семейства) и компиляция трёх изменённых файлов.
- Что проверяется владельцем (живой прогон): Options-чекбокс, ALT во время
  ховера предмета, стрелки на реальных builds, SHIFT в Import/Items.
- Коммиты не выполнялись.

## D-021: Side-by-Side Item Comparison — параллельная карточка экипированного предмета (2026-11-10)

Контекст:
Владелец запросил показывать рядом с основным тултипом нового предмета вторую
карточку — тултип предмета, уже экипированного в выбранный слот. Функция должна
быть независима от Compact Tooltips (D-020), сохранять дельты под основной
карточкой и учитывать реальную ширину `viewPort`.

Решения:
1. **Настройка (`src/Modules/Main.lua`):** boolean
   `main.sideBySideItemComparison` (default `true`) — независимая от
   `compactTooltips`. Атрибут `sideBySideItemComparison` читается и пишется в
   `<Misc>` файла `Settings.xml`; в Options добавлен CheckBox
   `^7Side-by-Side Item Comparison:`. Настройка участвует в `savedState`,
   `currentState` (переоткрытие Options при resize) и восстановлении Cancel.
2. **Выбор слота (`src/Modules/ItemComparison.lua`):** отдельный чистый helper
   определяет семейство слота, убирая суффикс ` Swap` и конечный номер.
   Компактный режим переключает SHIFT между двумя слотами семейства (Ring
   1↔2, Weapon 1↔2); при наведении на экипированный предмет исходный слот
   используется по умолчанию, SHIFT выбирает парный. Swap-варианты следуют за
   активным weapon set. В некомпактном режиме SHIFT не меняет выбранный слот.
3. **Вторичная карточка (`src/Classes/ItemsTab.lua`):** тултип экипированного
   предмета строится рекурсивным вызовом `AddItemTooltip` с
   `skipComparison`/`skipStatDifferences`, поэтому не создаёт третью карточку и
   не дублирует дельты. Заголовок: `Currently Equipped (SlotName)`. Если в
   выбранном слоте нет предмета, остаётся только основной тултип.
4. **Размер и layout:** обе карточки ограничены 450 px. Вторичная карточка
   рисуется справа от основной, если хватает места в `viewPort`, иначе слева;
   расстояние между карточками — 12 px. Дельты остаются в основном тултипе под
   содержимым нового предмета.
5. **Синхронизация дельт:** при Side-by-Side сравнение ограничивается тем же
   выбранным слотом, который используется вторичной карточкой. Поэтому SHIFT
   одновременно переключает карточку и блок дельт.
6. **Compact-режим:** обе карточки используют общий компактный рендер D-020
   (шрифты 13/15/18, компактные separators, скрытый flavour text).

Верификация (2026-11-10):
- Снапшот до правок: `Snapshots\PoE2-SideBySide-20261110\` (`Main.lua`,
  `ItemsTab.lua`, `Tooltip.lua` и копии проектных документов).
- `harness_batch11_sidebyside.lua` (host.exe) — **47/47 PASS**: выбор семейства
  и SHIFT, Settings.xml round-trip, viewport-арифметика, фактический
  `Tooltip.Draw` с проверкой размещения справа/слева, точная ширина зазора,
  static wiring-проверки и компиляция четырёх изменённых/новых файлов.
- Регрессия: batch10 67/67, batch9 67/67, batch8 60/60, batch7 80/80 PASS.
- Живая проверка владельцем: Options-чекбокс и сохранение, compact/non-compact
  карточки, SHIFT для колец/оружия, положение карточек у края окна.
- Коммиты не выполнялись.

## D-021: Side-by-Side Item Comparison — финальное состояние post-review (2026-11-10)

После post-review правок архитектура приведена к итоговому виду:
1. **ItemComparison** — центральный модуль: `MAX_TOOLTIP_WIDTH = 450`, `CARD_GAP = 12`,
   `GetSideBySideLayout` (правый → левый → nil при невозможности без наложения),
   `GetActivationComparisonMode` (`toggleFlask`/`toggleCharm`; флаконы и чармы
   сравниваются через состояние активации, а не через замену слота),
   `ShouldBuildChildTooltips` (строго boolean; вторичная карточка собирается с
   `skipChildTooltips = true`).
2. **Tooltip** — `maxCardWidth` жёсткий лимит (обрезает `GetSize`, запрещает
   переезд во вторую колонку при `not self.maxCardWidth`), `GetCardWidth()`
   возвращает фактическую внешнюю ширину карты (включая header-буст `title + 50`),
   `GetDynamicSize(viewPort)` возвращает pair-aware width/height для
   `ItemsTab` content bounds, `Draw` размещает вторичную карту через
   `ItemComparison.GetSideBySideLayout` с точным зазором 12 px.
3. **ItemsTab** — вторичная карта через рекурсивный `AddItemTooltip` с
   `skipComparison`, `skipStatDifferences`, `skipChildTooltips`, `cardWidthLimit`;
   привязана к `tooltip.comparisonTooltip`; заголовок
   `Currently Equipped (SlotName)` только при предмете в слоте; флаконы/чармы —
   `calcFunc({ [activationMode] = item })` после `showStatDifferences`; дельты
   ограничены тем же `sideBySideSlot` (`compareSlots = { sideBySideSlot }`);
   `UpdateDisplayItemTooltip` фиксирует `displayItemTooltipOptionState`, а
   `ItemsTab:Draw` перестраивает persistent tooltip при изменении
   `compactTooltips`/`sideBySideItemComparison`.
4. **Main** — `LoadSettings` сбрасывает `sideBySideItemComparison = true` перед
   чтением `Settings.xml` (отсутствующий атрибут оставляет опцию включённой);
   чтение/запись атрибута в `<Misc>`; CheckBox в Options; `savedState`/`currentState`/
   Cancel wiring.
5. **Harness batch11 (integration, перезаписан на реальную Tooltip-интеграцию):**
   100/100 PASS — точная ширина карты 450 px (minWidth+cap), заголовок не расширяет
   карту за пределы cap, `maxCardWidth` запрещает вторую колонку,
   `GetDynamicSize` pair = 912 px при двух картах по 450, Draw- anchors 462 px
   apart справа и слева, узкий viewport (primaryX=195) — вторичная карта не
   рисуется (1 draw call), CheckForUpdate сброс строк при изменении опций
   (включая Cancel-поведение через `UpdateDisplayItemTooltip`), сокеты
   `{ nodeId = ... }` через `itemsTab.sockets`, `orderedSlots`, все статические
   wiring-проверки, компиляция 5 файлов (Main, ItemComparison, ItemsTab, Tooltip,
   PassiveTreeView).
- Регрессия: batch10 67/0, batch9 67/0, batch8 60/0, batch7 80/0 PASS.
- `git diff --check` — без whitespace-ошибок (только предупреждение Git
  LF→CRLF для `Main.lua`). Рабочее дерево грязное (D-017..D-021), коммиты не
  выполняются, не требует C++/DLL.

## D-022: Долгосрочная стратегия эволюции — PoB2.NET и изоляция через Lua Worker (2026-11-11)

Зафиксировано стратегическое архитектурное видение проекта (подробности в `docs/ai/ARCH_POB2_NET_CONCEPT.md`):
1. **Приоритет исполнения:** Сначала довести текущую сборку PoB2 (SimpleGraphic C++23 + LuaJIT) до полностью стабильного, функционального и локализованного состояния. Никаких преждевременных переписываний до фиксации стабильного эталона (Ground Truth).
2. **Будущая архитектура (PoB2.NET):**
   - **Frontend:** C# 15 / .NET 11 (WinUI 3 для Windows / Avalonia UI для кроссплатформы) + аппаратный рендеринг пассивного дерева (Win2D / Skia).
   - **Backend:** Неизменное оригинальное ядро PoB2 (`CalcEngine`, `ModDB`, `ModParser`, `Skills`, `Items`) на LuaJIT 2.1 в изолированном фоновом процессе (Persistent Worker).
   - **Связь (Bridge):** Развитие `HeadlessWrapper.lua` в версионированный DTO IPC-протокол (JSON Lines / MessagePack). Прямой P/Invoke и переписывание математики на C#/Rust отвергнуты для сохранения 100% совместимости с апстримом.
   - **Вспомогательные слои:** Rust — только как автономный CLI для валидации и diff бинарных DAT-данных игры; Python — инструменты аудита модов и локализации.

## D-023: Русская локализация названий предметов — слой отображения (2026-11-11)

Контекст: требуется отображать русские названия базовых и уникальных предметов в тултипах и интерфейсе Path of Building PoE2, не ломая внутренние идентификаторы (item.baseName, item.title, item.namePrefix/Suffix), которые используются расчетами Calcs, базой модов и совместимостью сохранений (pobb.in).

Источники данных:
- `PoE2-Localization-Extractor/exports/base_items_ru_validation_retry8/base_items.json` (5,496 записей, RU-имена)
- `PoE2-Localization-Extractor/exports/uniques_ru_validation1/uniques.json` (449 уникалов, id → RU-имя)

Решения:
1. **Модуль `src/Data/ItemNamesRU.lua`** — компактная таблица маппинга `["English Name"] = "Русское название"`, сгенерированная скриптом из экспортов. Метод `ItemNamesRU:Get(en)` возвращает RU-перевод с фолбеком на оригинал. Включает 441 унику (прямой 1:1 по `id`) и 238 базовых предмета (оружие, броня — по совпадению уникальных сигнатур урона/брони; остальные базы — фолбек на английский).
2. **Основной идентификатор не меняется:** `item.baseName`, `item.title`, `item.namePrefix/Suffix` остаются на английском. Локализация применяется только в `AddItemTooltip` при рендеринге заголовка.
3. **Настройка `main.itemLanguage`** (EN / RU / DUAL, по умолчанию DUAL):
   - Читается/пишется как `itemLanguage` в `<Misc>` файла `Settings.xml`.
   - Участвует в `savedState` (открытие Options), `currentState` (переоткрытие при ресайзе), `controls.cancel` (откат).
   - DropDown «Item Names Language:» в секции Build-related с вариантами: English (Original) / Русский (RU) / Dual (Русский + English).
4. **Отображение в `AddItemTooltip` (ItemsTab.lua) и исправление визуального слоя:**
   - EN: только английское название (оригинальный заголовок).
   - RU: русское название из словаря с приведением к верхнему регистру (`toUpperRu` через `lua-utf8`) для сохранения стиля игры PoE2 (капитель/All-Caps, плотный и крупный шрифт).
   - DUAL: двухблочный формат заголовка (чистая шапка + английский подзаголовок):
     - Внутри декоративного баннера шапки: только русские названия (`АСТРАМЕНТИС`, `АМУЛЕТ С ОНИКСОМ` / `ШИРОКИЙ МЕЧ`). Строки компактные (140-190 px), расположены точно по центру с огромным запасом (80-100 px) до боковых декоративных наконечников — **рамка больше ничего не закрывает**.
     - Под декоративным баннером (в теле тултипа, где ширина полная 438 px): отдельной строкой серым цветом `^8` выводится оригинальное название `enSubtitle` (например, `Astramentis (Onyx Amulet)` или `Broadsword`).
     - Auto-fit размера заголовка: при превышении допустимой ширины карточки (`maxTitleW`) размер шрифта плавно уменьшается (22 → 18 → 15), предотвращая выход текста за границы.
   - Применяется и к вторичной карточке Side-by-Side (через рекурсивный `AddItemTooltip`).
5. **Исправление веса, толщины и яркости шрифта в C++ (`PathOfBuilding-SimpleGraphic-Next`):**
   - **Авто-переключение fallback на Semibold для жирных слотов:** в `r_font.cpp` при загрузке fallback-шрифта для слотов с `SmallCaps` или `Bold` (`Fontin SmallCaps`, `Liberation Sans Bold`) движок автоматически подставляет `notosanssc-semibold.ttf` вместо `regular` со scale 1.06. Русские буквы теперь имеют полужирное начертание (Semibold, вес 600) и по толщине штрихов и высоте заглавных букв точно соответствуют массивному английскому Fontin SmallCaps (вес 700).
   - **Устранение затемнения цвета:** в `r_font.cpp` растеризация глифов переведена с `IMGTYPE_GRAY` на `IMGTYPE_RGBA` с белым RGB `(255, 255, 255)` и альфой `bitmap[i]`. Устранено квадратичное двойное затемнение шейдер * blend. Цвет русских букв стал 100% сочным и идентичным Fontin. Свежая `SimpleGraphic.dll` развернута в `runtime/` и `smoke/`.
6. **Расширение базы локализации (`src/Data/ItemNamesRU.lua`):**
   - Добавлены все недостающие категории бижутерии и экипировки (101 запись, всего 780): кольца (все 29 баз, включая `Gold Ring` / `Golden Ring` → `Золотое кольцо`), амулеты (все 25 баз), пояса (все 20 баз), флаконы (18 баз) и чармы (13 баз).
   - Базы предметов больше не выводятся на английском языке (например, `Golden Ring`), устраняя диссонанс между русским именем и английской категорией.
7. **Защита границ и кэш в `src/Classes/Tooltip.lua`:**
   - `GetCardWidth` и `GetDynamicSize`: проверяют ВСЕ строки шапки до первого разделителя `separatorImage` с отступом `+50px`.
   - `CheckForUpdate`: отслеживает `itemLanguage` для мгновенного сброса кэша и перерисовки при смене языка в Options.
8. **Ветка dev, коммиты не выполняются.**

Верификация:
- Харнес `harness_batch12_itemloc.lua` — **44/44 PASS** (host.exe).
- Регрессия: batch8 60/60, batch9 67/67, batch10 67/67, batch11 100/100 — все PASS (337/337 тестов).
- Компиляция 4 файлов (ItemNamesRU, Main, ItemsTab, Tooltip) — COMPILE OK.
- Снапшоты: `Snapshots/PoE2-ItemLocalization-20261111/`, `Snapshots/PoE2-ItemLocalization-Fix-20261111/`, `Snapshots/SimpleGraphic-Next-FontColorFix-20261111/`.

## [D-024] Русская локализация дерева пассивных умений (Display Layer & Dual Tooltips)
Дата: 2026-11-11
Статус: ПРИНЯТО / РЕАЛИЗОВАНО
Компонент: `PathOfBuilding-PoE2` (ветка `dev`)
Связанные решения: D-023 (Item Localization & Dual Tooltips), D-022, D-016 (Fonts & UTF-8).

Контекст: требуется локализовать отображение названий нод пассивного дерева умений в Path of Building PoE2 (Keystones, Notables, базовые ноды, ноды классов Восхождения), не затрагивая внутренние числовые и строковые идентификаторы (`node.id`, `node.skill`, `node.sd`, `node.mods`), которые используются ядром расчетов Calcs и графом связей дерева.

Источники данных:
- `PoE2-Localization-Extractor/exports/passives_ru_validation_retry1/passive_skill_trees/Default.json` (5,152 пассивки, 5,032 именованные ноды с официальным русским переводом).
- `Atlas.json`, `EndgameMap.json`, `BrequelTree.json` (всего 6,415 уникальных хэшей/пассивок).
- Сопоставление с `PathOfBuilding-PoE2/src/TreeData/0_5/tree.json`: 4,914 из 4,914 нод (100.0% совпадение по `skill == hash`).
- Покрытие ранних версий дерева (0_1 .. 0_4): 99.0% - 99.8% благодаря комбинированному маппингу `bySkill` + `byName`.

Решения:
1. **Модуль `src/Data/TreeNodesRU.lua`:**
   - Таблица `bySkill`: `[skill_id] = "Русское название"` (6,415 записей O(1) поиска по ID).
   - Таблица `byName`: `["English Name"] = "Русское название"` (2,111 уникальных названий для фолбека).
   - Метод `TreeNodesRU:Get(nodeOrName)`: универсальный доступ. Если передана таблица `node`, сначала ищет по `node.skill` / `node.id`, затем по `node.dn` / `node.name`. Если передан ID или строка — ищет в соответствующей таблице. Возвращает оригинальное имя при отсутствии перевода.
2. **Слой отображения тултипов (`PassiveTreeView.lua` -> `AddNodeName`):**
   - Управляется настройкой `main.itemLanguage` (EN / RU / DUAL):
     - **EN:** оригинальное английское название `node.dn` (размер 24, FONTIN).
     - **RU:** русское название `TreeNodesRU:Get(node)` (размер 24, FONTIN, с сохранением цвета пергамента `^xF8E6CA` при включенном `main.showFlavourText`).
     - **DUAL:** двухстрочный заголовок:
       - 1-я строка по центру: русское название (размер 22, FONTIN).
       - 2-я строка по центру: оригинальное английское название серым цветом `^8` (размер 16, FONTIN SC).
   - Охватывает просмотрщик дерева на вкладке дерева, `ItemsTab:socketViewer` и выбор нотаблов `NotableDBControl`.
3. **Двуязычный поиск по дереву (`PassiveTreeView.lua` -> `DoesNodeMatchSearch`):**
   - Поле поиска по пассивному дереву теперь поддерживает запросы как на английском, так и на русском языке (например: "zealot" или "фанатик" / "обет", "ветра" или "winds").
   - Для регистронезависимого поиска кириллицы в UTF-8 задействован `lua-utf8` (`utf8.lower`), исключающий пропуски заглавных русских букв.
4. **Требования к открытию нод:**
   - В блоке `Requires allocation of node` имя требуемой ноды в режиме DUAL отображается в формате `Русское имя (English Name)`.

Верификация:
- Харнес `harness_batch13_treeloc.lua` — **34/34 PASS** (host.exe).
- Регрессионный сьют: batch8 (60/60), batch9 (67/67), batch10 (67/67), batch11 (100/100), batch12 (44/44), batch13 (34/34) — **372/372 PASS (100%)**.
- Снапшот: `Snapshots/PoE2-PassiveTreeLoc-20261111/`.

## [D-025] Русская локализация камней умений (Skill & Support Gems Display Layer)
Дата: 2026-11-11
Статус: ПРИНЯТО / РЕАЛИЗОВАНО
Компонент: `PathOfBuilding-PoE2` (ветка `dev`)
Связанные решения: D-024 (Passive Tree Localization), D-023 (Item Localization & Dual Tooltips), D-022.

Контекст: требуется локализовать отображение названий камней умений (активных навыков и камней поддержки) в интерфейсе умений (`SkillsTab`), сокетах и тултипах (`GemTooltip`), не изменяя внутренние английские идентификаторы (`gemData.name`, `gemData.id`, `gemInstance.nameSpec`, `grantedEffectId`), которые критически важны для Calcs, генерации списков способностей и обратной совместимости сохранений билдов XML / pobb.in.

Источники данных:
- `PoE2-Localization-Extractor/exports/skill_gems_ru_validation/skill_gems.json` (1,191 запись, официальный перевод PoE2).
- `PoE2-Localization-Extractor/exports/base_items_ru_validation_retry8/base_items.json` (5,496 записей).
- Сопоставление с `PathOfBuilding-PoE2/src/Data/Gems.lua`: 967 из 967 камней (100.0% покрытие всех активных навыков и саппортов по `gameId` и `grantedEffectId`).

Решения:
1. **Модуль `src/Data/GemNamesRU.lua`:**
   - Таблица `byName`: `["English Name"] = "Русское название"` (959 уникальных имен гемов).
   - Таблица `byGameId`: `["Metadata/Items/Gems/..."] = "Русское название"` (1,750 ID камней умений и саппортов).
   - Таблица `gemTypes`: русские названия категорий камней (`Spell` -> `Чары`, `Support` -> `Поддержка`, `Attack` -> `Атака`, `Warcry` -> `Боевой клич` и др.).
   - Метод `GemNamesRU:Get(gemOrName)`: универсальный резолв с безопасным фолбеком на английский оригинал.
2. **Тултипы камней (`GemTooltip.lua` -> `AddGemTooltip`):**
   - Управляется `main.itemLanguage` (EN / RU / DUAL):
     - **EN:** оригинальное имя и категория.
     - **RU:** русское название камня крупно и русская категория.
     - **DUAL:** 1-я строка русское название крупно (размер 24), 2-я строка оригинальное английское название серым цветом `^8` (размер 16), категория `Чары (Spell)`.
3. **Отображение в сокетах умений (`GemSelectControl.lua`):**
   - Свойство `inactiveText`: когда поле выбора камня в сокете не редактируется, выводится локализованное название:
     - В `DUAL`: `Кольцо льда ^8(Ice Nova)` / `Залповый огонь I ^8(Multishot I)`.
     - В `RU`: `Кольцо льда`.
     - В `EN`: `Ice Nova`.
   - Внутренний буфер `self.buf` и `gemInstance.nameSpec` хранят оригинальное английское имя для билда.
   - В выпадающем списке выбора камней отображается перевод с английским подзаголовком.
4. **Двуязычный поиск камней (`GemSelectControl.lua` -> `BuildList`):**
   - Расширен паттерн допустимых символов `EditControl` (`^ %a':-%z\128-\255`), разрешающий ввод русских букв в поле поиска сокета.
   - Поиск камней работает и по-английски, и по-русски с регистронезависимым поиском UTF-8 через `lua-utf8`.

Верификация:
- Харнес `harness_batch14_gemloc.lua` — **43/43 PASS** (host.exe).
- Регрессионный сьют: batch 8-14 — **415/415 PASS (100%)**.
- Снапшот: `Snapshots/PoE2-GemLocalization-20261111/`.

## [D-026] Русская локализация свойств и модов предметов (Item Modifiers Localization)
Дата: 2026-11-11
Статус: ПРИНЯТО / РЕАЛИЗОВАНО
Компонент: `PathOfBuilding-PoE2` (ветка `dev`)
Связанные решения: D-025 (Gems Localization), D-024 (Passive Tree Localization), D-023 (Item Localization & Dual Tooltips), D-022.

Контекст: требуется локализовать строки свойств предметов (имплиситы, префиксы, суффиксы, свойства осквернения, руны и чары) в интерфейсе предметов и тултипах, не ломая внутренний механизм парсинга модов в `ModDB`, расчеты калькулятора Calcs и формат экспорта билдов.

Источники данных:
- `PoE2-Localization-Extractor/exports/mods_ru_validation/mods.json` (16,911 модов с официальным переводом игры PoE2).
- Сопоставление с базами модов `src/Data/Mod*.lua` (ModItem, ModItemExclusive, ModJewel, ModFlask, ModCharm, ModCorrupted, ModVeiled): 9,083 мода сопоставлены по побайтово точным ID (100.0%).

Решения:
1. **Дизайн тултипа в режиме DUAL (Компактный гибрид — согласовано с владельцем):**
   - Заголовок предмета и база остаются двухстрочными DUAL (русское название крупно + серый английский подзаголовок).
   - Строки модов на карточке выводятся на русском языке в официальной терминологии PoE2.
   - Карточка предмета не раздувается по высоте в 2 раза, оставаясь компактной и читаемой.
   - При зажатии `Alt` (`launch.devModeAlt = true`) в детальном описании аффиксов выводится оригинальная английская строка мода.
2. **Модуль `src/Data/ModTranslationsRU.lua`:**
   - Таблица `exact`: 642 точные фразы модов (`Cannot be Frozen` -> `Нельзя заморозить`, `Hits can't be Evaded` -> `Удары нельзя предотвратить`, `Veiled Prefix` -> `Завуалированный префикс` и др.).
   - Таблица `templates`: 3,428 шаблонов числовых свойств (`to maximum Life` -> `к максимуму здоровья`, `% to Fire Resistance` -> `% к сопротивлению огню`, `% increased Attack Speed` -> `% повышение скорости атаки` и др.).
   - Таблица `specialRules`: специализированные правила для комплексных выражений добавленного урона (`Adds X to Y Physical/Fire/Cold/Lightning/Chaos Damage [to Attacks/Spells]`).
   - Метод `ModTranslationsRU:Translate(line)`: быстрый O(1) поиск и шаблонизация с подстановкой чисел/диапазонов и безопасным фолбеком на английский оригинал.
3. **Слой отображения (`src/Modules/ItemTools.lua` -> `itemLib.formatModLine`):**
   - Перевод накладывается на отображаемую строку `line` непосредственно перед возвратом `colorCode..line`.
   - Внутренний объект `modLine.line` и структуры `modLine.modList` остаются на английском языке.

Верификация:
- Харнес `harness_batch15_modloc.lua` — **37/37 PASS** (host.exe).
- Регрессионный сьют: batch 8-15 — **452/452 PASS (100%)**.
- Снапшот: `Snapshots/PoE2-ModLocalization-20261111/`.

## D-027: Масштабирование шрифта кириллицы и полная локализация заголовков предметов (2026-11-11)

Контекст:
Владелец обратил внимание на то, что русский шрифт в тултипах визуально мельче английского текста Fontin SmallCaps, а также в карточке предмета оставались непереведённые элементы шапки (урон, защита, гнёзда, осквернение) и строка требований имела формат Requires Level 65, 120 Str, 85 Dex.

Решения:
1. Масштабирование шрифта C++ (SimpleGraphic-Next engine/render/r_font.cpp):
   - В структуру r_font_c введен fallbackSlots с раздельным хранением FallbackFace и коэффициента масштабирования scale.
   - Для слотов SmallCaps (Fontin SmallCaps, Fontin SmallCaps Italic) масштаб кириллического fallback увеличен до 1.25, что выравнивает оптическую высоту русских строчных букв с английской капителью.
   - Для обычного Fontin установлен масштаб 1.12.
   - Пересобран SimpleGraphic.dll (RelWithDebInfo/x64, CMake MSVC) и развернут в runtime/ и smoke/pob2lua/.
2. Локализация строки требований предметов и камней (src/Modules/Build.lua):
   - Формат в RU/DUAL: Требования: Уровень 65, 120 Силы, 85 Ловкости (вместо Requires Level 65, 120 Str, 85 Dex).
   - В тултипах камней: Требования: Уровень 20, 155 Силы.
3. Локализация свойств предметов в тултипе (src/Classes/ItemsTab.lua):
   - Переведены параметры оружия (Физический урон, Урон от стихий, Урон от хаоса, Общий урон в сек., Шанс критического удара, Атак в секунду, Время перезарядки, Дальность оружия).
   - Переведены защитные характеристики брони (Качество, Шанс блока, Броня, Уклонение, Энергетический щит, Рунический оберег).
   - Переведены свойства флаконов (Восстанавливает X здоровья за Y секунды, Мгновенно восстанавливает, Тратит X из Y зарядов).
   - Переведены служебные метки (Гнёзда: S S, Уровень талисмана, Осквернено, Дважды осквернено, Отражено, Освящено).
4. Сохранение тегов модов в ModTranslationsRU:Translate:
   - Извлекаются все ведущие теги ({crafted}, {implicit}, {fractured}, {range:0.5}), переводится текст мода, затем теги возвращаются на место.

Верификация:
- Сборка C++ SimpleGraphic.dll успешна (MSBuild 0 ошибок).
- Харнес harness_batch15_modloc.lua — 42/42 PASS.
- Полный регрессионный сьют: batch 8-15 — 457/457 PASS (100%).
- Снапшот: Snapshots/PoE2-ItemFontAndHeaderLoc-20261111/.

## D-028: Точная калибровка базовой линии цифр и полная локализация самоцветов (2026-11-11)

Контекст:
Владелец предоставил скриншоты, демонстрирующие:
1. Цифры и кириллический текст находились на разной высоте: цифры из Fontin SmallCaps сидели визуально выше кириллических букв.
2. Не были переведены самоцветы (Jewel): базы (Ruby, Diamond, Time-Lost), категории, радиусы, уникальные самоцветы и их уникальные свойства.

Решения:
1. Точная калибровка базовой линии в C++ (SimpleGraphic-Next engine/render/r_font.cpp):
   - Замерен физический растр цифр 0-9 в Fontin SmallCaps.tgf: baseline находится на высоте 74% от высоты кегля (13.3px при h=18).
   - Векторные глифы Noto Sans из-за формулы ascent * scale располагались с baseline = 19px, то есть на 5.7px ниже цифр.
   - Внедрен yOffsetFactor = -0.30f для SmallCaps (-5px при h=18) и -0.20f для Fontin (-4px), что обеспечивает бесшовное совпадение базовой линии кириллицы и латинских цифр/символов.
   - SimpleGraphic.dll пересобран через MSVC/CMake в RelWithDebInfo и скопирован в smoke/pob2lua/.
2. Полная локализация самоцветов (Jewels):
   - Базы в ItemNamesRU: Ruby (Рубин), Emerald (Изумруд), Sapphire (Сапфир), Diamond (Алмаз), Time-Lost (Забытый рубин/изумруд/сапфир/алмаз), Timeless Jewel (Вневременный самоцвет).
   - Поддержка составных названий Title, Base в ItemNamesRU:Get() для отображения в списках (The Adorned, Diamond -> Былой блеск, Алмаз).
   - Радиусы в ItemsTab.lua: Very Small (Очень малый), Small (Малый), Medium (Средний), Large (Большой), Very Large (Очень большой), Massive (Огромный), Variable (Переменный).
   - Все свойства и уникальные механики в ModTranslationsRU:
     - Controlled Metamorphosis: Only affects Passives in <Ring> (Влияет только на пассивные умения внутри <кольца>).
     - The Adorned: (0-150)% increased Effect of Jewel Socket Passive Skills containing Corrupted Magic Jewels.
     - Voices: Allocates <N> Sinister Jewel sockets.
     - Split Personality: Can Allocate Passive Skills from the <Class> starting point.
     - Timeless: покорение калгурами/Бездной, деяния Вораны/Медведя/Олрота, дань Аманаму, Historic (Исторический).
     - Time-Lost: Small/Notable Passive Skills in Radius also grant <mod>.
3. Локализация интерфейса базы уникальных предметов:
   - В DropDownControl добавлена поддержка labelFunc.
   - В ItemDBControl локализованы выпадающие списки слотов, типов, лиг и требований.
   - В ItemListControl и ItemDBControl имена предметов в списке отображаются на русском языке.

Верификация:
- Сборка C++ SimpleGraphic.dll успешна (MSBuild 0 ошибок).
- Харнес harness_batch15_modloc.lua — 52/52 PASS (100%).
- Регрессионный сьют: batch 8-15 — 467/467 PASS (100%).
- Снапшот: Snapshots/Backup-Jewel-FontAlign-20261111-123518/.

## D-029: Локализация редких и иных предметов, шаблонов Rares.lua, свойств талисманов и пассивных умений (2026-11-11)

Контекст:
Владелец предоставил скриншоты двух предметов:
1. Редкий амулет ("GLOOM CHARM (ABSENT AMULET)"):
   - Название редкого предмета "GLOOM CHARM" не переводилось.
   - Тип предмета "AMULET" отображался на английском.
   - Свойства "Allocates Agonising Calamity", "40% increased Chaos Damage while affected by Herald of Plague", "Grants Skill: Level 18 Eternal Rage" не переводились.
   - Разница характеристик ("Tip: Press Ctrl+D...", "Removing this item...") и названия параметров не были локализованы.
2. Талисман ("FORSAKEN BANGLE (AMETHYST CHARM)"):
   - Тип "CHARM" оставался на английском.
   - Строка не поддерживаемых PoB свойств содержала английский суффикс "(Not supported in PoB yet)", ломая перевод самой строки в formatModLine.

Решения:
1. Архитектура генерации имен редких предметов (PoE Rare Naming Formula):
   - В PoE имена редких предметов генерируются по схеме `[Prefix] [Suffix]`.
   - В русской локализации PoE это переводится по правилу: `[Suffix_RU (Именительный падеж)] + " " + [Prefix_RU (Родительный падеж)]`.
   - В `ItemNamesRU.lua` внедрены словари `rarePrefixes` (77 префиксов в родительном падеже: Gloom -> мрака, Wrath -> гнева, Dusk -> заката, Death -> смерти и др.) и `rareSuffixes` (248 суффиксов в именительном падеже: Charm -> Оберег, Band -> Кольцо, Loop -> Петля, Grasp -> Хватка и др.).
   - При парсинге 2-словных имен редких предметов динамически формируется аутентичное русское название: `Gloom Charm` -> `Оберег мрака`, `Wrath Band` -> `Кольцо гнева`, `Dusk Loop` -> `Петля заката`.
2. Шаблоны редких предметов (src/Data/Rares.lua):
   - Все 75 уникальных заголовков шаблонов редких предметов из `Rares.lua` каталогизированы и переведены в `ItemNamesRU.map` (`Armour Helmet` -> `Шлем с броней`, `+4 Physical Bow` -> `+4 Физический лук`, `Attribute Amulet` -> `Амулет с характеристиками` и др.).
   - Добавлены 99 базовых предметов из `Rares.lua` (`Imperial Greathelm` -> `Имперский большой шлем`, `Freebooter Cap` -> `Шапка флибустьера` и др.).
   - Реализована динамическая локализация вариаций баз:
     - `Runeforged <Base>` -> `Руннокованый <Base_RU>`
     - `Runemastered <Base>` -> `Рунномастерский <Base_RU>`
     - `Superior <Base>` -> `Качественный <Base_RU>`
3. Магические аффиксы и флаконы:
   - Внедрены `ItemNamesRU.magicPrefixes` и `magicSuffixes` (`Potent Ultimate Life Flask of the Distiller` -> `Крепкий Совершенный флакон жизни дистиллятора`).
4. Подсказка и тип предмета в тултипе (ItemsTab.lua):
   - Тип предмета приводится к верхнему регистру через `toUpperRu(typeStr)` (`АМУЛЕТ`, `ОБЕРЕГ`, `КОЛЬЦО`, `ШЛЕМ`), сохраняя визуальный стиль SmallCaps.
   - Свойства даруемых пассивных умений (нотаблов / масел) теперь переводятся через `ModTranslationsRU:Translate(stat)`.
5. Исправление конвейера в ItemTools.lua:
   - В `itemLib.formatModLine` перевод через `ModTranslationsRU` теперь вызывается ДО добавления суффикса неподдерживаемых модов.
   - Для неподдерживаемых свойств на русском языке выводится локализованный суффикс ` (Пока не поддерживается в PoB)`.
6. Свойства талисманов и даруемых умений (ModTranslationsRU.lua):
   - `Allocates <Notable>` -> `Дарует: <Notable_RU>` с поддержкой словаря `ModTranslationsRU.notables` (включая `Agonising Calamity` -> `Мучительное бедствие`).
   - `Grants Skill: Level <N> <Skill>` -> `Дарует умение: <Skill_RU> <N> уровня` с интеграцией `GemNamesRU`.
   - Поддержка модификаторов вестников (`Herald of Plague` -> `Вестник чумы`, `Herald of Blood` -> `Вестник крови`).

Верификация:
- Интеграционный тест `harness_batch15_modloc.lua` расширен новыми проверками: 70 PASS, 0 FAIL (100%).

## D-030: Массовая экстракция UI-интерфейса PoB2 и архитектура UITranslationsRU (2026-11-11)

Контекст:
Пользователь инициировал задачу полного перевода интерфейса всего приложения с использованием OpenCode и LLM (Nemotron-3.5 120B).
Критическое архитектурное требование: не допустить повреждения расчетного движка Calcs/ModDB/StatParser. Перевод интерфейса должен работать исключительно как слой отображения (Display Layer).

Решения:
1. Создан Python-экстрактор (`scratch/extract_all_ui_strings.py`):
   - Просканированы все подсистемы: `ConfigOptions.lua`, `BuildDisplayStats.lua`, `CalcsTab.lua`, `CalcBreakdownControl.lua`, все классы `Classes/*.lua` (Items, Skills, Tree, Party, Import/Export, Options) и модули `Build.lua`, `Main.lua`.
   - Извлечены 1,674 элемента интерфейса (1,590 уникальных строк) по 44 категориям.
   - Сгенерированы два формата:
     - `src/Data/ui_strings_flat.json`: плоский ключ-значение для прямого скормливания модели Nemotron.
     - `src/Data/ui_strings_to_translate.json`: структурированный формат с указанием исходного файла, контекста и категории.
2. Создан архитектурный модуль `src/Data/UITranslationsRU.lua`:
   - Безопасный интерфейс `UITranslationsRU:Get(text)` с сохранением цветовых кодов PoB (`^7`, `^8`, `^xFFFF30`).
   - Функция динамической подгрузки `UITranslationsRU:LoadJSON(jsonStr)`.
   - Fallback на оригинальную английскую строку при отсутствии перевода или в режиме EN.
3. Разработан скрипт слияния (`scratch/merge_translations.py`):
   - При получении переведённого файла `ui_strings_ru.json` от OpenCode скрипт автоматически внедряет словарь в `UITranslationsRU.map`.

Верификация:
- Смоук-тест `test_ui_trans.lua` через `host.exe` подтвердил корректную работу поиска и экранирования цветовых префиксов.


---

## D-031: Исправление синтаксиса экранирования UITranslationsRU и интеграция Sidebar Display Stats

Дата: 2026-11-11.
Статус: Принято.

Контекст:
При загрузке src/Data/UITranslationsRU.lua происходил синтаксический сбой Data/UITranslationsRU.lua:822: ']' expected near 'Удаляет', вызванный тем, что подсказки регулярных выражений, заканчивающиеся на обратный слэш, не были экранированы в строковом литерале Lua. Также требовалось подключить UITranslationsRU к Build.lua (Sidebar Display Stats).

Решение:
1. В src/Data/UITranslationsRU.lua экранированы концевые слэши на строках 822 и 1060 (\\). Синтаксис верифицирован нативно в host.exe (loadfile -> OK).
2. В src/Modules/Build.lua подключен UITranslationsRU:Get(statData.label) для левой боковой панели характеристик (AddDisplayStatList) и при сравнении статов (statLabelMap fallback).

Верификация:
- test_uitrans_syntax.lua через host.exe: компиляция успешна (OK).
- Регрессионный сьют run_batch15_modloc.lua: PASS.

---

## D-032: Устранение обрезания текста левого сайдбара и полная локализация слотов экипировки и выпадающих списков

Дата: 2026-11-11.
Статус: Принято.

Контекст:
На скриншоте пользователя обнаружено:
1. Выход русского текста за левую границу экрана в левом сайдбаре (`...тор скорости передвижения`, `...фективный пул попаданий`, `...езарезервированный Дух`, `...елич. Уклонения от Древа` и т.д.). Причина: `statBox` в `Build.lua:490` использует правую границу колонки `x = 170, align = "RIGHT_X"`. Русские фразы длиннее 170px уходят в отрицательные X-координаты.
2. Метки слотов экипировки (`Weapon 1:`, `Helmet:`, `Body Armour:`, `Socket #1:` и др.) оставались на английском, так как в `ItemSlotControl.lua:171` рисовались без вызова словаря локализации.
3. Выпадающие списки экипировки (`ItemSlotControl.lua:126`, `DropDownControl.lua:378, 480`) показывали английские названия предметов и самоцветов, так как искали строки только в UI-словаре, минуя `ItemNamesRU`.
4. Часть редких самоцветов и баз не имели словарных префиксов/суффиксов (`Pandemonium Solace`, `Maelstrom Ornament`, `Exceptional ...`, `Seething ... of the Wide`).

Решение:
1. В `src/Modules/Build.lua:490` правый якорь первой колонки расширен со 170px до 185px (`x = 185, align = "RIGHT_X"`), колонка значений смещена на `x = 190`.
2. В `src/Data/UITranslationsRU.lua` громоздкие формулировки сокращены до компактных («Скор. передвижения», «Эфф. запас здоровья», «Трата здоровья/с», «Свободный дух», «% брони от древа» и др.).
3. В `src/Classes/ItemSlotControl.lua:171` метка слота обернута в `UITranslationsRU:Get(self.label)`.
4. В `src/Classes/ItemSlotControl.lua:126` и `src/Classes/DropDownControl.lua:378, 480` подключен поиск локализованных названий предметов через `ItemNamesRU:Get`.
5. В `src/Data/ItemNamesRU.lua` добавлены префиксы и суффиксы для самоцветов и редких предметов (`Solace`, `Ornament`, `Blast`, `Refuge`, `Talons`, `Exceptional`, `of the Wide`).
6. В `src/Modules/Build.lua:2414, 2434` локализованы строки DPS (`Best Poison DPS` -> «Лучший DPS яда») и источники (`from <Source>` -> «от <Источник>»).

Верификация:
- `test_item_translate.lua` через `smoke/pob2lua/host.exe`: 100% тестовых слотов, баз, самоцветов и флаконов успешно переводятся.
- `test_uitrans_syntax.lua`: синтаксис `UITranslationsRU.lua` валиден (OK).

---

## D-034: Интеграция полного перевода UI (OpenCode), устранение Mojibake и верификация

Дата: 2026-11-11.
Статус: Принято.

Контекст:
Модель Nemotron в OpenCode перевела 1,590 ключей интерфейса в `src/Data/ui_strings_ru.json`, однако при сохранении возникли:
1. Двойное UTF-8 кодирование (mojibake cp1251) и двойной BOM в `ui_strings_ru.json`.
2. В нескольких фрагментах Lua-кода отсутствовали двоеточия значений (`: ""`), что ломало валидность JSON.
3. Метод `UITranslationsRU:LoadJSON` перезаписывал защищённые компактные сокращения левого сайдбара длинными фразами, что приводило к риску повторного переполнения (clipping).
4. В окружении OpenCode отсутствовал доступ к `build-SimpleGraphic-Next/` для запуска нативного `host.exe`.

Решение:
1. Разработан скрипт `scratch/fix_ru_json.py`:
   - Устранён mojibake во всех 1,563 значениях.
   - Синтаксис JSON приведен к 100% валидности (1,083 переведённые строки интерфейса, 480 кодовых фрагментов оставлены пустыми).
   - Файл сохранён в UTF-8 без BOM.
2. В `src/Data/UITranslationsRU.lua:LoadJSON` добавлено правило: ручные компактные записи из `self.map` имеют наивысший приоритет и не перезаписываются JSON-словарем (`if not self.map[k] then self.map[k] = v end`), что гарантирует сохранение Anti-Overflow в сайдбаре.
3. Запущены нативные тесты через `build-SimpleGraphic-Next/smoke/pob2lua/host.exe`:
   - `test_load_ru_json.lua`: подгрузка 216 КБ JSON прошла успешно, проверены термины `Настройки`, `Заметки`, `Импорт/Экспорт`, `Древо`, `Броня`, `Энергетический щит`, компактный `Эфф. запас здоровья`.
   - `test_uitrans_syntax.lua`: синтаксис Lua-словаря валиден (OK).
   - Регрессионный сьют `run_batch15_modloc.lua`: **70 PASS, 0 FAIL**.

---

## D-035: Глобальный рендеринг-хук UI и сплошное покрытие экранов PoB2

Дата: 2026-11-11.
Статус: Принято.

Контекст:
Многие контролы в `ImportTab`, `ConfigTab`, `CalcsTab`, `SkillsTab`, `PartyTab`, `CompareTab` используют прямое форматирование строк и не вызывают `UITranslationsRU:Get()` индивидуально. Точечная модификация каждого класса контрола несла риски регрессий.

Решение:
1. В `src/Modules/Main.lua` внедрён прозрачный дисплейный перехватчик `DrawString` и `DrawStringWidth`.
2. Любой текст перед передачей в C++ SimpleGraphic пропускается через безопасный `UITranslationsRU:Get(text)`.
3. Внутренняя логика (расчеты, сохранение в XML, экспортные ссылки) остается полностью нетронутой на английском языке.

---

## D-037: Терминология перевода Calcs / Config / Tree-Node строк и Sap vs Shock

Дата: 2026-11-11.
Статус: Принято.

Контекст:
Появились три файла-задания перевода (`src/Data/to_translate_calcs.json`,
`to_translate_config.json`, `to_translate_tree_nodes.json`) с пустыми
значениями `""`. В русской локализации PoE2 состояния Shock и Sap —
разные эффекты с одним цветом `^xADAA47` в исходных строках Config.

Решение:
1. Терминология строго официальная: Броня, Энергетический щит, Уклонение,
   Отклонение, Жизнь, Мана, Дух; Огонь/Холод/Молния/Хаос/Физ. урон;
   Кровотечение, Ошеломление (Shock), Воспламенение (Ignite), Охлаждение
   (Chill), Заморозка (Freeze), Опаление (Scorch), Хрупкость (Brittle),
   Истощение (Sap), Электризация (Electrocute), Пригвождение (Pin).
2. Для коротких строк таблицы Calcs — компактные сокращения
   («Сниж. физ. урона», «База от снаряжения», «Сопр. хаосу», «Доп. рука»,
   «Осн. ...» для MH-метрик), чтобы не выходить за границы ячеек.
3. Плейсхолдеры `#`, `%`, `:`, `/`, `(`, `)`, `\n` и цветовые теги
   `^xRRGGBB`/`^7` сохраняются; допускается добавление закрывающего `^7`
   при перестановке слов для корректного возврата к белому цвету.
4. Ключи JSON не изменяются, включая оригинальные опечатки
   (`Devestating Devices`, `Beastial Skin`).
5. Открытый пункт: в `UITranslationsRU.lua` Sap переведён как
   «Ошеломление»; при интеграции новых файлов унифицировать на
   «Истощение» во всём проекте.

Проверка: Node.js `JSON.parse` — валидно, ключей 544/132/1189,
пустых значений нет, дубликатов нет, UTF-8 без BOM.

## D-036: Динамические шаблоны UI, нормализация CRLF и полное закрытие 8 экранов

Дата: 2026-11-11.
Статус: Принято.

Контекст:
Анализ 8 скриншотов пользователя (снятых на реальной сборке) выявил остаточные блоки на английском языке:
- Многострочные справочные тексты (ItemsTab) не сопоставлялись из-за переносов строк Windows `\r\n`.
- Динамические префиксы контролов («Character import status: <Status>», «Save location: <Path>», «Skill Hit Damage: <DPS>», «LEVEL: %d», «%d points to node») требовали регулярных выражений.
- Моды дерева пассивных умений требовали подключения `ModTranslationsRU` в `PassiveTreeView.lua`.

Решение:
1. В `src/Data/UITranslationsRU.lua` добавлено свыше 130 точных переводов для всех вкладок (Import, Config, Skills, Items, Calcs, Party, Compare).
2. В `UITranslationsRU:Get(text)` внедрена нормализация `\r\n` -> `\n`, поддержка составных строк (суффиксы с двоеточием) и динамических регулярных выражений для статусов, уровней камней, пробитий и наград за квесты.
3. Верификация через `build-SimpleGraphic-Next/smoke/pob2lua/host.exe`:
   - Синтаксис Lua-модулей — OK.
   - Тесты многострочных блоков и динамических шаблонов — PASS.
   - Регрессионный тест `run_batch15_modloc.lua`: 70/70 PASS.

---

## D-038: Интеграция полного перевода OpenCode (Calcs/Config/Tree), парсер суффиксов цвета и унификация Sap

Дата: 2026-11-11.
Статус: Принято.

Контекст:
После перевода OpenCode файлов `to_translate_calcs.json` (544), `to_translate_config.json` (132) и `to_translate_tree_nodes.json` (1189) требовалась:
1. Надежная интеграция без runtime-зависимости от `dkjson`.
2. Поддержка формата строк из `CalcSections.lua` (строки оканчиваются на `"^7:"` или точку `.`).
3. Разрешение терминологического конфликта Sap («Ошеломление» $\rightarrow$ «Истощение»).

Решение:
1. В `src/Data/UITranslationsRU.lua` напрямую интегрированы 1 822 перевода (при сохранении приоритета ручных компактных сокращений сайдбара); в `src/Data/TreeNodesRU.lua` добавлено 29 недостающих нодов.
2. Термин `Sap` унифицирован на «Истощение» во всех ключах `UITranslationsRU.lua`.
3. В `UITranslationsRU:Get()` реализован парсинг завершающего цветового кода (`^7:`) и завершающей точки (`.`), что полностью открыло перевод таблиц расчётов в `CalcSectionControl`.
4. Верификация в `smoke/pob2lua/host.exe`:
   - `UITranslationsRU.lua` и `TreeNodesRU.lua`: синтаксис OK.
   - Выборка Calcs (`^7Base from Gear^7:`, `^7Phys. Dmg. Reduct.^7:`, `^7Armour Defense^7:` и др.) и Sap: 100% PASS.
   - `run_batch15_modloc.lua`: 70/70 PASS.
## D-040 (2026-11-11): Переработка вкладки «Расчёты» — вёрстка, авто-схлопывание, цветовое зонирование
- **Контекст:** русские ROW-подписи (268 из 476) превышали жёсткий столбец 130–134px и обрезались; 6-колоночные таблицы урона переполнялись диапазонами; пустые секции с нулями занимали десятки строк.
- **Решение (Вариант А):** labelWidth 132..154px (формула `132 + (viewWidth-700)*22/200`, clamp); адаптивный colWidth 230..275 при окне >= 1340px; проверка «одна колонка» через `section.widthCols == 1`, а не сравнение ширины; 6-колоночные таблицы урона распределяют ширину поровну; тинты колонок урона — литералы в `ThemeFluent.calcSection.damageTints`/`damageHeaderColors` (Resolve их не затирает — палитронезависимо, по ТЗ); нулевые ячейки → `^8`, « to » → «–» и 12px только при переполнении (визуально, формулы не тронуты).
- **Решение (Вариант Б):** тумблер «Скрывать пустые» (`hideEmptySections`, по умолчанию true, сохраняется в XML); авто-схлопывание подсекции при чисто-нулевом extra (`isZeroSummaryText`: все числа строки равны 0 и хотя бы одно есть; «2,851/2,851» и «x 1.27» — не ноль); `userToggled` забирает управление у автоматики; ненулевое значение автоматически раскрывает блок.
- **Отклонение от ТЗ:** «Enemy Ail. Thresh.» → «Порог недугов» (вариант ТЗ «Порог недугов врага» = 161px, не влезал в 148px-бюджет ROW-меток; «врага» однозначно из заголовка секции).
- **Отклонение от ТЗ:** сокращение заголовка «Recoup and Hit Taken Over Time» → «Восполн. и удар по вр.» (258.8px > бюджета HDR 225px).
- **Инструмент:** ширина метрик — Python-валидатор `scratch/validate_label_widths.py` (fontTools, advance-метрики notosanssc-regular.ttf, слот VAR) по выводу Lua-аудитора `scratch/audit_calc_labels.lua`; `DrawStringWidth` в smoke-host вне кадрового цикла не работает (Renderer not initialised), поэтому host.exe используется только для аудита пар EN/RU.
- **Статус:** реализовано и проверено (синтаксис 5/5, 19/19 граничных тестов zero-предиката, batch15 70/70 PASS, валидатор ширины 0 wide).

## D-042: Total audit & completion of Russian localization (2026-11-11)

**Scope:** TZ_OPENCODE_TOTAL_AUDIT_AND_SKILLS_RU.md — sections 1-5 (UI, Tree, Skills, Config) + section 5 verification.

**Decisions:**
1. Display-Only layer preserved: no internal ID / Calc* formula / XML-format changes; CalcSection `.label` not renamed; `Древняя эгида` kept intact.
2. Bilingual fallback via `DrawString` hook (`Main.lua:63-90`) — `UITranslationsRU:Get(text)` is the single translation entry point; direct dictionary keys must match exactly; concatenated/runtime-built strings use dynamic patterns in `Get()`.
3. `Get()` preserves leading whitespace into `colorPrefix` and trailing whitespace/colon into `trailingSuffix` on all direct-return paths; inner color-tag fallback strips ALL `^`/`^x...` tags and retries `self.map[tagless]`.
4. GemTooltip lines (Tier/Level/Quality/Cost/Reservation/Cooldown/Can Store/Soul Gain Prevention/Attack Time/Attack Damage/Critical Hit Chance/Requires/Category/weapon requirements/Set N:) translated via dynamic patterns in `Get()`; cost resource forms mapped (`{0} Mana` → «Маны», `{0}% Mana` → «% Маны», etc.); weapon names mapped via `weapRu` table with `/` splitting.
5. `SkillDescriptionsRU.lua` — new module with 980 skill descriptions (indexed Python dicts merged), `Get(text)` with fallback to original English; connected in `GemTooltip.lua:216-219` when `itemLang ~= "EN"`.
6. `addDescriptionLine` passes `line` through `ModTranslationsRU:Translate(line)` when `itemLang ~= "EN"`.
7. `SkillListControl.GetRowValue` localises `displayLabel` via `GemNamesRU:Get()` (comma-split parts); suffixes: «(Откл.)», «(Активно)», «(Принуд. активно)», «(FullDPS)»; model not touched.
8. `SkillsTab.lua`: «Include in Full DPS:» indent 145→165; labels localised via dictionary (no width regression expected; ROW-ме labels calibrated to 148px).
9. Backups: 10 files in `backup_ui_fix/20261111-213000-total-audit/` before edits. No git commit/reset/clean/checkout.

---

## D-043: Интеграция официальной GGPK-базы StatDescriptionsRU и очистка SkillDescriptionsRU

Дата: 2026-11-11.
Статус: Принято.

Контекст:
После тотального аудита D-042 в `GemTooltip` строки статов умений и камней поддержки передавались через `ModTranslationsRU` (содержащий в основном моды предметов), а в сгенерированном моделью `SkillDescriptionsRU.lua` оставались артефакты (CJK/немецкие/испанские вкрапления), тогда как в `PoE2-Localization-Extractor/exports/` уже лежали официальные русские выгрузки GGPK.

Решение:
1. Из `PoE2-Localization-Extractor/exports/stat_translations_ru_validation/stat_translations/` сгенерирован `src/Data/StatDescriptionsRU.lua` (372 scope, 5 286 описателей статов в 18 чанках для укладки в лимит 200 локалов на функцию LuaJIT).
2. В `src/Modules/StatDescriber.lua` подключён display-only перехват `StatDescriptionsRU:Get(scopeName, descriptor.description.stats)` после проверки `matchLimit` на английском дескрипторе (сохраняя `gem_quality`-фильтрацию и `applySpecial`).
3. В `src/Data/SkillDescriptionsRU.lua` 518 описаний камней поддержки заменены на официальный `support_text` из `skill_gems.json`, а оставшиеся 25 повреждённых строк переведены на чистый русский язык.
4. В `src/Classes/SkillListControl.lua` добавлено уважение флага `main.itemLanguage == "EN"` для названий групп и суффиксов `(Disabled)`/`(Active)`.
5. Верификация в `host.exe`: синтаксис 8/8 модулей OK; E2E `StatDescriber` RU/EN switch PASS; `calcs_check.lua` ALL PASS; `batch13` 34/34 PASS; `batch14` 43/43 PASS; `batch15` 70/70 PASS.

---

## D-044: Точечное устранение дефектов локализации и вёрстки по 5 скриншотам (2026-11-12)

Дата: 2026-11-12.
Статус: Принято.

Контекст:
После D-042/D-043 пользователь прислал 5 скриншотов с оставшимися английскими строками, дублями заголовков, наложениями и артефактами форматирования в `GemTooltip`, вкладке `Skills`, секции `Награды за квесты` (`Config`), тултипе нодов дерева и тултипе предметов. Попутно аудит выявил, что `src/Data/to_translate_audit_ui.json` (542 ключа) содержал только пустые значения, из-за чего `Usage Tips:` и опции `QuestRewards` оставались непереведёнными, а в названиях квестов Акта 3/4/Интерлюдии 2 в словаре имелись опечатки.

Решение:
1. В `scratch/generate_stat_descriptions_ru.py` удалён разделитель `@` из GGPK-строк (`s.replace("@", ": ")`) и добавлен fallback-поиск `"specific_skill_stat_descriptions/" .. norm` в `StatDescriptionsRU:Get()`, устраняя английские статы специфических умений (включая *Стену щитов / Shield Wall*).
2. В `GemTooltip.lua` добавлен перевод строки тегов (`GEM_TAGS_RU`), локализован `(Not supported in PoB yet)`, а в `DUAL`-режиме возвращён серый английский подзаголовок `^8(enTitle)`. В `UITranslationsRU.lua` убран повтор `%` для `Attack Damage` / `Attack Speed` и добавлен шаблон `Main Skill: ...`.
3. В `SkillsTab.lua` увеличен `optionInputsY` (`45 → 64`), чтобы блок `Usage Tips:` не перекрывал шапку «Параметры камней»; в `UITranslationsRU.lua` добавлен перевод `Usage Tips:` и компактные подписи (`Камни поддержки:`, `Устаревшие камни:`), в `SkillListControl.lua` — `(Полн.DPS)`.
4. В `UITranslationsRU.lua` добавлены недостающие названия квестов (`Jiquani's Machinarium`, `Eye of Hinekora`, `Khari Crossing`, `Kriar Village` и др.), все опции `QuestRewards` (включая многострочные `\n\t`) и все 14 Distilled Emotions (`Tooltip.lua` теперь переводит `r.name` до `DrawStringWidth`).
5. В `ModTranslationsRU.lua`: добавлен разбор префикса `Bonded:` → `Узы:`, шаблоны пассивных модов `Electrocute`/`Shock`, 9 точных правил `Can roll ... modifiers`, правило среднего числа `Damaging Ailments deal damage <N>% faster` и экранирование `%` в `specialRules` перед `string.gsub` (чтобы `%1` вида `19%` не терял знак `%`).

Верификация (`host.exe` после финальных правок):
- `scratch/verify_5_screenshots.lua`: **44/44 PASS** (7/7 синтаксис, статы *Стены щитов*, `Attack Damage` без `%%`, `Main Skill`, `Usage Tips`, `QuestRewards`, эмоции, `Bonded:`/`Can roll`/`19% faster`).
- `calcs_check.lua`: **ALL PASS**; `batch13`: **34/34 PASS**; `batch14`: **43/43 PASS**; `batch15`: **70/70 PASS**; `test_stat_describer_e2e.lua`: **PASS**.
- Бэкапы изменённых файлов сохранены в `../backup_ui_fix/*.bak_s5` (и `.bak_post_screenshot`).

## D-045: 100% локализация дерева пассивных умений PoE2 (2026-11-12)

Дата: 2026-11-12.
Статус: Принято.

Контекст:
В `src/TreeData/0_5/tree.lua` 2 622 уникальные строки описаний статов и 2 027 уникальных имён нодов. Через существующие regex `ModTranslationsRU` переводилось только 44.6% строк статов, а `TreeNodesRU` пропускало 24 имени (включая 5 с хвостовым пробелом). Требуется 100% покрытие через официальные GGPK-данные.

Решение:
1. **Раздел 1 — `StatDescriptionsRU.lua`:** обновлён `scratch/generate_stat_descriptions_ru.py` с добавлением `passive_skill_variant_stat_descriptions.json` и фильтрацией `stat_descriptions.json` по stat_id из дерева (`tree_stat_ids.json`). Чанк размером 150 (LuaJIT лимит 200 локалов). Итого 374 scopes, 6 697 описателей.
2. **Раздел 2 — `TreeNodesRU.lua`:** добавлена trimmed-логика в `Get()` (поиск по `self.byName[name]`, затем `self.byName[name:match("^%s*(.-)%s*$")]`). Добавлены 24 отсутствующих имени (из `Default.json`, `characters.json`, `ascendancies.json`), включая 5 с хвостовым пробелом. 16 имён без RU в GGPK добавлены как явные исключения (английское имя как значение).
3. **Раздел 3 — `TreePassivesRU.lua`:** новый модуль `src/Data/TreePassivesRU.lua` (17 чанков), сгенерированный через `scratch/build_tree_passives_ru.lua` + `StatDescriptionsRU` (per-stat lookup через `host.exe`). Содержит `statsBySkill[skill]`, `flavourBySkill[skill]`, методы `GetStats(node)` / `GetFlavour(node)`.
4. **Раздел 4 — `PassiveTreeView.lua`:** добавлена загрузка `TreePassivesRU` через `pcall`. В `addModInfoToTooltip` — фолбек на `TreePassivesRU:GetStats(node)` при `ModTranslationsRU:Translate` без совпадения и нулевом `incSmallPassiveSkillEffect + localIncEffect`. Флейвор-текст берется из `TreePassivesRU:GetFlavour(node)` при `itemLang ~= "EN"`. Поиск по дереву проверяет RU строки статов.

Верификация (`host.exe` после финальных правок):
- `scratch/verify_tree100_ru.lua`: **29/29 PASS** (синтаксис 5/5, EN mode 0 изменений, имя coverage 100.00% = 2027/2027, статы coverage 98.71% = 4438/4496 узлов, ключевые ноды, RU поиск).
- `scratch/verify_5_screenshots.lua`: **44/44 PASS**.
- `run_batch13_treeloc.lua`: **34/34 PASS**; `run_batch14_gemloc.lua`: **43/43 PASS**; `run_batch15_modloc.lua`: **70/70 PASS**; `calcs_check.lua`: **ALL PASS**; `test_stat_describer_e2e.lua`: **PASS**.
- Нерешённые stat_id (без RU в GGPK): 16 шт. (например, `base_physical_damage_reduction_rating_no_display`, `ascendancy_lich_spell_damage_+%_final_when_sacrificing_energy_shield` и др.).
- Нерешённые имена нод (без RU в GGPK): 16 шт. (class-specific опции: `Attuned with Nature`, `Bastion of the Forest`, `Primal Spirit` и др.).
- Бэкапы: `backup_ui_fix/20261112-120000-tree100/` (5 файлов).

## D-046: Полный аудит и локализация всех диалоговых окон и UI (2026-11-12)

Дата: 2026-11-12.
Статус: Принято.
Компонент: `PathOfBuilding-PoE2` (ветка `dev`).
ТЗ: `TZ_OpenCode_Full_Dialogs_and_UI_Sweep.md`.

Контекст:
Требуется найти и перевести все оставшиеся непереведённые строки во всех диалоговых окнах (`OpenPopup`, `OpenConfirmPopup`, `OpenMessagePopup`) и во всём UI (`Classes/` и `Modules/`): кнопки, заголовки, чекбоксы, метки, плейсхолдеры, списки настроек, статусы и подсказки контролов.

Решение:
1. **Python-сканер `scratch/audit_ui_dialogs.py`:** сканирует все .lua в `src/Classes/` + `src/Modules/` (Export/ исключён), находит вызовы диалогов и атрибуты контролов (`label`, `tooltip`, `prompt`, `placeholder`, `tooltip:AddLine`), разделяет на статические и динамические строки (сохраняя `file:line` и шаблон).
2. **Хост-скрипт `scratch/audit_ui_dialogs_host.lua`:** загружает `UITranslationsRU.lua` через `loadfile` + `io.open` stub, прогонит все статические строки через `UITranslationsRU:Get(s)`, выводит `TOTAL`/`TRANSLATED`/`UNTRANSLATED`.
3. **UITranslationsRU.lua:** добавлено ~70 новых статических переводов (заголовки диалогов, кнопки, надписи контролов, подтверждения удаления, опции) + динамические паттерны `Get()` для ошибок файловых операций (`Couldn't open/move/rename/copy/delete/save/create '...'`), подтверждений удаления (`Are you sure...`, `Delete '...'`, `Confirm Folder Delete`), импорта/экспорта (`Importing ...`, `Build file exported successfully to:\n...`, `Error creating link:\n...`, `Warning: Importing to the current build...`), Class Change (все классы/ветки).
4. **Экранирование % в gsub:** все подставляемые аргументы экранируются через `val:gsub("%%", "%%%%")` перед `gsub`; `|` не используется в Lua-паттернах.
5. **Исключены технические строки:** имена шрифтов (`VAR`, `FONTIN`, `FIXED`), коды формата (`%d`, `%c`), URL, внутренние префиксы (`nil`).
6. **Main.lua `OpenMessagePopup`:** кнопка "Ok" использует динамическую ширину через `DrawStringWidth` (как в `OpenConfirmPopup`), чтобы длинные русские надписи не обрезались.

Верификация (`host.exe`):
- `scratch/audit_ui_dialogs_before.txt`: TOTAL=2400, TRANSLATED=1725, UNTRANSLATED=675.
- `scratch/audit_ui_dialogs_after.txt`: TOTAL=2400, TRANSLATED=1772, UNTRANSLATED=628 (+47 переводов, -47 непереведённых).
- `scratch/verify_dialogs.lua`: **58/58 PASS** (все ключевые типы диалогов, динамические сообщения, EN-режим passthrough, пустые/nil значения).
- Регрессия: `calcs_check.lua` **ALL PASS**, `run_batch13_treeloc.lua` **34/34 PASS**, `run_batch14_gemloc.lua` **43/43 PASS**, `run_batch15_modloc.lua` **70/70 PASS**, `verify_tree100_ru.lua` **29/29 PASS**, `verify_5_screenshots.lua` **44/44 PASS**, `test_stat_describer_e2e.lua` **PASS**.
- Бэкапы: `backup_ui_fix/20261112-095210-ui-dialogs-sweep/` (UITranslationsRU.lua, Main.lua, PopupDialog.lua).
- Git commit/reset/clean/checkout не выполнялись.

## D-047: Полный перевод 1 005 строк интерфейса (2026-11-12)

Дата: 2026-11-12.
Статус: Принято.
Компонент: `PathOfBuilding-PoE2` (ветка `dev`).
ТЗ: `TZ_OpenCode_Remaining_UI_100pct.md`.

Контекст:
Требуется перевести все 1 005 оставшихся непереведённых строк интерфейса, собранных в `PathOfBuilding-PoE2/scratch/ui_to_translate_clean.json`, и вмерджить их в `src/Data/UITranslationsRU.lua`.

Решение:
1. **ui_to_translate_clean.json:** все 1 005 записей заполнены (0 пустых `"ru": ""`), цветовые теги (`^7`, `^8`, `^xRRGGBB`), переносы `\n`, табы `\t`, плейсхолдеры (`%d`, `%s`, `{0}`) и терминология PoE2 сохрены точно.
2. **UITranslationsRU.lua:** +1 005 записей в `self.map` (append-only, без перезаписи существующих компактных переводов). 494 новых ключей добавлено, остальные уже присутствовали.
3. **Экранирование:** все строки экранированы через `lua_escape` (`"`, `\`, `\n`, `\t`).
4. **Технические строки:** Lua-кодовые фрагменты, внутренние идентификаторы, коды формата и цветовые коды помечены как технические исключения с русскими описаниями в скобках.

Верификация (`host.exe`):
- `scratch/verify_ui_1005.lua`: **TOTAL=1005, TRANSLATED=1005, UNTRANSLATED=0 (100.0% >= 98% порога)**.
- `scratch/verify_dialogs.lua`: **58/58 PASS**.
- `scratch/verify_5_screenshots.lua`: **44/44 PASS**.
- `scratch/verify_tree100_ru.lua`: **29/29 PASS**.
- `calcs_check.lua`: **ALL PASS**.
- `run_batch13_treeloc.lua`: **34/34 PASS**.
- `run_batch14_gemloc.lua`: **43/43 PASS**.
- `run_batch15_modloc.lua`: **70/70 PASS**.
- `test_stat_describer_e2e.lua`: **PASS**.
- Бэкапы: `backup_ui_fix/20261112-110548-ui-1005/` (UITranslationsRU.lua).
- Git commit/reset/clean/checkout не выполнялись.

## D-048: Runtime Miss Logger + системные фиксы UITranslationsRU:Get() (2026-11-12)

Дата: 2026-11-12.
Статус: Принято.
Компонент: `PathOfBuilding-PoE2` (ветка `dev`).
ТЗ: `TZ_OpenCode_Runtime_Miss_Logger.md`.

Контекст:
Переход от угадывания строк в исходниках к точному сбору всех реально непереведённых строк из живого UI + исправление 3 системных причин, из-за которых многие строки не переводятся даже при наличии частей в словаре.

Решение:
1. **UITranslationsRU.lua — убирание квадратных скобок:** Значения вида `"[PoE2]"`, `"[Maxroll]"`, `"[POBBin]"`, `"[PoeNinja]"`, `"[PoE2DB]"`, `"[MCM]"`, `"[FullDPS]"`, `"[CombinedDPS]"`, `"[TotalDPS]"`, `"[управление]"` и др. заменены на соответствующие ключи без скобок (`"PoE2"`, `"Maxroll"`, `"Control"` и т.д.).
2. **UITranslationsRU.lua — построчный fallback для `\n`:** В конце `Get()`, если текст содержит `\n`, строка разбивается по переносам, каждая часть переводится отдельно через рекурсивный `self:Get(line)` (с защитой от бесконечной рекурсии), и результат собирается обратно с сохранением `colorPrefix` и `trailingSuffix`.
3. **UITranslationsRU.lua — Label: Value fallback:** Если строка имеет вид `"Label: Value"` и левая часть не содержит кириллицы, левая часть переводится через `self.map`, правая часть через рекурсивный `self:Get()`, результат собирается с корректным разделителем.
4. **RULogger.lua (новый модуль):** `src/Modules/RULogger.lua` — лёгкий runtime miss logger:
   - Активен только когда `main.itemLanguage ~= "EN"` и `main.logUntranslatedRU ~= false`.
   - Фильтры: пустые строки, нет 2+ латинских букв, технические токены (DPS, EHP, PoB, URL, пути и т.д.), чистый русский текст не логируется.
   - Смешанные строки (русский + английский, >1 латинского слова) логируются с пометкой `[MIXED]`.
   - Дедупликация через `seen` таблицу, буфер `pending`, сброс в `untranslated_live.log` каждые 2 секунды через `GetTime()` и при `Shutdown()`.
5. **Точки перехвата:**
   - `Main.lua` → `translateForRender` (источник `"UI"`).
   - `Tooltip.lua` → `AddLine` (источник `"TOOLTIP"`).
   - `ModTranslationsRU:Translate` (источник `"MOD"`).
   - `PassiveTreeView.lua` → `AddNodeName` и `addModInfoToTooltip` (источник `"TREE"`).

Верификация (`host.exe`):
- `scratch/verify_runtime_logger.lua`: **13/13 PASS** (multiline, Label:Value, EN passthrough, safety).
- `scratch/verify_dialogs.lua`: **58/58 PASS**.
- `scratch/verify_5_screenshots.lua`: **44/44 PASS**.
- `scratch/verify_tree100_ru.lua`: **29/29 PASS**.
- `calcs_check.lua`: **ALL PASS**.
- `run_batch13_treeloc.lua`: **34/34 PASS**.
- `run_batch14_gemloc.lua`: **43/43 PASS**.
- `run_batch15_modloc.lua`: **70/70 PASS**.
- `test_stat_describer_e2e.lua`: **PASS**.
- Бэкапы: `backup_ui_fix/20261112-113531-runtime-miss-logger/`.
- Git commit/reset/clean/checkout не выполнялись.

## D-049: Split uiLanguage/itemLanguage, Options Scrollbar, NotesTab/ItemListControl & Tree Extra Lines (2026-11-12)

Дата: 2026-11-12.
Статус: Принято.
Компонент: `PathOfBuilding-PoE2` (ветка `dev`).

Контекст:
После внедрения Runtime Miss Logger (D-048) и живых прогонов требовалось: разделить язык интерфейса приложения и язык игровых сущностей (предметы/камни/дерево), добавить скроллбар в переполненное окно «Настройки», устранить наложение/обрезку в «Заметках» и списке предметов, снять жёсткое совпадение длины `#ruStats == #node.sd` для нодов дерева и отключить `RULogger` по умолчанию.

Решение:
1. **`src/Modules/Main.lua` — независимые `uiLanguage` и `itemLanguage`:**
   - Добавлена настройка `self.uiLanguage = "RU"` (сохранение/загрузка в `Settings.xml` `<Misc>`, отдельный `DropDownControl` в Options, участие в `savedState`/`currentState`/Cancel). `translateForRender` ориентируется на `main.uiLanguage` (с фолбеком на `itemLanguage`).
   - В `Options` включён вертикальный скроллбар (`useScrollBar = true`, `controls.scrollBar`), чтобы элементы настроек не наезжали на нижние кнопки.
   - `self.logUntranslatedRU = false` по умолчанию (отключение фоновой записи `untranslated_live.log` после завершения сбора промахов).
2. **`src/Classes/PassiveTreeView.lua` — снятие жёсткого сравнения `#ruStats == #node.sd`:**
   - При наличии `ruStats` из `TreePassivesRU:GetStats(node)` используется построчное сопоставление `i <= #ruStats` и вывод оставшихся строк через `extraRuLines`, что поднимает покрытие нодов дерева до 99.69% (`4482/4496`).
3. **`src/Classes/NotesTab.lua` и `src/Classes/ItemListControl.lua`:**
   - В `NotesTab.lua` многострочное описание разбито на 3 отдельных `LabelControl` (`notesDesc`, `notesDesc2`, `notesDesc3`), смещены кнопки цветов (`60`) и `toggleColorCodes` (`82`), высота редактора скорректирована (`self.height - 140`).
   - В `ItemListControl.lua` статус слотов (`(Не используется)` / `(В наборе '...')`) учитывает `uiLanguage`, а названия предметов — `itemLanguage` через `ItemNamesRU:Get()`.

Верификация (`host.exe`, из `src/`):
- `scratch/verify_final_all.lua`: **SYNTAX 16/16 OK**, **TREE_COVERAGE 4482/4496 (99.69%)**.
- `scratch/verify_lang_split.lua`: **PASS** (`Main.lua` syntax OK & independent `uiLanguage`/`itemLanguage`).
- `scratch/verify_4_screenshots.lua`: **11/11 PASS**.
- `scratch/verify_5_screenshots.lua`: **44/44 PASS**.
- Git commit/reset/clean/checkout не выполнялись.

## D-050: Tooltips, WrapString Overflow Fix, CalcBreakdownRU, ConfigTooltipsRU & Automated Audits (2026-11-12)

Дата: 2026-11-12.
Статус: Принято.
Компонент: `PathOfBuilding-PoE2` (ветка `dev`).

Контекст:
Живая проверка после D-049 выявила ряд недочётов: непереведённые `tooltipText` в `Options` и вкладках, наложение текста в `PartyTab` из-за удвоения `\n`, выход длинных модов за рамки 450 px в Side-by-Side тултипах, перекрытие подзаголовка иконкой в `GemTooltip`, обрезка `Skill Movement Speed` в сайдбаре и большое число непереведённых строк в детализациях `Calcs` и тултипах `Config`.

Решение:
1. **`src/Modules/Main.lua` & `src/Classes/Tooltip.lua` — фикс переноса строк `WrapString`:**
   - В `main:WrapString(str, height, width, font)` перенос срабатывает **до** слова, превышающего `width`, добавлен параметр `font`.
   - `TooltipClass:AddLine` передаёт фактический шрифт `fontToUse` и ширину `self.maxWidth - H_PAD - 4`, устранив выход текста за границы 450 px карточек Side-by-Side.
   - В `Options` добавлен чекбокс `Логировать непереведённые строки:` (`main.logUntranslatedRU`, default `false`).
2. **`src/Data/UITranslationsRU.lua`:**
   - Исправлен многострочный fallback: `(coreText .. "\n"):gmatch("([^\n]*)\n")` вместо `gmatch("([^\n]*)")` (устранено удвоение `\n` и наложение в `PartyTab`).
   - Добавлены 45+ статических и динамических подсказок `Options`/`Party`/`Tree`/`Import`, компактный `Скор. передв. навыка`, `Active Skill #N`, `level from gem/items/corruption`, предупреждения `BuildDisplayStats.lua` и др.
3. **`src/Data/CalcBreakdownRU.lua` (новый) & `src/Classes/CalcBreakdownControl.lua`:**
   - Вынесены статические заголовки, ~170+ пояснений в скобках `^7/^8(...)` и без скобок, формулы AoE/уклонения/похищения/состояний/EHP.
   - В `CalcBreakdownControl.lua` добавлен `localizeCellValue(row, col)` для перевода `sourceName` предметов (`ItemNamesRU`) и умений (`GemNamesRU`).
4. **`src/Data/ConfigTooltipsRU.lua` (новый):**
   - Переведено >260 динамических подсказок `ConfigOptions` (`tooltipFunc`) и контролов вкладок `Items`/`Import`/`Calcs`/`Party`/`Compare` с сохранением цветовых тегов.
5. **`src/Classes/GemTooltip.lua`, `src/Data/SkillDescriptionsRU.lua`, `src/Classes/SkillsTab.lua`, `src/Data/ModTranslationsRU.lua`:**
   - Увеличен отступ `iconTagIndent` для `(enTitle)` и `displayType` в `GemTooltip`; добавлены теги `Sustained`/`Storm`; исправлена опечатка `становятсяare` в `Грозе`; в `SkillsTab:AddSocketGroupTooltip` имена камней переводятся через `GemNamesRU`; добавлены шаблоны `Deals <min> to <max> <Type> Damage` без скобок и 4 мода из живого лога.
6. **Автоматизация аудита (`scratch/`):**
   - `scratch/ast_audit_ru.py` + `scratch/ast_audit_host.lua` — Lua-лексер/парсер выражений (3 307 выражений).
   - `scratch/headless_audit_ru.lua` — headless-обходчик в `host.exe` (все 9 вкладок, `DrawString`, `tooltipText`, `tooltipFunc`, `calcsEnv.player.breakdown`), снизил число пропусков с 484 до 83.

Верификация (`host.exe`, из `src/`):
- `scratch/headless_audit_ru.lua`: **HEADLESS_MISSES=83** (все `[TT_FUNC]` из `Config` закрыты).
- `scratch/verify_tooltips_ru.lua`: **26 PASS, 0 FAIL**.
- `scratch/verify_final_all.lua`: **SYNTAX 16/16 OK**, **TREE_COVERAGE 4482/4496 (99.69%)**.
- `scratch/verify_5_screenshots.lua`: **44 PASS, 0 FAIL**.
- Бэкапы: `Snapshots/PoB2-Tooltips-20261112/`.
- Git commit/reset/clean/checkout не выполнялись.

## D-051: Кросс-портирование на PoE1 (ветка ru-localization), закрытие 13 ТЗ и взаимные улучшения (2026-11-12)

Дата: 2026-11-12.
Статус: Принято.
Компоненты: `PathOfBuilding` (PoE1, форк `skllfi2/PathOfBuilding`, ветка `ru-localization`) и `PathOfBuilding-PoE2`.

Контекст:
После успешного релиза локализации и Fluent UI для PoE2 потребовалось перенести наработки на PoE1 согласно `POE1_PORTING_PLAYBOOK.md`, обеспечив 100% работу без багов отображения, полную локализацию контента и автосборку релизов.

Решение:
1. **Портирование ядра и UI на PoE1 (ТЗ 01–05, коммиты 38998bdd..3643953f):**
   - Перенесены `SimpleGraphic.dll` (v2.5.6-совместимый), TTF-шрифты, `ThemeFluent.lua`, `UIFont.lua`, `WindowState.lua`, `ItemComparison.lua`.
   - Внедрена темизация Fluent для всех 8 базовых контролов (с безопасным fallback при отсутствии расширенного C++ API).
2. **Контентные словари PoE1 (ТЗ 06–10, коммиты 15ab1c66..c1266676):**
   - На базе официальной выгрузки PoE1 (`dist/poe1/`) сгенерированы: `ItemNamesRU.lua` (5657 предметов), `GemNamesRU.lua` (1280 ID), `TreeNodesRU.lua`, `SkillDescriptionsRU.lua` (726 описаний), `ModTranslationsRU.lua` и `TreePassivesRU.lua`.
3. **UI-полировка и фиксы тултипов (ТЗ 11–13, коммиты 7adc72be, 962977ff, 7ae48a5f):**
   - **Скролл настроек:** `PopupDialog:GetEffectiveHeight()`, авто-ограничение высоты попапа `Options` (`maxSingleColHeight = min(740, screenH - 30)`), плавная прокрутка колесом мыши.
   - **Side-by-Side сравнение:** полная связка настроек и генерация тултипов сравнения экипировки в `ItemsTab.lua` с переключением слотов по Shift.
   - **Фикс сохранения цветов в тултипах (`Tooltip.lua`):** активный цвет (`activeColour`) теперь сохраняется при переносе длинных строк, исключая сброс в белый цвет.
   - **Требования и статы предметов:** локализованы требования уровня/характеристик и статы оружия/брони/флаконов.
   - **100% покрытие дерева и Мастерств:** добавлены все 133 группы Masteries и малых нод дерева (1746 из 1746 актуального дерева `3_26`), устранены частичные переводы в `TreePassivesRU.lua` (2438 нод из 2438 переведены на 100%).
   - **Поддержка чисел в середине строк (`ModTranslationsRU.lua`):** добавлена O(1) подстановка `%1` для перестановочных шаблонов («На %1 больше...») и regex для свойств приспешников/регенерации/убийства.
4. **CI и релиз:**
   - Настроен GitHub Actions workflow `.github/workflows/ru-release.yml` для автоматической сборки portable `.zip` при публикации тега `v*-ru`.

Верификация:
- Все модули данных валидированы компиляцией и выполнением в реальном рантайме LuaJIT (`lua51.dll`).
- Аудит покрытия дерева: **100.0%** (2438/2438 нод полностью на русском, 0 частично переведенных).
- Ветка `ru-localization` запушена в `origin/ru-localization`.
