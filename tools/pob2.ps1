[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet("help","status","context","sync","recall","save","handoff")]
    [string]$Command = "help",

    [Parameter(Position=1)]
    [string[]]$Query,

    [string]$Title,
    [string]$Text,
    [string]$Id
)

$ErrorActionPreference = "Stop"

$script:AppRepo = Split-Path -Parent $PSScriptRoot
$script:WorkspaceRoot = Split-Path -Parent $script:AppRepo
$script:DocsRoot = Join-Path $script:AppRepo "docs\ai"
$script:SpaceId = "pob2fork"

$configPath = Join-Path $script:WorkspaceRoot ".nowledge\config.json"

if (Test-Path -LiteralPath $configPath -PathType Leaf) {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    if (-not [string]::IsNullOrWhiteSpace($config.space)) {
        $script:SpaceId = [string]$config.space
    }
}

$script:NmemExe = Join-Path $env:LOCALAPPDATA "Nowledge Mem\_up_\rust-backend\nmem.exe"

if (-not (Test-Path -LiteralPath $script:NmemExe -PathType Leaf)) {
    throw "Nowledge Mem CLI не найден: $script:NmemExe"
}



$script:Repos = @(
    [PSCustomObject]@{
        Name = "PathOfBuilding-PoE2"
        Path = $script:AppRepo
    },
    [PSCustomObject]@{
        Name = "PathOfBuilding-SimpleGraphic"
        Path = Join-Path $script:WorkspaceRoot "PathOfBuilding-SimpleGraphic"
    },
    [PSCustomObject]@{
        Name = "RePoE"
        Path = Join-Path $script:WorkspaceRoot "PoE2-Localization-Extractor\RePoE"
    },
    [PSCustomObject]@{
        Name = "PyPoE"
        Path = Join-Path $script:WorkspaceRoot "PoE2-Localization-Extractor\PyPoE"
    },
    [PSCustomObject]@{
        Name = "PathOfExile_Translated"
        Path = Join-Path $script:WorkspaceRoot "PoE2-Localization-Extractor\PathOfExile_Translated"
    }
)

