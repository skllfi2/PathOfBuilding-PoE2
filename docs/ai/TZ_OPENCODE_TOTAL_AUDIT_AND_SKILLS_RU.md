# ТЗ для OpenCode (Nemotron): Тотальный аудит и добивка локализации PoB2 (Интерфейс, Умения, Настройки, Дерево)

**Репозиторий:** `f:\Development\Dev\mydev\PoB2Fork\PathOfBuilding-PoE2`  
**Внимание по инструментам:** В системе установлен только Windows PowerShell 5.1 (**PS 7.6 отсутствует**). Все операции валидации, парсинга JSON/UTF-8 без BOM и регистрочувствительных ключей выполнять строго через **Python 3 / Node.js / `host.exe`**, НЕ использовать `ConvertFrom-Json` в PS 5.1.

---

## 0. Инварианты и подготовка

1. **Display-Only слой:** не изменять внутренние ID (`node.id`, `skillId`, `item.baseName`), формулы расчёта (`Calc*`) и XML-формат сохранений.
2. **Бэкапы (обязательно):** перед изменением любого существующего `.lua`-файла сделать копию в `../backup_ui_fix/<timestamp>/`.
3. **Запрещено:** `git commit`, `git reset`, `git clean`, `git checkout`.
4. **Источники официальной терминологии PoE2 уже в workspace:**
   - `../PoE2-Localization-Extractor/exports/skill_gems_ru_validation/skill_gems.json`
   - `../PoE2-Localization-Extractor/exports/stat_translations_ru_validation/`
   - `../PoE2-Localization-Extractor/exports/passives_ru_validation_retry1/`
   - `src/Data/GemNamesRU.lua`, `src/Data/ModTranslationsRU.lua`, `src/Data/TreeNodesRU.lua`, `src/Data/ItemNamesRU.lua`

---

## 1. Обязательная замена терминологии: «Древо» → «Дерево»

1. Во всём [src/Data/UITranslationsRU.lua](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Data/UITranslationsRU.lua) заменить UI-слово **`Древо` / `Древа` / `древа` / `древо`** на **`Дерево` / `Дерева` / `дерева` / `дерево`**:
   - `["Tree"] = "Дерево"`
   - `["Tree:"] = "Дерево:"`
   - `["Passive tree:"] = "Дерево пассивных умений:"`
   - `["Passive Tree and Jewels"] = "Дерево пассивных умений и самоцветы"`
   - Проверить все вхождения в сайдбаре (`% от дерева`, `%Увелич. Брони от Дерева` и т.д.).
   - **Осторожно:** не испортить слова с корнем «древн-» (например, `["Ancient Aegis"] = "Древняя эгида"`!).

---

## 2. Тотальный аудит и перевод оставшегося UI (542 подготовленных ключа)

Уже выгружен чистый список оставшихся непереведённых UI-строк (без кода) из `Classes/`, `Modules/` и `Data/QuestRewards.lua`:
- **Файл-задание:** [src/Data/to_translate_audit_ui.json](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Data/to_translate_audit_ui.json) (**542 ключа**)

