# Архитектура системы и план перехода на C# 15 / .NET 11 / WinUI 3

Документ описывает текущую архитектуру `PathOfBuilding` (PoE1 / PoE2) и пошаговую стратегию замены C++ хоста (`SimpleGraphic`) на современный стек **C# 15 / .NET 11 / WinUI 3** без потери совместимости с расчётным ядром PoB.

---

## 1. Текущая 3-слойная архитектура

```
+-------------------------------------------------------------------+
| Layer 3: Display-Only Localization & Fluent UI (Lua)              |
|  - Main.lua (translateForRender, uiLanguage, itemLanguage)        |
|  - ThemeFluent.lua, UIFont.lua, WindowState.lua, ItemComparison   |
|  - UITranslationsRU, CalcBreakdownRU, ConfigTooltipsRU,           |
|    ModTranslationsRU, ItemNamesRU, GemNamesRU, TreePassivesRU     |
+-------------------------------------------------------------------+
| Layer 2: PoB Core & Calculations (LuaJIT)                         |
|  - CalcOffence, CalcDefence, CalcPerform, CalcBreakdown, ModDB    |
|  - PassiveTree, ItemsTab, SkillsTab, Build (XML / pobb.in)        |
|  - Работает 100% на английских внутренних идентификаторах         |
+-------------------------------------------------------------------+
| Layer 1: Native Graphics & OS Host (C++ SimpleGraphic.dll)        |
|  - GLFW окно, OpenGL/ANGLE рендер, stb_truetype, .tgf шрифты      |
|  - LuaJIT VM, lcurl, zlib, lua-utf8                               |
|  - Контракт: ~60 C-функций (описаны в src/_SimpleGraphic.def.lua) |
+-------------------------------------------------------------------+
```

**Ключевой вывод:** Вся бизнес-логика, парсинг предметов и расчёты PoB живут в **Layer 2 (LuaJIT)**, а **Layer 1 (C++ SimpleGraphic)** отвечает только за окно, ввод, шрифты, 2D-примитивы и сетевые/крипто-библиотеки.

---

## 2. Целевая архитектура на C# 15 / .NET 11 / WinUI 3

```
+-------------------------------------------------------------------+
| WinUI 3 Shell (C# 15 / .NET 11, MVVM, Mica/Acrylic, Native DPI)   |
|  - Нативные XAML-окна: Settings, BuildList, Trade, Notes, Dialogs |
|  - SwapChainPanel / Win2D (Direct2D + DirectWrite) Canvas         |
|    для отрисовки PassiveTree и таблиц Calcs с аппаратным 60+ FPS  |
+-------------------------------------------------------------------+
| Interop Bridge (C# UnmanagedCallersOnly / P/Invoke <-> LuaJIT)    |
|  - Реализует контракт _SimpleGraphic.def.lua поверх Win2D/WinUI   |
|  - Нативный DirectWrite решает проблемы кириллицы, сглаживания,   |
|    ClearType, эмодзи и подбора шрифтов без .tgf-костылей          |
+-------------------------------------------------------------------+
| PoB Core Engine (LuaJIT / HeadlessWrapper / совместимый слой)     |
|  - CalcOffence, CalcDefence, ModDB, XML/pobb.in — 100% точность   |
|  - Постепенная (помодульная) миграция расчётов на C# при желании  |
+-------------------------------------------------------------------+
```

---

## 3. Пошаговая стратегия миграции (без переписывания с нуля)

