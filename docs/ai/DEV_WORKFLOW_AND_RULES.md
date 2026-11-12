# Порядок разработки и правила качества (PoB2Fork)

Единый регламент работы с кодом, локализацией, тестами и Git в проектах PoB2 и PoE1.

---

## 1. Стандартный цикл задачи (5 шагов)

1. **Pre-flight (перед правками):**
   - Прочитать `docs/ai/START_HERE.md` и `docs/ai/CURRENT_STATE.md`.
   - Проверить `git status` и текущую ветку **только** в целевом репозитории (корень workspace не является Git-репозиторием).
   - Создать резервную копию изменяемых файлов в `Snapshots/<Task>-YYYYMMDD/`.

2. **Реализация (минимальные атомарные правки):**
   - Не дублировать логику — выносить повторяющиеся проверки в helper'ы (`CalcBreakdownRU`, `ItemComparison`, `RULogger`).
   - Не смешивать логику расчётов (`Calc*`, `ModDB`) с display-переводом.
   - Проверять работу обоих переключателей языка (`uiLanguage = "EN"/"RU"` и `itemLanguage = "EN"/"RU"/"DUAL"`).

3. **Автоматическая верификация (до ручного запуска GUI):**
   - Запускать скрипты через `host.exe` с `WorkingDirectory = src/` и жёстким таймаутом:
     - `tools/ru_i18n/validate_ru_dicts.lua` → требовать `ERRORS=0 WARNINGS=0`.
     - `tools/ru_i18n/ast_audit_ru.py` → `scratch/ast_audit_host.lua` → контроль новых пропусков в `scratch/missing_to_translate.json`.
     - `tools/ru_i18n/headless_audit_ru.lua` → обход всех вкладок, `Options` и `player.breakdown`.
     - Профильные тесты (`verify_final_all.lua`, `verify_5_screenshots.lua`, `calcs_check.lua`).

4. **Обновление проектной документации:**
   - Добавить решение `D-XXX` в `docs/ai/DECISIONS.md`.
   - Обновить `docs/ai/CURRENT_STATE.md` и `docs/ai/SESSION_HANDOFF.md`.

5. **Git и релиз:**
   - Никогда не коммитить временные логи/отчёты (`scratch/`, `src/untranslated_live.log`, `to_translate_*.json`).
   - Не делать `reset --hard`, `clean -fd`, `rebase` или `commit` без подтверждения владельца.
   - Держать `upstream` на оригинальном репозитории `PathOfBuildingCommunity`, а `origin` — на форке (`ru-localization`).
   - Релизы публиковать через тег `v*-ru` (срабатывает `.github/workflows/ru-release.yml`).

---

## 2. Чек-лист перед релизом

- [ ] `git status` чистый, все изменения закоммичены в `ru-localization`.
- [ ] `validate_ru_dicts.lua` → `ERRORS=0 WARNINGS=0`.
- [ ] `headless_audit_ru.lua` → нет новых критичных пропусков `[DRAW]` / `[TT_FUNC]` / `[BD:*]`.
- [ ] `main.logUntranslatedRU == false` по умолчанию в `Main.lua`.
- [ ] `manifest.xml` в релизном архиве указывает на форк (`<owner>/<repo>/ru-localization`), а не на `PathOfBuildingCommunity`.
- [ ] Проверен запуск `Path of Building*.exe` из распакованной папки без `.git` (отсутствует предупреждение `Dev Mode`).
