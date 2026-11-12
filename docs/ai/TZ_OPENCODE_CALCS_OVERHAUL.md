# ТЗ для OpenCode: Переработка вкладки «Расчёты» (Calcs Tab — Вариант А + Б)

**Проект:** PathOfBuilding-PoE2 (`f:\Development\Dev\mydev\PoB2Fork\PathOfBuilding-PoE2`)  
**Цель:** Устранить обрезание/наложение русского текста во вкладке **Расчёты (Calcs)**, визуально разделить типы урона и разгрузить экран от пустых/нулевых секций без какого-либо вмешательства в формулы расчёта урона/защиты и формат XML-сохранений.

---

## 1. Обязательные ограничения (Инварианты)

1. **Никаких изменений в формулах и ID:**
   - Не изменять имена `modName`, `output`, `flag`, `notFlag`, `breakdown`, `formatCalcStr` и структуру данных в [CalcPerform.lua](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Modules/CalcPerform.lua), [CalcOffence.lua](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Modules/CalcOffence.lua), [CalcDefence.lua](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Modules/CalcDefence.lua), [CalcSections.lua](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Modules/CalcSections.lua).
   - Оригинальные поля `.label` в `CalcSections.lua` используются для поиска (`SearchMatch`) и XML-идентификаторов (`subSec.id = subSec.label:gsub("%W", "")`) — **не переименовывать `.label` в `CalcSections.lua`**. Все русские сокращения делаются только в словаре [UITranslationsRU.lua](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Data/UITranslationsRU.lua) (display-only слой).
2. **Резервные копии (Правило проекта):** перед редактированием любого существующего `.lua`-файла создать бэкап в `../backup_ui_fix/` с временной меткой.
3. **Не делать `git commit`, `reset`, `clean`, `checkout`.**
4. **Верификация:** после всех правок обязательно прогнать синтаксическую проверку и тесты через `build-SimpleGraphic-Next/smoke/pob2lua/host.exe`.

---

## 2. Задачи Варианта А (Вёрстка, Anti-Overflow и Цветовое зонирование)

### 2.1. Адаптивная ширина колонок и столбца подписей
**Файлы:** [CalcsTab.lua](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Classes/CalcsTab.lua), [CalcSectionControl.lua](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Classes/CalcSectionControl.lua)

Сейчас в `CalcsTab.lua:35` ширина 1 колонки жёстко зафиксирована `self.colWidth = 230`, а в `CalcSectionControl.lua` столбец подписей жёстко зафиксирован в `130–134px` (`DrawImage` шириной `130`, `DrawString` c `RIGHT_X` в `drawX + 132`, `local xOffset = 134`, `colData.width = ... or width - 136`). На широких экранах (1600–1920px) это приводит к обрезанию русских подписей слева и наползанию длинных значений (`204,724 to 294,820`) на соседние колонки.

**Требуется:**
1. Ввести вычисляемую ширину колонки подписи `self.labelWidth` в `CalcSectionControl` (или брать из `self.calcsTab.labelWidth`, по умолчанию `154`, а при узком окне / portrait mode плавно сжимать до `132`).
   - Заменить хардкоды `130`, `132`, `134`, `136` в `CalcSectionControl.lua` (строки 135, 139, 508, 585, 589, 592, 595) на переменные на базе `labelWidth`:
     - Фон ячейки подписи: ширина `labelWidth - 2` (`drawX + 2`).
     - Выравнивание `RIGHT_X`: `drawX + labelWidth` (вместо `drawX + 132`).
     - Начало колонок данных: `xOffset = labelWidth + 2` (вместо `134`).
     - Остаточная ширина одной ячейки: `width - (labelWidth + 4)` (вместо `width - 136`).
2. Сделать `colWidth` в `CalcsTab.lua` адаптивным в `Draw(viewPort, ...)` при доступной ширине:
   - При `viewPort.width >= 1340` (например, 1600–1920px окно) увеличивать `colWidth` пропорционально доступному месту до разумного предела (`255–275px` для `maxCol = 5` или `4`), чтобы 5 колонок равномерно заполняли экран, а не оставляли пустую полосу справа.
   - При изменении `colWidth` пересчитывать `section.width = section.widthCols * self.colWidth + 8 * (section.widthCols - 1)`.
   - **Критично:** в `CalcsTab.lua:284` заменить `if section.width == self.colWidth then` на `if section.widthCols == 1 then`, чтобы проверка ширины не сломалась при динамическом ресайзе!
