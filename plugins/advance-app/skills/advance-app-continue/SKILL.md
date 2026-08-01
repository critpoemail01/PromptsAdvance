---
name: advance-app-continue
description: Continue, adopt, validate, recover, request, rerun, run, or stop an Advance application and lifecycle from any Codex project. Use under explicit programmer control, including when the user says to run/start/stop the app or "corre a app".
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
   For `run/start/corre a app`, follow its local-run procedure and start the
   exact `Server.Api`, `Client.Ssr`, and real `Client.Web`/`Cliente.Web`
   projects without advancing lifecycle state.
5. When an existing lifecycle uses an older compatible catalog, use the
   canonical `software-lifecycle.ps1` as the migration entry point. Automatic
   upgrades still require a `stable` source and exact approved pilot. If the
   programmer explicitly requested continuation and the old embedded script
   predates `advance`, that same request authorizes a controlled local
   migration with `upgrade -ConfirmMigration -AcceptCandidateCatalog
   -Objective "<continuation reason>"`, followed by `advance` in the migrated
   instance. Do not ask for a duplicate confirmation, overwrite product
   artefacts, edit lifecycle state directly, or treat a pending catalog pilot
   as a blocker to local application development. Preserve and report all gaps.
   External, destructive, Git, release, store, financial, and production
   actions retain their specific authorization requirements.

The canonical skill reports every prompt result and remaining implementation,
then waits for `next`, `repeat`, `correct`, or `skip and advance`. It inspects
history or brownfield overlap and obtains a concrete objective before repeating
a prompt.

If neither a lifecycle root nor a valid catalog can be resolved, stop before
changing files and ask for the exact lifecycle, application, or catalog path.
Never download, clone, install, commit, push, or perform external actions
without explicit authorization.
