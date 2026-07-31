---
name: advance-app-start
description: Create a new greenfield Advance initiative from any Codex project, execute only prompt 01, report result and remaining work, then wait for the programmer. Do not use for an existing application or lifecycle; use advance-app-continue instead.
---

# Advance App Start

Use this plugin skill as the global entry point to the canonical
`PromptsAdvance` catalog. Do not reproduce or replace the catalog workflow.

## Resolve and load the catalog

1. Locate the plugin root from this skill directory.
2. Discover the available PowerShell executable.
3. Run the bundled resolver:

```powershell
pwsh -NoProfile -File <absolute-plugin-root>/scripts/Resolve-AdvanceCatalog.ps1
```

Pass `-CatalogPath` when the user supplied an exact `PromptsAdvance` clone.
The resolver checks that the catalog contains `PROCESS_MANIFEST.json`,
`software-lifecycle.ps1`, and both canonical Advance skills. It may use the
configured `PROMPTS_ADVANCE_ROOT`, the installed `promptsadvance` marketplace
checkout, a bounded conventional clone path, or an ancestor of the current
working directory. Do not search the entire filesystem.

4. Read `<catalog>/.agents/skills/advance-app-start/SKILL.md` completely.
5. Follow that canonical skill from the resolved catalog root.

If the catalog cannot be resolved, stop before creating files and ask for its
exact path. Never infer another repository or download, clone, install, commit,
push, or create external resources without explicit authorization.
