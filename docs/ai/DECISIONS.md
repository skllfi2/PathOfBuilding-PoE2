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