**Требуется:**
1. Перевести все ключи `to_translate_audit_ui.json` (оставив ключи нетронутыми, без BOM, валидный JSON) и слить в `UITranslationsRU.lua`.
2. **Дополнительно проверить в исходниках UI пропущенные кейсы:**
   - **Награды за квесты (`src/Data/QuestRewards.lua` + `ConfigOptions.lua`):** перевести все квесты (`Act 3: Jiquani's Machinarium`, `Act 4: Eye of Hinekora`, `Interlude 2: Khari Crossing`, `Interlude 3: Kriar Village`) и **все пункты выпадающих списков** (многострочные вроде `"30% increased Charm Charges Gained\n\t+1 Charm Slot"` и одиночные).
   - **Строки со встроенными цветовыми тегами в середине (`ConfigOptions.lua`):** например `"Have you been Stunned " .. colorCodes... .. "Recently?"` $\rightarrow$ на скриншоте выглядит как `Вы были оглушены Recently?`, `Вас Hits Recently?`.
     - В `UITranslationsRU:Get(text)` добавить fallback: если прямой поиск не сработал, проверить очищенную от **всех** внутренних цветовых тегов строку (`text:gsub("%^x%x%x%x%x%x%x", ""):gsub("%^%d", "")`) и по возможности восстановить цвет или вернуть чистый перевод (`Вы были оглушены недавно?`, `По вам попадали ударом недавно?`, `Убивали врагов недавно?` и т.д.).
   - **Компактность Config Tab:** укоротить `Откл. получение EHP при блоке/подавлении:` $\rightarrow$ `Без EHP от блока/подавл.:`, чтобы текст не выходил за левую рамку секции `Общее`.
   - **Кнопки пользовательских модификаторов в Config:** `Add Mod Group`, `Add Mod`.
   - **Прочие диалоги и вкладки:** `Main.lua` (Options, About, Popups), `TreeTab.lua` (поиск, сравнение деревьев, менеджер наборов), `ImportTab.lua`, `CompareTab.lua`, `CalcBreakdownControl.lua`, `TradeQuery*.lua`.
   - Дополнительно просканировать Lua-файлы в `src/Classes/` и `src/Modules/` на предмет строковых литералов в `SetText(...)`, `DrawString(...)`, выпадающих списков `{ label = ... }`, заголовков `OpenPopup(...)` / `OpenMessagePopup(...)` / `OpenConfirmPopup(...)`, если что-то ещё не попало в `to_translate_audit_ui.json`.

---

## 3. Вкладка «Умения» (`SkillsTab`) и перевод текстов умений

### 3.1. Исправление вёрстки и непереведённых элементов UI в `SkillsTab` и `SkillListControl`
1. **Многострочный блок `Usage Tips:` (`SkillsTab.lua:100-108`):** проверить точное совпадение (включая `\n` в начале/конце или очистку крайних пробелов/переносов в `UITranslationsRU:Get`), чтобы блок подсказок гарантированно выводился на русском.
2. **`Skill set:` (`SkillsTab.lua:93`)**: убедиться в наличии перевода `Набор умений:`.
3. **Устранение обрезаний и наложений в `SkillsTab.lua`:**
   - Слева в блоке `Параметры камней` (`SkillsTab.lua:111-140`): укоротить `Показывать камни поддержки:` $\rightarrow$ `Камни поддержки:`, `Показывать устаревшие камни:` $\rightarrow$ `Устаревшие камни:` (или подвинуть `optionInputsX` так, чтобы метки полностью помещались внутри рамки `360px`).
   - Сверху в деталях группы (`SkillsTab.lua:202, 220`): укоротить `Include in Full DPS:` $\rightarrow$ `В полный DPS:` и при необходимости увеличить отступ между `groupEnabled` (`Включено:`) и `includeInFullDPS` (например, со `145` до `165`), а также перевести `Set 1:` / `Set 2:` (`Набор 1:` / `Набор 2:`, проверив отступ `set2Enabled`).
4. **Список групп умений слева (`src/Classes/SkillListControl.lua`):**
   - Сейчас отображает `Mace Strike (FullDPS)`, `Shield Wall (Active) (FullDPS)` на английском.
   - При отрисовке названия группы (не ломая `socketGroup.label` внутри модели!) переводить название скилла через `GemNamesRU:Get(...)` и суффикс `(Active)` $\rightarrow$ `(Активно)` (оставить лаконичное `(FullDPS)` или `(Полн.DPS)`).

