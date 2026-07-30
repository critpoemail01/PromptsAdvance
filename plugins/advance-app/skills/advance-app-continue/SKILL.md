---
name: advance-app-continue
description: Continue, adopt, validate, or recover an Advance application's complete gated lifecycle from any Codex project. Use when the user provides an existing application, lifecycle, or filesystem path and asks Codex to determine or execute the next authorized Advance prompt without skipping gates.
---

# Advance App Continue

Use this plugin skill as the global entry point to the canonical
`PromptsAdvance` workflow. Do not initialize a new greenfield lifecycle from
this skill; route that request to `$advance-app-start`.

## Resolve and load the catalog

1. When the supplied path already contains `LIFECYCLE_STATE.json` and
   `software-lifecycle.ps1`, treat it as the lifecycle root.
2. Otherwise locate the plugin root from this skill directory, discover the
   available PowerShell executable, and run:

```powershell
pwsh -NoProfile -File <absolute-plugin-root>/scripts/Resolve-AdvanceCatalog.ps1
```

Pass `-CatalogPath` when the user supplied an exact `PromptsAdvance` clone.
The resolver checks explicit configuration, the installed `promptsadvance`
marketplace checkout, bounded conventional clone paths, and ancestors of the
current working directory. Do not search the entire filesystem.

3. Read the canonical
   `<catalog>/.agents/skills/advance-app-continue/SKILL.md` completely.
4. Follow that canonical skill and use the resolved catalog's
   `software-lifecycle.ps1` for application-path discovery or adoption.

If neither a lifecycle root nor a valid catalog can be resolved, stop before
changing files and ask for the exact lifecycle, application, or catalog path.
Never download, clone, install, commit, push, or perform external actions
without explicit authorization.
