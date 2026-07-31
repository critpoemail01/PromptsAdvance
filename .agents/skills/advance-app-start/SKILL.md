---
name: advance-app-start
description: Create and initialize a brand-new greenfield Advance initiative, execute only prompt 01, report its result, and wait for the programmer before moving to prompt 02. Use only when no application or lifecycle already exists.
---

# Advance App Start

Create an isolated lifecycle and execute only discovery prompt 01. The
programmer controls every later transition.

## Initialize

1. Locate the catalog `PROCESS_MANIFEST.json` and `software-lifecycle.ps1`.
2. Read `AGENTS.md`, `EXECUTION_CONTRACT.md`, `PRODUCT_EXCELLENCE.md`,
   `APP_CONTEXT.md`, `IMPLEMENTATION_STATUS.md`, and prompt 01 completely.
   Read `HELP_AND_ACADEMY.md` when contextual help, task videos, or an Academy
   is in scope.
3. Require an initiative name and owner; normalize only the filesystem slug.
4. Use the existing sibling `BoilerPlateAdvance` or an exact supplied path.
5. If an application or lifecycle already exists, stop and use
   `$advance-app-continue`.

```powershell
pwsh -NoProfile -File ./software-lifecycle.ps1 start `
  -Name initiative-slug `
  -Owner "Product owner" `
  -BoilerplatePath "/exact/path/BoilerPlateAdvance"
```

Never initialize inside the catalog or boilerplate and never overwrite an
existing destination. Do not perform GitHub, commit, push, destructive,
financial, store, or production actions without exact authorization.

## Execute prompt 01 only

Run `status`, `validate`, and `next`; read the generated `NEXT_TASK.md`; then
execute only prompt 01 with a plan and validation proportional to the work.
The task ledger is optional for complex work, not a routine blocker.

Record an honest result:

```powershell
.\software-lifecycle.ps1 record -ProcessRoot . -PromptId 01 `
  -Result completed -Evidence "PRODUCT_DEFINITION.md" `
  -Summary "Idea, audience, problem, value and MVP are defined"
```

For `partial` or `blocked`, add each specific missing item with
`-RemainingWork`. After recording, report result, achieved scope, missing work,
evidence, and the choices `next`, `repeat`, `correct`, or `skip and advance`.

Do not execute prompt 02 and do not prepare it until the programmer explicitly says
`next`.