function Invoke-Nmem {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Arguments,

        [AllowEmptyString()]
        [string]$StandardInput
    )

    $hasInput = $PSBoundParameters.ContainsKey("StandardInput")

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $script:NmemExe
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardInput = $hasInput

    # Correct Windows command-line quoting for every argument.
    $quotedArguments = @()

    foreach ($argument in $Arguments) {
        $value = [string]$argument

        if ($value.Length -gt 0 -and $value -notmatch '[\s"]') {
            $quotedArguments += $value
            continue
        }

        $builder = New-Object System.Text.StringBuilder
        [void]$builder.Append([char]34)

        $backslashCount = 0

        for ($i = 0; $i -lt $value.Length; $i++) {
            $character = $value[$i]

            if ($character -eq [char]92) {
                $backslashCount++
                continue
            }

            if ($character -eq [char]34) {
                [void]$builder.Append(('\' * ($backslashCount * 2 + 1)))
                [void]$builder.Append([char]34)
                $backslashCount = 0
                continue
            }

            if ($backslashCount -gt 0) {
                [void]$builder.Append(('\' * $backslashCount))
                $backslashCount = 0
            }

            [void]$builder.Append($character)
        }

        if ($backslashCount -gt 0) {
            [void]$builder.Append(('\' * ($backslashCount * 2)))
        }

        [void]$builder.Append([char]34)
        $quotedArguments += $builder.ToString()
    }

    $psi.Arguments = $quotedArguments -join ' '

    $utf8 = New-Object System.Text.UTF8Encoding($false)

    try {
        $psi.StandardOutputEncoding = $utf8
        $psi.StandardErrorEncoding = $utf8
    }
    catch {
        # Default .NET stream encoding remains available.
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    try {
        if (-not $process.Start()) {
            throw "Не удалось запустить nmem.exe."
        }

        # Begin draining output before writing stdin to avoid pipe deadlocks.
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()

        if ($hasInput) {
            $inputBytes = [System.Text.Encoding]::UTF8.GetBytes($StandardInput)
            $inputStream = $process.StandardInput.BaseStream

            if ($inputBytes.Length -gt 0) {
                $inputStream.Write($inputBytes, 0, $inputBytes.Length)
                $inputStream.Flush()
            }

            $process.StandardInput.Close()
        }

        $process.WaitForExit()

        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()

        if ($process.ExitCode -ne 0) {
            throw "nmem завершился с кодом $($process.ExitCode).`nSTDOUT:`n$stdout`nSTDERR:`n$stderr"
        }

        if (-not [string]::IsNullOrWhiteSpace($stderr)) {
            Write-Warning $stderr
        }

        return $stdout.Trim()
    }
    finally {
        $process.Dispose()
    }
}

function Get-RepoStatus {
    param([PSCustomObject]$Repo)

    if (-not (Test-Path -LiteralPath $Repo.Path -PathType Container)) {
        return "MISSING: $($Repo.Path)"
    }

    $output = & git -C $Repo.Path status --short --branch 2>&1
    $exitCode = $LASTEXITCODE
    $rendered = ($output | Out-String).Trim()

    if ($exitCode -ne 0) {
        return "NOT A GIT REPOSITORY: $($Repo.Path)"
    }

    if ([string]::IsNullOrWhiteSpace($rendered)) {
        $rendered = "Clean working tree"
    }

    return $rendered
}

function New-HandoffPack {
    $contextJson = Invoke-Nmem -Arguments @(
        "context", "read",
        "--no-ensure",
        "--space-id", $script:SpaceId,
        "--json"
    )

    $bundle = $contextJson | ConvertFrom-Json
    $builder = New-Object System.Text.StringBuilder

    [void]$builder.AppendLine("# PoB2Fork — AI Context Pack")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
    [void]$builder.AppendLine("Workspace: $script:WorkspaceRoot")
    [void]$builder.AppendLine("Main repository: $script:AppRepo")
    [void]$builder.AppendLine("Nowledge Mem Space: $script:SpaceId")
    [void]$builder.AppendLine()

    [void]$builder.AppendLine("---")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine($bundle.rendered_markdown)
    [void]$builder.AppendLine()

    $documents = @(
        "PROJECT_OVERVIEW.md",
        "CURRENT_STATE.md",
        "DECISIONS.md",
        "RUNBOOK.md",
        "SESSION_HANDOFF.md"
    )

    foreach ($name in $documents) {
        $path = Join-Path $script:DocsRoot $name

        if (Test-Path -LiteralPath $path -PathType Leaf) {
            [void]$builder.AppendLine("---")
            [void]$builder.AppendLine()
            [void]$builder.AppendLine("# DOCUMENT: $name")
            [void]$builder.AppendLine()
            [void]$builder.AppendLine(
                ([System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8))
            )
            [void]$builder.AppendLine()
        }
    }

    [void]$builder.AppendLine("---")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine("# Git repository status")
    [void]$builder.AppendLine()

    foreach ($repo in $script:Repos) {
        [void]$builder.AppendLine("## $($repo.Name)")
        [void]$builder.AppendLine()
        [void]$builder.AppendLine("Path: $($repo.Path)")
        [void]$builder.AppendLine()
        [void]$builder.AppendLine('```text')
        [void]$builder.AppendLine((Get-RepoStatus -Repo $repo))
        [void]$builder.AppendLine('```')
        [void]$builder.AppendLine()
    }

    $reportDir = Join-Path $script:WorkspaceRoot "reports"
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

    $reportPath = Join-Path $reportDir "AI_CONTEXT_PACK.md"
    $encoding = New-Object System.Text.UTF8Encoding($false)

    [System.IO.File]::WriteAllText(
        $reportPath,
        $builder.ToString(),
        $encoding
    )

    return $reportPath
}

function Show-Status {
    Write-Host "`n=== WORKSPACE ===" -ForegroundColor Cyan
    Write-Host $script:WorkspaceRoot

    Write-Host "`n=== NOWLEDGE MEM ===" -ForegroundColor Cyan
    Write-Host (Invoke-Nmem -Arguments @("status"))

    Write-Host "`n=== SPACE ===" -ForegroundColor Cyan
    Write-Host "Space ID: $script:SpaceId"

    Write-Host "`n=== GIT REPOSITORIES ===" -ForegroundColor Cyan

    foreach ($repo in $script:Repos) {
        Write-Host "`n--- $($repo.Name) ---" -ForegroundColor Yellow
        Write-Host (Get-RepoStatus -Repo $repo)
    }
}

function Sync-Documents {
    $items = @(
        [PSCustomObject]@{
            File = "PROJECT_OVERVIEW.md"
            Id = "pob2fork-overview"
            Title = "PoB2Fork — Project Overview"
        },
        [PSCustomObject]@{
            File = "CURRENT_STATE.md"
            Id = "pob2fork-current-state"
            Title = "PoB2Fork — Current State"
        },
        [PSCustomObject]@{
            File = "DECISIONS.md"
            Id = "pob2fork-decisions"
            Title = "PoB2Fork — Architecture Decisions"
        },
        [PSCustomObject]@{
            File = "RUNBOOK.md"
            Id = "pob2fork-runbook"
            Title = "PoB2Fork — Runbook"
        }
    )

    foreach ($item in $items) {
        $path = Join-Path $script:DocsRoot $item.File

        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Write-Warning "Документ отсутствует: $path"
            continue
        }

        $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

        if ($content.Length -gt 20000) {
            throw "Документ слишком большой для безопасной передачи через аргументы CLI: $path"
        }

        Write-Host "`nSync: $($item.File)" -ForegroundColor Cyan

        $result = Invoke-Nmem -Arguments @(
            "memories", "add",
            "--id", $item.Id,
            "--title", $item.Title,
            "--importance", "0.85",
            "--unit-type", "context",
            "--labels", "pob2fork,workspace-context",
            "--source", "pob2fork-workspace",
            "--source-app", "pob2.ps1",
            "--space-id", $script:SpaceId,
            "--json",
            "--stdin"
        ) -StandardInput $content

        Write-Host $result
    }
}

function Save-Memory {
    if ([string]::IsNullOrWhiteSpace($Title)) {
        throw "Для save нужно указать -Title."
    }

    if ([string]::IsNullOrWhiteSpace($Text)) {
        throw "Для save нужно указать -Text."
    }

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $suffix = [Guid]::NewGuid().ToString("N").Substring(0,8)
        $Id = "pob2fork-note-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$suffix"
    }

    $result = Invoke-Nmem -Arguments @(
        "memories", "add",
        "--id", $Id,
        "--title", $Title,
        "--importance", "0.75",
        "--unit-type", "context",
        "--labels", "pob2fork,technical-note",
        "--source", "pob2fork-workspace",
        "--source-app", "pob2.ps1",
        "--space-id", $script:SpaceId,
        "--json",
        "--stdin"
    ) -StandardInput $Text

    Write-Host $result
}

switch ($Command) {
    "help" {
        Write-Host @"
PoB2Fork workspace utility

Commands:
  status
  context
  sync
  recall <query>
  save -Title <title> -Text <text> [-Id <stable-id>]
  handoff

Examples:
  .\tools\pob2.ps1 status
  .\tools\pob2.ps1 context
  .\tools\pob2.ps1 sync
  .\tools\pob2.ps1 recall "buff stat templates"
  .\tools\pob2.ps1 save -Title "Decision" -Text "Description"
  .\tools\pob2.ps1 handoff
"@
    }

    "status" {
        Show-Status
    }

    "context" {
        $path = New-HandoffPack
        Write-Host "Контекст подготовлен: $path" -ForegroundColor Green
    }

    "handoff" {
        $path = New-HandoffPack
        Write-Host "Handoff создан: $path" -ForegroundColor Green
    }

    "sync" {
        Sync-Documents
    }

    "recall" {
        if (-not $Query -or $Query.Count -eq 0) {
            throw "Укажите поисковый запрос."
        }

        $arguments = @(
            "memories", "search",
            "--space-id", $script:SpaceId,
            "--limit", "15",
            "--json"
        )

        $arguments += $Query

        Write-Host (Invoke-Nmem -Arguments $arguments)
    }

    "save" {
        Save-Memory
    }
}
