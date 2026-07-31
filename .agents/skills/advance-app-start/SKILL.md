---
name: advance-app-start
description: Create and initialize a new greenfield Advance software initiative as an isolated gated lifecycle, then execute only discovery prompt 01. Use when Codex is asked to create, start, or initialize a brand-new Advance application or initiative. Do not use for an existing application, lifecycle, or filesystem project path; use advance-app-continue for those cases.
---

# Advance App Start

Create the lifecycle instance first. Do not create the application repository,
copy the boilerplate into an application, or skip product discovery and gates.

## Establish the inputs

1. Locate the nearest `PROCESS_MANIFEST.json` and `software-lifecycle.ps1` and
   treat that directory as the catalog root.
2. Read `AGENTS.md`, `EXECUTION_CONTRACT.md`, `PRODUCT_EXCELLENCE.md`,
   `APP_CONTEXT.md`, `IMPLEMENTATION_STATUS.md`, and prompt 01 completely. Read
   `HELP_AND_ACADEMY.md` when contextual help, task videos, or an Academy is in
   the approved or proposed scope.
3. Require the initiative name and product owner. Normalize a user-facing
   initiative label such as `Minha App` to a safe lowercase slug such as
   `minha-app`; report the normalization and do not present it as approved
   product naming.
4. Use the sibling `BoilerPlateAdvance` only when it exists. Otherwise require
   its exact path. Never infer or create an external repository.
5. If the request points to an existing application or lifecycle, stop this
   workflow and use `$advance-app-continue`.

## Initialize one isolated lifecycle

Discover the available PowerShell executable and run the catalog script. On
PowerShell 7 environments, use:

```powershell
pwsh -NoProfile -File ./software-lifecycle.ps1 start `
  -Name initiative-slug `
  -Owner "Product owner" `
  -BoilerplatePath "/exact/path/BoilerPlateAdvance"
```

Pass `-ProcessRoot` only when the user supplied or approved a different safe
destination. Never initialize inside the catalog or boilerplate, overwrite an
existing destination, or perform GitHub, commit, push, financial, destructive,
or production actions.

The initializer must create an isolated process, prepare `NEXT_TASK.md`, and
leave the application repository uncreated until the gated lifecycle reaches
the authorized creation prompt.

## Execute only prompt 01

Use the process root returned by the initializer:

```powershell
pwsh -NoProfile -File ./software-lifecycle.ps1 status -ProcessRoot .
pwsh -NoProfile -File ./software-lifecycle.ps1 validate -ProcessRoot .
pwsh -NoProfile -File ./software-lifecycle.ps1 next -ProcessRoot .
```

Confirm that the current prompt is `01`, then:

1. Read `NEXT_TASK.md` and every document it requires.
2. Start the durable task ledger with `software-lifecycle.ps1 work-start`.
3. Execute only prompt 01, including its zero-input discovery behavior,
   evidence requirements, and separated review requirement.
4. Checkpoint goals, record verification, register accepted adversarial issues
   with `finding-add`, resolve them only with evidence, and run `finding-gate`.
5. Close out the attempt and use `software-lifecycle.ps1 record` with
   `completed`, `partial`, or `blocked` according to the observed evidence.

Do not execute prompt 02, approve Gate A, create the application repository, or
cross an external-action boundary in the same task.

## Deliver

Report the normalized initiative slug, product owner, boilerplate path, process
root, current stage and prompt, task-ledger evidence, validation results,
findings, lifecycle result, blockers, and the next authorized action.