3. Для широкой 3-колоночной таблицы `HitDamage` (`Uron удара умения`) распределять ширину `colWidth` 6 ячеек (`All Types`, `Physical`, `Lightning`, `Cold`, `Fire`, `Chaos`) равномерно из оставшейся ширины `(section.width - (labelWidth + 6)) / 6`, чтобы диапазоны урона вида `267,917 to 386,338` гарантированно помещались внутрь колонки (при необходимости уменьшать размер шрифта длинной строки до `12px` или сокращать `to` $\rightarrow$ `–` при отрисовке, только визуально!).

### 2.2. Устранение тавтологии и обрезания подписей в `UITranslationsRU.lua`
**Файл:** [UITranslationsRU.lua](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Data/UITranslationsRU.lua)

Провести аудит всех подписей секций `CalcSections.lua` (включая недавно добавленные из `to_translate_calcs.json`) и укоротить длинные фразы (> 18–20 символов), повторяющие заголовок собственного блока:
- В блоках **Кровотечение / Яд / Поджигание** не повторять название недуга в каждой строке:
  - `Max Bleed Stacks` / `Max Poison Stacks` / `Max Ignite Stacks` $\rightarrow$ `Макс. зарядов`
  - `Bleed Chance` / `Chance to Bleed` / `Chance to Poison` / `Chance to Ignite` $\rightarrow$ `Шанс`
  - `Average Bleed Roll` / `Average Poison Roll` / `Average Ignite Roll` $\rightarrow$ `Сред. бросок`
  - `Bleed Duration` / `Poison Duration` / `Ignite Duration` $\rightarrow$ `Длительность`
  - `Dmg of all Bleeds` / `Dmg of all Poisons` / `Dmg of all Ignites` $\rightarrow$ `Общий урон`
  - `OH Source Physical` / `MH Source Physical` / `OH Source Chaos` / `MH Source Fire` $\rightarrow$ `Лев. физ. база` / `Прав. физ. база` / `Лев. хаос база` / `Прав. огонь база`
  - `Stack Potential` $\rightarrow$ `Потенциал стаков`
  - `Magnitude Effect` $\rightarrow$ `Эффект силы`
  - `Effective DPS Mod` $\rightarrow$ `Мод. эфф. DPS`
- В таблице **Урон удара умения** и метриках `MH`/`OH` (основная/доп. рука):
  - `OH Total Increased` / `MH Total Increased` $\rightarrow$ `Увел. (доп.)` / `Увел. (осн.)` (или `Лев. % увел.` / `Прав. % увел.`)
  - `OH Total More` / `MH Total More` $\rightarrow$ `Больше (доп.)` / `Больше (осн.)`
  - `OH Eff. DPS Mod` / `MH Eff. DPS Mod` $\rightarrow$ `Эфф. DPS (доп.)` / `Эфф. DPS (осн.)`
  - `OH Hit Damage` / `MH Hit Damage` $\rightarrow$ `Урон (доп.)` / `Урон (осн.)`
  - `OH Average Hit` / `MH Average Hit` $\rightarrow$ `Сред. удар (доп.)` / `Сред. удар (осн.)`
  - `OH Crit Chance` / `MH Crit Chance` $\rightarrow$ `Крит (доп.)` / `Крит (осн.)`
  - `OH Crit Multiplier` / `MH Crit Multiplier` $\rightarrow$ `Множ. крита (доп.)` / `Множ. крита (осн.)`
  - `OH Crit Effect Mod` / `MH Crit Effect Mod` $\rightarrow$ `Эфф. крита (доп.)` / `Эфф. крита (осн.)`
  - `OH Inc. Att. Speed` / `MH Inc. Att. Speed` $\rightarrow$ `Скор. атк % (доп.)` / `Скор. атк % (осн.)`
  - `OH More Att. Speed` / `MH More Att. Speed` $\rightarrow$ `Больше ск. (доп.)` / `Больше ск. (осн.)`
  - `OH Att. per second` / `MH Att. per second` $\rightarrow$ `Атак/с (доп.)` / `Атак/с (осн.)`
  - `OH Accuracy` / `OH Chance to Hit` $\rightarrow$ `Меткость (доп.)` / `Попадание (доп.)`
