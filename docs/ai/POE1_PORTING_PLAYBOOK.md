# Playbook: Перенос русской локализации, Fluent UI и автоаудита на Path of Building (PoE1)

Документ фиксирует полный воспроизводимый процесс, использованный в `PathOfBuilding-PoE2` (ветка `ru-localization`, релиз `v0.23.1-ru`), чтобы максимально быстро и без повторных ошибок перенести всё на [PathOfBuildingCommunity/PathOfBuilding](https://github.com/PathOfBuildingCommunity/PathOfBuilding).

---

## 1. Архитектура, которую переносим без изменений

1. **Display-Only слой перевода (D-006):**
   - Внутренние идентификаторы (`item.baseName`, `gemData.id`, `ModDB`, `output:*`, XML-сохранения, импорт/экспорт pobb.in) **всегда остаются на английском**.
   - Перевод происходит только в момент отображения:
     - `Main.lua` → `translateForRender` (перехват `DrawString` / `DrawStringWidth`).
     - `Tooltip.lua` → `AddLine` (построчный перевод до `WrapString`).
     - Модули данных в `src/Data/`:
       - `UITranslationsRU.lua` — словарь UI + fallback'и (`\n`, `Label: Value`, снятие `^7`/`^xRRGGBB` и `:`).
       - `CalcBreakdownRU.lua` — статические заголовки, пояснения в скобках `^7/^8(...)`, формулы AoE/EHP/уклонения/похищения/состояний.
       - `ConfigTooltipsRU.lua` — динамические подсказки `ConfigOptions` и контролов вкладок.
       - `ModTranslationsRU.lua`, `ItemNamesRU.lua`, `GemNamesRU.lua`, `SkillDescriptionsRU.lua`, `StatDescriptionsRU.lua`, `TreeNodesRU.lua`, `TreePassivesRU.lua`.
     - `RULogger.lua` — живой логгер непереведённых строк (`src/untranslated_live.log`), управляемый галочкой в `Options` (`main.logUntranslatedRU`, по умолчанию `false`).

2. **Независимые языковые настройки (`Main.lua`):**
   - `main.uiLanguage` (`"RU"` / `"EN"`) — язык интерфейса приложения.
   - `main.itemLanguage` (`"DUAL"` / `"RU"` / `"EN"`) — язык игровых сущностей (предметы, камни, моды, дерево).
   - Обе настройки сохраняются в `<Misc>` файла `Settings.xml` и участвуют в `savedState` / `currentState` / Cancel окна `Options`.

3. **C++ рендерер (`SimpleGraphic` / `SimpleGraphic-Next`):**
   - Использовать уже собранную `SimpleGraphic.dll` (ветка `feat/modern-runtime`, коммит `9588a6a`), в которой уже есть:
     - UTF-8 / `stb_truetype` TTF fallback;
     - `SetIndexedColor` (темизация `^7`);
     - Window State API (`GetWindowPosition`, `SetWindowPosition`, `GetMonitorBounds`, и т.д.);
     - фикс яркости (`IMGTYPE_RGBA`) и базовой линии кириллицы для `Fontin SmallCaps` (`engine/render/r_font.cpp`).
   - В PoE1 используется тот же движок SimpleGraphic — повторно менять C++ не потребуется (достаточно проверить совместимость экспортируемых функций с версией PoE1).

---

## 2. Критические баги, найденные в PoE2 (применять в PoE1 сразу)

1. **`main:WrapString` (`Main.lua`) и `Tooltip:AddLine` (`Tooltip.lua`):**
   - В оригинале `WrapString` обновлял `lastBreak` **до** проверки ширины, из-за чего перенос происходил *после* слова, превысившего лимит `width`, и текст вылезал за края 450 px карточек.
   - Обязательно: проверять `DrawStringWidth(height, fontName, str:sub(lineStart, s - 1)) > width` **до** обновления `lastBreak`, передавать `fontToUse` и ширину `self.maxWidth - H_PAD - 4`.
2. **Многострочный fallback в `UITranslationsRU:Get()`:**
   - Использовать `(coreText .. "\n"):gmatch("([^\n]*)\n")` вместо `gmatch("([^\n]*)")`, иначе Lua удваивает каждый `\n` и ломает вёрстку многострочных описаний (как было в `PartyTab`).
3. **Обработка двоеточия `:` в `UITranslationsRU:Get()`:**
   - Не терять `trailingSuffix = ":"` перед вызовом `CalcBreakdownRU.Translate` и искать по обоим ключам `tagless` и `tagless .. ":"`.
4. **`GemTooltip.lua`:**
   - Для подзаголовка `(enTitle)` и типа камня (`fontSizeBig`) использовать увеличенный отступ `iconTagIndent`, чтобы текст не налезал на иконку камня.
5. **Бюджет ширины сайдбара (`Build.lua`):**
   - Расширить правую границу колонки меток `statBox` (`170 → 185 px`), а длинные русские формулировки в `UITranslationsRU.lua` сокращать (например, `Скор. передв. навыка`, `Эфф. запас здоровья`, `% брони от дерева`).
6. **`Settings.xml` без BOM:**
   - При генерации/правке `Settings.xml` скриптами писать UTF-8 **без BOM**, иначе XML-парсер PoB не читает настройки.

---

## 3. Что нужно перегенерировать специально под PoE1

Контентные словари из PoE2 **нельзя** переносить вслепую — у PoE1 своя база данных игры:
1. **Выгрузка официальной русской локализации PoE1 (GGPK / `PathOfExile_Translated` / RePoE):**
   - `ItemNamesRU.lua` — базы предметов и уники PoE1 (включая флаконы, кластерные самоцветы, карты/идолы при наличии).
   - `GemNamesRU.lua` и `SkillDescriptionsRU.lua` — активные камни, поддержки, Awakened / Transfigured / Vaal версии.
   - `StatDescriptionsRU.lua` — из `stat_descriptions` PoE1 (с разбивкой на чанки <= 150 элементов из-за лимита в 200 локальных переменных в LuaJIT).
   - `TreeNodesRU.lua` и `TreePassivesRU.lua` — дерево пассивных умений PoE1 (включая Masteries и Cluster Jewels).
   - `ModTranslationsRU.lua` — точные строки и regex-шаблоны модов предметов/самоцветов PoE1.
2. **UI и расчёты PoE1:**
   - Скопировать `UITranslationsRU.lua`, `CalcBreakdownRU.lua`, `ConfigTooltipsRU.lua` как стартовую базу (покроют ~75–85% интерфейса сразу).
   - Отличия PoE1 (Pantheon, Bandits, Utility Flasks, Tattoos, Mastery, Atlas/Config-опции) собрать через автоаудит (шаг 4).

---

## 4. Пошаговый цикл запуска на PoE1

1. **Форк и ветка:**
   - Форкнуть `PathOfBuildingCommunity/PathOfBuilding`, настроить `upstream` на оригинал, `origin` на свой форк, создать рабочую ветку `ru-localization`.
2. **Подготовка среды (`host.exe`):**
   - Использовать `host.exe` (или `luajit.exe` + `HeadlessWrapper.lua`) с `WorkingDirectory = src/` и прописанными путями `runtime/lua/?.lua` / `runtime/?.dll`.
3. **Перенос ядра локализации и UI:**
   - Перенести `SimpleGraphic.dll`, `Fonts/`, `ThemeFluent.lua`, `UIFont.lua`, `WindowState.lua`, `ItemComparison.lua`, `RULogger.lua`, фиксы `Main.lua` (`WrapString`, `uiLanguage`, `itemLanguage`, скролл в `Options`) и `Tooltip.lua`.
4. **Автоматический поиск всех пропусков (без ручного прокликивания):**
   - Запустить статический AST-аудит (`scratch/ast_audit_ru.py` → `host.exe`) по `src/Classes/` и `src/Modules/`.
   - Запустить headless-обходчик (`scratch/headless_audit_ru.lua` через `HeadlessWrapper.lua` в `host.exe`) на 3–4 эталонных билдах PoE1 (Attack, Spell/DoT, Minion, ES/Block).
5. **Пакетный перевод + регрессия:**
   - Дополнить `UITranslationsRU.lua`, `CalcBreakdownRU.lua`, `ConfigTooltipsRU.lua`.
   - Прогнать проверки синтаксиса, `verify_tooltips_ru.lua`, `verify_tree100_ru.lua`, `calcs_check.lua` (убедиться, что расчёты 100% совпадают с оригиналом).
6. **Сборка и публикация portable-релиза:**
   - Собрать чистую папку без `.git`, `scratch/`, черновых `*.json` и `untranslated_live.log`.
   - В `manifest.xml` заменить `PathOfBuildingCommunity/PathOfBuilding/{branch}` на `<your-user>/PathOfBuilding/ru-localization`, чтобы автообновление не затирало русский язык оригиналом.
   - Проверить запуск `Path of Building.exe` на чистой папке (убедиться, что нет `Dev Mode`).
   - Опубликовать `.zip` через `gh release create`.

---

## 5. Предложения по улучшению инструментов для PoE1

1. **AST-экстрактор v2 (JSON + группировка по категориям):**
   - Доработать `ast_audit_ru.py`, чтобы на выходе он сразу формировал `missing_to_translate.json` (с группировкой по `UI`, `ConfigTooltips`, `CalcBreakdown`, указанием `file:line`, наличием `^`-тегов и `%`-плейсхолдеров) — такой файл можно отдавать на автоперевод одним проходом.
2. **Multi-build + Popup Headless Crawler:**
   - Расширить `headless_audit_ru.lua`: грузить не один пустой билд, а 3–4 готовых XML-билда разных архетипов и программно открывать попапы (`Options`, `Manage Tree`, `Craft Item`, `Import/Export`), чтобы собрать ~98% динамических строк без единого клика мышкой.
3. **Автовалидатор качества переводов в `host.exe`:**
   - Скрипт проверки словарей перед релизом:
     - совпадение числа и типов плейсхолдеров (`%d`, `%.2f`, `%s`, `{0}`) в `en` и `ru`;
     - корректность цветовых тегов (`^7`, `^xRRGGBB`) и отсутствие случайных `%%` или непереведённых вставок;
     - проверка ширины (`DrawStringWidth <= 180px` для строк сайдбара и `<= 148px` для меток в диалогах/табах), чтобы отлавливать обрезку текста ещё до запуска GUI.
4. **GitHub Actions для автосборки релиза:**
   - Добавить `.github/workflows/ru-release.yml` (триггер по тегу `v*-ru`), который сам собирает portable `.zip`, подменяет `manifest.xml` на форк и прикрепляет архив к GitHub Release.
