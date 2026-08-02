---
name: advance-app-continue
description: Continue, adopt, validate, recover, correct, rerun, run, or stop an Advance application and its lifecycle. Use for an existing application, lifecycle, or filesystem project path when the user asks for the next prompt, a specific prompt, a correction, a rerun, an honest readiness/result assessment, or says to run/start/stop the app (including "corre a app").
---

# Advance App Continue

Operate the Advance catalog as a programmer-controlled prompt sequence. Execute
exactly one prompt, report its honest result, and stop. Never move to another
prompt until the programmer explicitly says `next` or names another prompt.

Use `$advance-app-start` only for a brand-new initiative without an existing
application or lifecycle.

## Assume a production-bound application

Treat every Advance application as a final product intended for production.
Never offer prototype/MVP/pilot versus production maturity profiles. The
manifest's `fast`, `standard`, and `deep` execution profiles control only the
proportional effort for an individual prompt; they do not lower final quality.

The programmer may stop, reorder, waive, or defer non-critical work, but do not
call the lifecycle complete or the application production-ready until every
hard-required prompt is completed, every other prompt has an explicit result or
disposition, no partial/blocked work remains, and G10 has passed. Reaching the
last numeric prompt is not completion. Report `not_production_ready` and the
exact gaps instead. This assumption never authorizes deployment, stores,
production resources, costs, or another external action.

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
   After correcting a defect or recurring weakness, read
   `UPSTREAM_LEARNING.md` completely and apply its recurrence classification,
   upstream generalization, privacy, regression, and authorization rules.
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

## Run the local application

Treat `run the app`, `start the app`, `corre a app`, and equivalent wording as
an operational request, not as permission to execute or advance a lifecycle
prompt. Resolve the application root from lifecycle state, `APP_CONTEXT.md`, or
the current repository, then discover exactly one executable project for each
of these roles:

- `<App>.Server.Api`;
- `<App>.Client.Ssr`;
- `<App>.Client.Web` (also accept `<App>.Cliente.Web` only when that is the real
  project name in the repository).

Use the real `.csproj`, solution, launch profiles, SDK and commands from the
repository. Never substitute `Server.Web`, `Client.Core`, `Client.Maui`,
`Client.Windows`, or another project for a missing role. If any role is missing
or ambiguous, report the exact matches and stop without starting a partial app,
unless the programmer explicitly asks for a partial run.

Before starting new processes, resolve the lifecycle root and run its canonical
allocator:

```powershell
.\scripts\Manage-AdvanceLocalPorts.ps1 status `
  -ApplicationRoot "<exact application root>" -ProcessRoot "<lifecycle root>" -Json
.\scripts\Manage-AdvanceLocalPorts.ps1 reserve `
  -ApplicationRoot "<exact application root>" -ProcessRoot "<lifecycle root>" -Json
```

The machine-local registry assigns a locked ten-port block per application:
API HTTP/HTTPS at base/base+1, SSR at base+2/base+3, and Web at
base+4/base+5. MAUI uses the reserved API URL and does not receive a listener.
Never fall back to boilerplate/default fixed ports when a reservation exists.
Never commit `APP_LOCAL_PORTS.json` or copy it to shared/remote configuration.

If reserved ports are listening, first inspect the owning commands/processes.
Reuse them only when all roles match this exact application and are healthy. If
a listener belongs elsewhere, call `reserve -ReallocateIfOccupied`, then apply
the returned API/SSR/Web URLs consistently to local client configuration, CORS,
redirects and launch commands. Do not reallocate a healthy running instance.
Immediately before each launch, verify the assigned listener is still free; if
binding loses a race, stop only the processes started in this attempt,
reallocate once and retry with the complete new block.

Start the API first and wait until its listener or health endpoint is ready;
then start SSR and Web concurrently in separate persistent terminal sessions.
Pass each reserved pair through the repository's supported local mechanism,
preferably `ASPNETCORE_URLS` or the real `--urls` option, and pass the reserved
API URL through the application's typed local API-base setting. Do not edit
committed `launchSettings.json` merely to change machine ports.
Reuse an already healthy matching process instead of launching a duplicate.
Keep all three processes alive after replying and report, for each role, the
project, session/process identifier, URL, and readiness or error. Do not claim
the app is running when one of the three exited or never became reachable.

Default to the local development environment. This request does not authorize
deployment, production, external services, data resets, migrations with side
effects, or secrets. When asked to stop the app, terminate only the exact
sessions/processes started or identified for these three roles; never kill all
`dotnet` processes broadly. Keep its reservation after stopping so the URLs are
stable. Release it only when the programmer explicitly asks to remove/liberate
that application's local port reservation:

```powershell
.\scripts\Manage-AdvanceLocalPorts.ps1 release `
  -ApplicationRoot "<exact application root>" -ProcessRoot "<lifecycle root>"
```

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

## Decide without executing a prompt

Read `PROCESS_MANIFEST.json` before deciding. Every prompt has one stable class:

- `hard_required`: critical invariant; it cannot be skipped or dispositioned;
- `recommended`: normal path, but the programmer may waive or defer it;
- `conditional`: execute when its capability/surface/risk applies;
- `optional`: execute only when it adds value to this product.

At a prompt boundary, the programmer may decide any non-critical prompt before
execution with one short reason:

```powershell
.\software-lifecycle.ps1 decide -ProcessRoot . -PromptId 03 `
  -Result deferred -Evidence "Requirements workshop moves to the next iteration"
.\software-lifecycle.ps1 decide -ProcessRoot . -PromptId 33 `
  -Result not_applicable -Evidence "This application has no billing"
.\software-lifecycle.ps1 decide -ProcessRoot . -PromptId 48 `
  -Result waived -Evidence "Advertising is excluded from this product"
```

Use `not_applicable` when the scope does not apply, `waived` when it applies but
the programmer accepts omitting it, and `deferred` when it should be revisited.
Do not translate these into `partial` or `blocked`: those are execution results.
`advance` skips recorded dispositions. A later `request`/`repeat` may reopen the
prompt after showing its history and receiving a concrete objective.

## Execute one prompt

1. Read the current packet and resolve only inputs material to this prompt.
2. Create a short plan for non-trivial work.
3. Implement the smallest coherent scope and validate it proportionately.
4. Perform an adversarial self-review. Use the task ledger and findings commands
   when the task is complex or their diagnostic value is useful; they are not a
   routine prerequisite for recording a prompt result.
5. Record one honest result and stop.

## Learn from application corrections

After fixing a defect in an Advance application, do not assume the lesson is
application-specific. Follow `UPSTREAM_LEARNING.md` before the final response:

1. validate the application fix;
2. classify the root cause as `advanceappflow_systemic`,
   `boilerplate_systemic`, `application_specific`, or `unknown`;
3. for a systemic cause, update a safe canonical AdvanceAppFlow development
   clone with the smallest generalized correction and a regression oracle;
4. if safe upstream integration is unavailable, write
   `reports/ADVANCEAPPFLOW_UPSTREAM_FEEDBACK.md` in the application instead;
5. report the application result separately from the AdvanceAppFlow learning.

Never copy secrets, customer data, private URLs, app-specific names, or
proprietary domain logic into the catalog. This local learning rule does not
authorize commit, push, PR, publication, production, or another external
action.

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
- `not_applicable` only with evidence and never for a `hard_required` prompt.

## Wait for the programmer

After `record`, do not continue automatically. Present these choices:

- `next` — prepare the following numeric prompt;
- `repeat` or `correct` — rerun the same prompt with a stated objective;
- `skip and advance` — accept listed gaps and continue with a stated reason;
- `decide` — disposition a future non-critical prompt with a short reason;
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

For a compatible automatic lifecycle upgrade, keep the existing safety rule:
the source manifest is `stable` and `PILOT_APPROVAL.md` is approved for the
exact version before running
`software-lifecycle.ps1 upgrade -ProcessRoot <lifecycle-root>`.

An old lifecycle must not trap an explicit programmer decision merely because
its embedded script predates `advance`. When the programmer explicitly asks to
continue or accepts incomplete work, use the canonical script to perform the
controlled local migration, preserve history/evidence, and then advance:

```powershell
<canonical>/software-lifecycle.ps1 upgrade -ProcessRoot <lifecycle-root> `
  -ConfirmMigration -AcceptCandidateCatalog `
  -Objective "Programmer requested continuation with recorded gaps"
<lifecycle-root>/software-lifecycle.ps1 advance -ProcessRoot <lifecycle-root> `
  -AcceptIncomplete -Objective "Gaps accepted by the programmer for this iteration"
```

The programmer's explicit continuation request is the authorization for this
local lifecycle migration; do not ask for a second confirmation and do not
report the catalog pilot as an application-development blocker. Never rewrite
state JSON by hand. Report the candidate status and preserved gaps honestly.
This exception does not authorize external, destructive, Git, release, store,
financial, or production actions.

## Deliver each prompt result

Start with:

1. `Result` — completed, partial, blocked, or not applicable;
2. `Achieved` — what was implemented or validated;
3. `Missing to finish` — specific implementation still required, or `none`;
4. `Evidence` — essential files and checks;
5. `Decision` — `next`, `repeat`, `correct`, `skip and advance`, or disposition
   a future non-critical prompt.

Never hide missing work inside a long report and never prepare the next prompt
in the same task.