- В **Ненаносящие урон недуги / Предотвращение урона / Другие эффекты**:
  - `Enemy Ail. Thresh.` $\rightarrow$ `Порог недугов врага`
  - `Spell Dodge Chance` $\rightarrow$ `Уклон. от чар`
  - `Eva. as Deflection` / `Arm. as Deflection` $\rightarrow$ `Укл. в откл.` / `Броня в откл.`
  - `Deflection Rating` / `Deflect Effect` / `Deflect Chance` $\rightarrow$ `Рейтинг откл.` / `Эфф. откл.` / `Шанс откл.`
  - `Presence Radius` / `Surrounded Radius` $\rightarrow$ `Присутствие` / `Окружение`

*(Привести в соответствие все строки `CalcSections.lua`, чтобы ни одна видимая строка при `labelWidth = 154px` не выходила за левую границу, проверив через `DrawStringWidth` в `host.exe`!)*

### 2.3. Цветовое зонирование типов урона
**Файлы:** [CalcSectionControl.lua](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Classes/CalcSectionControl.lua), [ThemeFluent.lua](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Modules/ThemeFluent.lua)

В секции `HitDamage` (и любых мультиколоночных секциях с типами урона по 6 столбцам):
1. Добавить мягкие полупрозрачные фоновые оттенки (tint) столбцов стихий и/или цветную верхнюю полоску/подсветку заголовков, чтобы `Все типы`, `Физ.`, `Молния`, `Холод`, `Огонь`, `Хаос` мгновенно различались глазами:
   - Столбец 1 (`All Types`): нейтральный (`{0.16, 0.17, 0.20, 0.35}`), жирный итог.
   - Столбец 2 (`Physical`): холодный серебристый оттенок (`{0.24, 0.24, 0.26, 0.28}`).
   - Столбец 3 (`Lightning`): приглушённый золотисто-янтарный (`{0.28, 0.25, 0.08, 0.26}`), заголовок ярче (`^xF0D050` или `colorCodes.LIGHTNING`).
   - Столбец 4 (`Cold`): приглушённый ледяной синий (`{0.09, 0.18, 0.30, 0.30}`), заголовок ярче (`^x68A8FF` или `colorCodes.COLD`).
   - Столбец 5 (`Fire`): приглушённый тёплый огненный (`{0.30, 0.13, 0.06, 0.28}`), заголовок ярче (`^xFF8844` или `colorCodes.FIRE`).
   - Столбец 6 (`Chaos`): приглушённый пурпурный (`{0.24, 0.08, 0.24, 0.28}`), заголовок ярче (`^xE060C0` или `colorCodes.CHAOS`).
2. Если значение в ячейке равно нулю (`"0"`, `"0%"`, `"0 to 0"`, `"x 0"`), приглушать цвет текста (`^8` серый), а ненулевые значения оставлять яркими (`^7` или цветом стихии для итогового DPS/Hit Damage). Это мгновенно уберёт визуальный шум и выделит реальные типы урона билда!

---

## 3. Задачи Варианта Б (Умная разгрузка пустых/нулевых секций)

