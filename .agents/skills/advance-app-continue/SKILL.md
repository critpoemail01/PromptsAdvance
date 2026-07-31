---
name: advance-app-continue
description: Continue, adopt, validate, recover, or rerun an Advance application lifecycle one prompt at a time. Use for an existing application, lifecycle, or filesystem project path, when the user asks for the next prompt, a specific prompt, a rerun, or an honest readiness/result assessment.
---

# Advance App Continue

Operate the Advance catalog as a programmer-controlled prompt sequence. Execute
exactly one prompt, report its honest result, and stop. Never move to another
prompt until the programmer explicitly says `next` or names another prompt.

Use `$advance-app-start` only for a brand-new initiative without an existing
application or lifecycle.

## Locate and inspect

1. Find the nearest `PROCESS_MANIFEST.json` and `software-lifecycle.ps1`.
2. For an active lifecycle, run `status`, `validate`, and `next`, then read
   `NEXT_TASK.md` and every item in its `Required context` list completely.
3. Read [workflow.md](references/workflow.md) before choosing or repeating a
   prompt. Read [quality-gates.md](references/quality-gates.md) and the root
   `QUALITY_GATES.md` when the prompt affects architecture, UI, implementation,
   security, release, production, or operations.
   Read `HELP_AND_ACADEMY.md` when contextual help, task videos, or an Academy
   is in scope.
4. Inspect the application, Git state, code, tests, and previous prompt history.
   Existing implementation is evidence, not proof of completeness.

## Continue or adopt an existing application

For `Continue the Advance project at <path>`, run:

```powershell
.\software-lifecycle.ps1 continue -ProjectPath "<exact-existing-path>"
```

The lifecycle remains isolated from the application and must not overwrite its
files, Git history, branches, remotes, or local changes. Prompt 01 adapts to a
brownfield application by discovering the implemented product and gaps.

## Before executing a requested prompt

Check its history and the application first.

- If the prompt has already run, do not run it immediately. State its previous
  result, summary, evidence, and remaining work. Ask whether it should run again
  and require a concrete objective such as fixing pending work, revalidating
  after changes, or replacing a previous decision.
- If this is a brownfield application and no lifecycle history proves the prompt
  ran, say that clearly. Identify likely overlap with implemented behavior and
  require confirmation plus an objective before repeating that scope.
- Never claim that a prompt ran merely because similar code exists.

The supported inspection/confirmation flow is:

```powershell
.\software-lifecycle.ps1 request -ProcessRoot . -PromptId 03
.\software-lifecycle.ps1 repeat -ProcessRoot . -PromptId 03 `
  -Objective "Revalidate requirements after the billing change" -ConfirmRepeat
```

## Execute one prompt

1. Read the current packet and resolve only inputs material to this prompt.
2. Create a short plan for non-trivial work.
3. Implement the smallest coherent scope and validate it proportionately.
4. Perform an adversarial self-review. Use the task ledger and findings commands
   when the task is complex or their diagnostic value is useful; they are not a
   routine prerequisite for recording a prompt result.
5. Record one honest result and stop.

Example completed result:

```powershell
.\software-lifecycle.ps1 record -ProcessRoot . -PromptId 03 `
  -Result completed -Evidence "requirements/traceability.md" `
  -Summary "All in-scope pages and functions have detailed requirements"
```

Example incomplete result:

```powershell
.\software-lifecycle.ps1 record -ProcessRoot . -PromptId 03 `
  -Result partial -Evidence "requirements/traceability.md" `
  -Summary "Public and authenticated web requirements were captured" `
  -RemainingWork "Inventory the native application",`
                 "Validate permissions with the product owner"
```

Use:

- `completed` only when the prompt objective and criteria are satisfied;
- `partial` when useful implementation exists but work remains;
- `blocked` when a material dependency prevents safe progress;
- `not_applicable` only with evidence.

## Wait for the programmer

After `record`, do not continue automatically. Present these choices:

- `next` — prepare the following numeric prompt;
- `repeat` or `correct` — rerun the same prompt with a stated objective;
- `skip and advance` — accept listed gaps and continue with a stated reason;
- request a specific prompt — inspect its history before preparing it.

Commands:

```powershell
.\software-lifecycle.ps1 advance -ProcessRoot .
.\software-lifecycle.ps1 advance -ProcessRoot . -AcceptIncomplete `
  -Objective "Accepted by the programmer for this iteration"
```

Routine product, architecture, design, and quality gates are advisory
checklists in this default workflow. They must be reported honestly but do not
force a return to earlier prompts. Hard stops remain for secrets, impossible
technical prerequisites, and external, destructive, financial, Git, store, or
production actions without exact authorization. Release still requires the
exact candidate, environment, authorization, smoke tests, and rollback plan.

The legacy governed profile may still use `work-start`, `checkpoint`,
`finding-add`, `finding-gate`, deterministic `select`, human gates, pilot
approval, and `software-lifecycle.ps1 record` closeout. Those controls are
optional and are not the default application-development flow.

For a compatible lifecycle upgrade, keep the existing safety rule: the source manifest is `stable` and `PILOT_APPROVAL.md` is approved for the exact version
before running `software-lifecycle.ps1 upgrade -ProcessRoot <lifecycle-root>`.
Candidate catalogs may be tested in isolation but never auto-upgrade an
existing lifecycle.

## Deliver each prompt result

Start with:

1. `Result` — completed, partial, blocked, or not applicable;
2. `Achieved` — what was implemented or validated;
3. `Missing to finish` — specific implementation still required, or `none`;
4. `Evidence` — essential files and checks;
5. `Decision` — `next`, `repeat`, `correct`, or `skip and advance`.

Never hide missing work inside a long report and never prepare the next prompt
in the same task.
