# PoB2Fork — Runbook

## Entry point

Из корня workspace:

`F:\Development\Dev\mydev\PoB2Fork`

Основной PowerShell-инструмент:

`PathOfBuilding-PoE2\tools\pob2.ps1`

## PowerShell

Скрипты workspace требуют PowerShell 7 (`pwsh`). Windows PowerShell 5.1
(`powershell.exe`) неверно читает UTF-8 без BOM (`pob2.ps1` падает с ParserError)
и записывает UTF-8 **с BOM**, что ломает парсеры, чувствительные к первому байту
(.tgf конфиги шрифтов). Файлы без BOM:
`[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))`.

## Commands

Статус:

`.\PathOfBuilding-PoE2\tools\pob2.ps1 status`

Собрать общий контекст:

`.\PathOfBuilding-PoE2\tools\pob2.ps1 context`

Синхронизировать документы с Nowledge Mem:

`.\PathOfBuilding-PoE2\tools\pob2.ps1 sync`

Найти сведения:

`.\PathOfBuilding-PoE2\tools\pob2.ps1 recall "buff stat templates"`

Сохранить решение:

`.\PathOfBuilding-PoE2\tools\pob2.ps1 save -Title "Название" -Text "Описание решения"`

Подготовить handoff:

`.\PathOfBuilding-PoE2\tools\pob2.ps1 handoff`

## Direct Nowledge Mem

CLI launcher:

`%LOCALAPPDATA%\Nowledge Mem CLI\bin\nmem.cmd`

Project Space:

`pob2fork`

Пример чтения контекста:

`nmem context read --no-ensure --space-id pob2fork --json`

## Git safety

Каждый компонент проверяется отдельно:

`git -C <component-root> status --short --branch`

Не запускать Git-команды из workspace root.

## Session close procedure

1. Проверить status каждого изменённого компонента.
2. Записать фактически выполненные изменения.
3. Обновить CURRENT_STATE.md и DECISIONS.md при необходимости.
4. Подготовить SESSION_HANDOFF.md.
5. Выполнить `pob2.ps1 sync`.
6. Создать `AI_CONTEXT_PACK.md` командой handoff.
7. Не создавать commit без разрешения владельца.
