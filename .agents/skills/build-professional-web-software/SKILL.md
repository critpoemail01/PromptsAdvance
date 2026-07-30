---
name: build-professional-web-software
description: Start, adopt, continue, validate, or recover the repository's complete gated lifecycle for greenfield or existing brownfield professional web software, from idea/product discovery through architecture, UX/UI, vertical-slice implementation, security, delivery, release, monitoring, ROI, bugs, and continuous improvement. Use when Codex is asked to create a new app from BoilerPlateAdvance, continue or adopt an Advance project from a filesystem path, determine or execute the next lifecycle prompt, automate the 73-prompt process, assess stage readiness, or produce professional layout, architecture, and engineering evidence without skipping gates.
---

# Build Professional Web Software

Operate the prompt catalog as a controlled software team workflow. Keep one task per prompt, use small complete vertical slices, and fail closed when a gate, decision, evidence, authorization, or independent review is missing.

## Locate the process

1. Find the nearest `PROCESS_MANIFEST.json` and `software-lifecycle.ps1`.
2. Treat that directory as the lifecycle root.
3. Read `AGENTS.md`, `EXECUTION_CONTRACT.md`, `APP_CONTEXT.md`, `IMPLEMENTATION_STATUS.md`, `LIFECYCLE_STATE.json` when present, and the current prompt.
4. Read [workflow.md](references/workflow.md) completely before selecting a prompt or crossing a stage.
5. Read [quality-gates.md](references/quality-gates.md) and the root `QUALITY_GATES.md` before architecture, UI/UX, implementation, hardening, acceptance, release, or operations work.

## Start a new initiative

Require a safe initiative slug and a product owner. Use the sibling `BoilerPlateAdvance` only when it exists; otherwise require its exact path.

Run:

```powershell
.\software-lifecycle.ps1 start -Name initiative-slug -Owner "Product owner"
```

Pass `-ProcessRoot` or `-BoilerplatePath` only when needed. Never initialize inside the catalog, overwrite an existing destination, or infer an external repository.

Report the created path and execute only prompt 01 from `NEXT_TASK.md`. Do not mark Gate A complete.

## Continue an initiative

From the instance root:

```powershell
.\software-lifecycle.ps1 status -ProcessRoot .
.\software-lifecycle.ps1 validate -ProcessRoot .
.\software-lifecycle.ps1 next -ProcessRoot .
```

If validation fails, repair lifecycle metadata only when evidence supports it. Do not bypass a failed product, architecture, design, security, release, or production gate.

## Continue or adopt from an application path

Treat natural-language requests such as `Continua o projeto Advance em
C:\Work\produto` as path-based lifecycle discovery. Require the exact existing
directory, then run the catalog entry point:

```powershell
.\software-lifecycle.ps1 continue -ProjectPath "C:\Work\produto"
```

Pass `-Owner` when the user supplied the product owner. Do not invent it; a
brownfield lifecycle may start with the owner pending. Prompt 01 performs
zero-input market discovery without asking for that owner; the owner must be
resolved by prompt 04 before Gate G01.

The command must:

- use `LIFECYCLE_STATE.json` directly when the supplied path is already a
  lifecycle root;
- resolve an existing isolated process whose `applicationRoot` matches;
- otherwise create an isolated brownfield process outside both the application
  and `BoilerPlateAdvance`, and outside the existing Git repository tree;
- capture only non-sensitive Git baseline metadata and leave application files,
  `.git`, history, branches, working-tree changes and remotes untouched;
- validate the lifecycle and prepare `NEXT_TASK.md`.

After resolution, use the returned process root to run `status`, `validate` and
`next`, then execute only `NEXT_TASK.md`. For brownfield work, use the
application as evidence but never infer that existing behavior satisfies a
requirement or gate. Prompt 07 performs the controlled adoption baseline instead
of copying the boilerplate over the application.

Use the explicit initializer when discovery is not desired:

```powershell
.\software-lifecycle.ps1 adopt `
  -ProjectPath "C:\Work\produto" `
  -Name produto `
  -Owner "Product owner"
```

## Execute the current task

1. Read `NEXT_TASK.md` and its embedded prompt.
2. Resolve all material inputs and show their source/confidence/status.
3. Start the durable task ledger with `work-start`; for non-trivial work, pass
   the staged plan as `kind::description` goals.
4. Checkpoint goals with evidence, and record proportionate validation with
   `verify`.
5. Implement only the current prompt or selected vertical-slice lot.
6. Run prompt-specific checks plus the applicable quality gate.
7. Perform an adversarial self-review. Record accepted issues with
   `finding-add`, resolve them only with correction and verification evidence,
   then run `finding-gate`. Call a review independent only when another
   separated reviewer/task actually performed it.
8. Update human-readable artefacts and durable evidence.
9. Record the result with the lifecycle tool. `completed` is rejected until
   the task-ledger closeout passes; use `partial` or `blocked` honestly when it
   does not.

Example start:

```powershell
.\software-lifecycle.ps1 work-start `
  -ProcessRoot . `
  -Goal "inspect::Confirm current behavior and evidence",
        "change::Execute the scoped prompt",
        "verify::Run proportionate validation",
        "review::Perform adversarial self-review"
