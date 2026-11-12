# PoB2Fork — Start Here

## Purpose

This directory contains the shared technical context for the PoB2Fork workspace.

## Read in this order

1. PROJECT_OVERVIEW.md — system architecture and repository map.
2. CURRENT_STATE.md — known implementation and localization status.
3. DECISIONS.md — accepted architectural decisions.
4. RUNBOOK.md — routine development operations.
5. SESSION_HANDOFF.md — current task handoff.

## Reference Guides & Standards

- `OPENCODE_TZ_STANDARD.md` — стандарты и шаблоны ТЗ (A/B/C) для OpenCode и AI-агентов.
- `DEV_WORKFLOW_AND_RULES.md` — пошаговый цикл разработки, правила качества и чек-лист перед релизом.
- `POE1_PORTING_PLAYBOOK.md` — пошаговое руководство по переносу локализации и UI на PoE1.
- `ARCHITECTURE_AND_CSHARP_MIGRATION.md` — 3-слойная архитектура и roadmap перехода с C++ SimpleGraphic на C# 15 / .NET 11 / WinUI 3.

## Workspace layout

The workspace root is the parent of this repository.
It is not itself a Git repository.

The main application repository is PathOfBuilding-PoE2.
Other components have their own Git roots.

## Nowledge Mem

Project Space: `pob2fork`

Local routing config:
`<workspace>/.nowledge/config.json`

The project documentation and Git repositories remain the source of truth.
Nowledge Mem stores distilled knowledge and decisions.