### Фаза 1. Заморозка контракта Host <-> Lua
- Источник правды: `src/_SimpleGraphic.def.lua` + callbacks из `Launch.lua` (`OnInit`, `OnFrame`, `OnKeyDown`, `OnKeyUp`, `OnChar`, `CanExit`, `OnExit`).
- Сгруппировать функции хоста по 5 интерфейсам в C#:
  1. `IRenderBackend`: `DrawImage`, `DrawString`, `DrawStringWidth`, `DrawStringCursorIndex`, `SetDrawColor`, `SetDrawLayer`, `SetViewport`, `SetIndexedColor`.
  2. `IWindowService`: `GetScreenSize`, `GetVirtualScreenSize`, `SetWindowTitle`, `GetWindowPosition`/`Size`, `SetWindowMaximized`, `GetMonitorBounds`, `SetWindowDarkMode`, `SetDPIScaleOverridePercent`.
  3. `IInputService`: `GetCursorPos`, `IsKeyDown`, `Copy`, `Paste`.
  4. `IResourceLoader`: `NewImageHandle` (DDS/PNG/WebP), `NewFileSearch`, `StripEscapes`.
  5. `ILuaHost`: инициализация `lua51.dll` (LuaJIT), регистрация `[UnmanagedCallersOnly]` коллбэков и циклов `OnFrame`.

### Фаза 2. WinUI 3 + Win2D (Direct2D/DirectWrite) как Drop-In замена `SimpleGraphic.dll`
- Создать WinUI 3 проект (`net11.0-windows10.0.22621.0`, `AllowUnsafeBlocks = true`, NativeAOT-совместимый P/Invoke к `lua51.dll`).
- На главной странице разместить `CanvasAnimatedControl` / `CanvasControl` (Win2D) или `SwapChainPanel`:
  - `DrawString` → `DirectWrite` (`CanvasTextFormat` с автоподбором системных/встроенных `.ttf` шрифтов `Fontin`, `Noto Sans`, цветных эмодзи и нативным сглаживанием ClearType).
  - Координатная сетка и цветные коды `^7` / `^xRRGGBB` парсятся в C# один раз в кэшируемый `TextLayout`.
- **Результат Фазы 2:** всё существующее приложение PoB (включая русскую локализацию, дерево пассивок и все расчёты) запускается внутри WinUI 3 окна **без переписывания 100k+ строк Lua**.

### Фаза 3. Нативный WinUI 3 UI для экранов и диалогов (Hybrid MVVM)
- Заменить кастомные Lua-попапы и списки на нативные WinUI 3 контролы (MVVM):
  1. `Options` (SettingsDialog) → нативный `NavigationView` / `SettingsExpander` с биндингом в `Settings.xml` и локализацией через `.resw` / JSON.
  2. `BuildList` и `Import/Export` → `ListView` / `AutoSuggestBox` с мгновенным поиском и Drag&Drop.
  3. `TradeQuery` / `Notes` / `Config` → нативные XAML-панели с поддержкой системной темы Windows 11 (Mica/Backdrop).
- Дерево пассивных умений (`PassiveTreeView`) и сетку `Calcs` целесообразно **оставить на Direct2D/Win2D Canvas**, так как они рисуют тысячи узлов/линий за кадр.

### Фаза 4. Опциональная миграция расчётного ядра на C#
- Переносить расчёты (`ModDB`, `CalcOffence`, `CalcDefence`) стоит **только после** стабильной работы Фаз 2–3 и строго через **эталонное тестирование**:
  - Эталоном служит `HeadlessWrapper.lua` в `host.exe`.
  - Для каждого портируемого модуля прогоняется набор из 50+ билдов (XML) с побайтовым/численным сравнением `output.*` между LuaJIT и C#.

---

## 4. Правила качества для будущего C# / WinUI 3 репозитория

1. **Чёткое разделение слоёв:** `PoB.Interop` (P/Invoke к LuaJIT), `PoB.Rendering` (Win2D/DirectWrite), `PoB.UI` (WinUI 3 XAML + ViewModels), `PoB.Localization` (словари/ресурсы).
2. **Никакого блокирования UI-потока:** импорт билдов, запросы к Trade API и расчёты запускать асинхронно (`async/await` + `DispatcherQueue`).
3. **Централизованный кэш ресурсов:** кисти (`CanvasSolidColorBrush`), шрифты (`CanvasTextFormat`) и текстуры (`CanvasBitmap`) создавать один раз и освобождать по `IDisposable`.
4. **Автотесты в CI:** `dotnet test` (контракты Interop, парсер `^`-тегов, регрессия словарей) + headless-проверка билдов на каждый PR.