### 3.2. Перевод описаний и характеристик умений (текст скиллов)
1. **Описания умений (`src/Data/to_translate_skills_desc.json` — 980 ключей):**
   - Перевести 980 описаний из `to_translate_skills_desc.json` с максимальной опорой на официальные русские тексты в `../PoE2-Localization-Extractor/exports/skill_gems_ru_validation/skill_gems.json` (колонка `support_text` / описания умений) и терминологию PoE2.
   - Сохранить в новый модуль `src/Data/SkillDescriptionsRU.lua` с методом `SkillDescriptionsRU:Get(text)` (fallback на оригинал).
   - Подключить в [src/Classes/GemTooltip.lua:218](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Classes/GemTooltip.lua#L216-L219) для `grantedEffect.description` (при `itemLang ~= "EN"`).
2. **Строки параметров и модов в `GemTooltip.lua` (`src/Classes/GemTooltip.lua:130-245`, `addDescriptionLine`):**
   - Сейчас строки вида `"   Cost: ^7" .. cost`, `"   Attack Damage: ^7%s%% of base"`, `"   Requires: ^7"`, `"   Cooldown Time: ^7"`, `"   Cast Time: ^7"`, `"   Critical Hit Chance: ^7"` содержат 3 пробела в начале и внутренний `^7`, из-за чего пролетают мимо `DrawString`-хука. Добавить явную локализацию / поддержку отступов в `UITranslationsRU:Get()` (с сохранением ведущих пробелов) и перевести значения (`Mana` $\rightarrow$ `Маны`, `sec` $\rightarrow$ `сек`, `Instant` $\rightarrow$ `Мгновенно`, `(MAX)` $\rightarrow$ `(МАКС)`).
   - Проверить строки характеристик камня из `StatDescriber` / `describeStats` (в `GemTooltip.lua:addDescriptionLine`): пропускать итоговые строки свойств умений через `ModTranslationsRU:Translate(line)` (а недостающие частые шаблоны статов камней дозаполнить в `ModTranslationsRU`, сверяясь с `PoE2-Localization-Extractor/exports/stat_translations_ru_validation/`).

---

## 4. Дерево пассивных умений (Tree Tab) — добивка

1. Проверить все строки управления в `src/Classes/TreeTab.lua` (поиск узлов, сравнение деревьев, пути, экспорт/импорт, названия классов/восхождений, статистику выделенных пассивок).
2. Проверить тултипы дерева (`PassiveTreeView.lua`) и покрытие модификаторов узлов в `ModTranslationsRU.lua` по реальным строкам из `src/TreeData/0_1/tree.lua` (дополнить недостающие шаблоны модов пассивок, опираясь на `passives_ru_validation_retry1` / `ModTranslationsRU`).

---

## 5. Верификация (только через Python / Node.js / `host.exe`)

1. **JSON-валидация:** `to_translate_audit_ui.json` и `to_translate_skills_desc.json` валидны, 0 пустых строк, UTF-8 без BOM.
2. **Нативные тесты через `../build-SimpleGraphic-Next/smoke/pob2lua/host.exe`:**
   - Проверка `loadfile` синтаксиса всех изменённых `.lua` файлов (включая `UITranslationsRU.lua`, `SkillDescriptionsRU.lua`, `GemTooltip.lua`, `SkillsTab.lua`, `SkillListControl.lua`, `TreeTab.lua`, `ConfigOptions.lua`, `ModTranslationsRU.lua`).
   - Проверка ключевых кейсов из скриншотов пользователя (`Tree` $\rightarrow$ `Дерево`, `Usage Tips:`, `Skill set:`, `Disable EHP...`, `Have you been Stunned ^7Recently?`, `Act 3: Jiquani's Machinarium`, `30% increased Charm Charges Gained\n\t+1 Charm Slot`, `"   Attack Damage: ^7533% of base"`, перевод `description` умения и строки мода камня).
   - Проверка ширины новых подписей в `SkillsTab` и `ConfigTab` через `DrawStringWidth` (исключить обрезание слева/наезды).
   - Регрессионные тесты: `calcs_check.lua`, `run_batch13_treeloc.lua`, `run_batch14_gemloc.lua`, `run_batch15_modloc.lua` — **100% PASS, 0 FAIL**.
3. Обновить `docs/ai/CURRENT_STATE.md`, `docs/ai/DECISIONS.md`, `docs/ai/SESSION_HANDOFF.md`.