**Файлы:** [CalcsTab.lua](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Classes/CalcsTab.lua), [CalcSectionControl.lua](file:///f:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/Classes/CalcSectionControl.lua)

Сейчас все активные секции защиты и второстепенных механик (например, `Энергетический щит: 0`, `Уклонение: 0`, `Руническая защита: 0`, `Уклонение (Dodge): 0%/0%`, `Отклонение: 0%`, `Флаконы: +0%, 0/s`) развёрнуты целиком даже при нулевых показателях, занимая десятки строк нулями.

**Требуется:**
1. **Тумблер (чекбокс) в верхней панели `CalcsTab` рядом с `Search`:**
   - Название: `"Скрывать пустые"` (в коде ключ `"Hide empty"` / `"Collapse zero sections"`, по умолчанию `true` — включено!).
   - Сохранять настройку в `self.input.hideEmptySections` (или загружать/сохранять в `CalcsTab:Save`/`Load` с дефолтом `true`), чтобы пользователь мог одним кликом развернуть вообще всё или вернуться к чистому виду.
2. **Логика определения «пустой» подсекции (Auto-Collapse):**
   - Для каждой `subSec`, если у неё есть `subSec.data.extra` (значение в заголовке) и в этой подсекции нет интерактивных контролов (`not self.hasControls`):
     - Проверить вычисленное строковое значение `formatCalcStr(subSec.data.extra, actor)` (очистив цветовые теги `^%d`, `^x......`).
     - Если строка заголовка представляет собой чистый ноль (например: `"0"`, `"0/0"`, `"0%"`, `"0%/0%"`, `"0/s"`, `"+0%, 0/s"`, `"0%, 0/s"`, `"0.0"`, а также для недугов при `0` DPS в заголовке: `"0% 0 0s"` / начинается с `"0% 0 "` или заканчивается на `" 0%"`), и пользователь **не** кликал по кнопке `+`/`-` вручную (`subSec.userToggled ~= true`), автоматически сворачивать подсекцию (`subSec.autoCollapsed = true`).
     - При изменении билда (если например игрок надел вещь с ЭЩ > 0) `autoCollapsed` автоматически сбрасывается в `false`, и блок мгновенно раскрывается!
     - Если пользователь вручную нажал `+` на авто-свёрнутом блоке, ставить `subSec.userToggled = true` и разворачивать его; повторный клик `-` сворачивает.
   - При выключенном тумблере «Скрывать пустые» `autoCollapsed` игнорируется (используется только `subSec.collapsed`).
3. **Заголовок свёрнутой секции (`CalcSectionControl.lua`):**
   - Даже если `subSec` свёрнута (либо вся секция свёрнута, но `enabled == true`), в шапке рядом с названием обязательно показывать `subSec.data.extra` (например: `Энергетический щит: 0`, `Уклонение: 0`), чтобы пользователь видел сводку за 1 строку! *(В оригинале `CalcSectionControl.lua:547` рисует `extra` для первой/каждой подсекции независимо от `collapsed`, но важно убедиться, что `UpdateSize` корректно выставляет высоту `22px`, если `subSection[1]` свёрнута, и не затирает `extra` кнопкой `+` справа!)*

---

## 4. Критерии приёмки и обязательные тесты (`host.exe`)

1. **Синтаксис LuaJIT:** `CalcsTab.lua`, `CalcSectionControl.lua`, `CalcSections.lua`, `UITranslationsRU.lua`, `ThemeFluent.lua` загружаются без ошибок через `loadfile` в `build-SimpleGraphic-Next/smoke/pob2lua/host.exe`.
2. **Проверка ширины всех переведённых подписей `CalcSections`:**
   - Скрипт-валидатор на `host.exe` (или Python/Lua-тест с `DrawStringWidth`) проверяет все подписи строк `CalcSections.lua` после `UITranslationsRU:Get()` и подтверждает отсутствие чрезмерно длинных переводов (> 148px при 16px VAR шрифте).
3. **Функциональный smoke-тест:**
   - Проверить вызов `CalcSectionControl` на граничных значениях `extra` (`"0"`, `"0/0"`, `"0%/0%"`, `"+0%, 0/s"`, `"2,851/2,851"`, `"100% 633,112.7 1.27s"`), подтвердить корректное срабатывание `autoCollapsed`.
   - Проверить сохранение всех регрессионных тестов (`run_batch15_modloc.lua` $\rightarrow$ **70/70 PASS**).
4. **Документация:** зафиксировать изменения в `docs/ai/CURRENT_STATE.md`, `docs/ai/DECISIONS.md` и `docs/ai/SESSION_HANDOFF.md`.