```

For a small, fully evidenced task, `closeout` may complete the standard goals
atomically, but it still requires a passing verification record, adversarial
review evidence and zero open findings. Complex tasks should checkpoint each
goal separately so the evidence remains diagnostic.

Example:

```powershell
.\software-lifecycle.ps1 record `
  -ProcessRoot . `
  -PromptId 03 `
  -Result completed `
  -Evidence "IMPLEMENTATION_STATUS.md; requirements/traceability.md"
```

Deterministic transitions are selected automatically. When the lifecycle enters
`waiting_decision`, use `select` with the allowed decision shown by `status`;
never force `NextPrompt`. Use `partial` or `blocked` when evidence is
incomplete. For a human gate, also pass `-GateId`, `-GateDecision`,
`-GateEvidence`, and `-ApprovedBy`. Never manufacture the approver.

## Route work correctly

- Follow 01–12 linearly, subject to G01/G02/G03.
- After prompt 12, do not continue numerically.
- Select a small vertical slice and store its requirement IDs, kind, surface, acceptance criteria, exclusions, and evidence in `LIFECYCLE_STATE.json` and `IMPLEMENTATION_STATUS.md`.
- Use the lifecycle selector instead of editing `currentPrompt` directly:

```powershell
.\software-lifecycle.ps1 select `
  -ProcessRoot . `
  -PromptId 19 `
  -SliceId "SLICE-001" `
  -SliceKind page `
  -Surface web `
  -Requirements "FR-001, SEC-001" `
  -AcceptanceCriteria "FR-001 succeeds; SEC-001 denies unauthorized access" `
  -OutOfScope "billing, native app and external identity providers" `
  -Evidence "PRODUCT_DEFINITION.md; IMPLEMENTATION_STATUS.md"
```

- For the first slice, establish backend/data/auth foundations with 19–22 only as needed.
- For a page, execute 25, the surface prompt 13/15/17, then 26.
- For a feature, execute 27, the surface prompt 13/15/17, then 28.
- Repeat until every `Must` journey is evidenced.
- Execute 23/24 and 14/16/18 only when closing the applicable global/surface scope.
- Select optional prompts only from approved architecture or requirements.
- Record a proven exclusion with `software-lifecycle.ps1 decide -PromptId <ID> -Result not_applicable -Evidence "<decision>"`; never leave conditional work silently skipped before its exit gate.
- Use `software-lifecycle.ps1 gate` for a gate that is reached between prompts, after all manifest prerequisites pass. Never edit gate JSON directly.
- Continue through security, public presence, hardening, delivery, operations, acceptance, independent review, authorized release, and recurring operations according to [workflow.md](references/workflow.md).

When the next prompt is not mechanically determined, leave `currentPrompt` empty, set a precise `nextAction`, and stop for the smallest material decision. Never use numeric order to invent a product decision.

## Preserve professional quality

Require observable evidence, not adjectives:

- architecture mapped to requirements, C4/ADRs, dependency rules, contracts, threat model, and operational trade-offs;
- code that respects repository boundaries, naming, tests, analyzers, data integrity, authorization, observability, and recovery;
- UI with product-specific hierarchy, information architecture, tokens, responsive behavior, complete states, accessibility, real content, render evidence, visual regression, and professional critique;
- immutable release candidates, separated read-only review, smoke tests, monitoring, and rollback;
- structured G06–G10 evidence in `LIFECYCLE_GATE_EVIDENCE.json`, including verified local artifact hashes, identities and exact release authorization before prompt 64;
- post-release SLO, RUM/Core Web Vitals, bugs, costs, vulnerabilities, DORA, and ROI feedback.

Do not promise zero bugs, professional usability, accessibility conformance, or production readiness without the evidence required by `QUALITY_GATES.md`.

## Use team separation

Use distinct roles/tasks when available:

- product discovery and requirements;
- architecture/security design;
- Product Design/UX critique;
- implementation;
- QA/accessibility/performance;
- security review;
- SRE/operational readiness;
- final independent read-only review.

Parallelize only bounded read-only or isolated work. Never let two live tasks edit the same checkout. A role label alone does not create independence.

## Respect authorization

Auto-continue through local reversible work. Stop before external, destructive, financial, legal, identity, GitHub, baseline-changing, store, or production actions unless the exact target and authorization are recorded.

Plan or Goal mode never broadens permission.

## Deliver

Always finish with:

- current stage, prompt, and gate;
- result and evidence;
- files or artefacts changed;
- validation and adversarial findings;
- blockers and residual risks;
- next authorized prompt/action;
- lifecycle state: `completed`, `partial`, `blocked`, or `waiting_decision`.
