# Lifecycle workflow

## Contents

1. Operating loop
2. Stages and gates
3. Vertical-slice routing
4. Optional capabilities
5. Release and operations
6. Recovery rules

## 1. Operating loop

For every task:

1. inspect `status`;
2. run `validate`;
3. prepare `next`;
4. resolve inputs and plan;
5. execute one prompt;
6. validate behavior and perform adversarial review;
7. update evidence;
8. record the honest result;
9. cross a gate only with its required evidence and approval.

Keep related work in the same initiative, but use one Codex task per coherent prompt/slice result. Use isolated worktrees for concurrent changes.

For `brownfield`, the lifecycle process remains outside the existing
application. Path-based `continue` resolves the linked process or initializes
one without modifying the application. Prompts 01-06 establish approved product,
current/target architecture and threat-model evidence; prompt 07 captures the
existing repository baseline and gap map. Existing code never skips a prompt or
gate by itself.

## 2. Stages and gates

| Stage | Prompts/work | Exit condition |
|---|---|---|
| 01 Product definition | 01–04 | G01: `PRODUCT_DEFINITION.md` approved; DOR-01–12 and script pass |
| 02 Architecture/foundation | 05–10 | G02: architecture, threat model, repo, Codex setup, environments and contracts approved |
| 03 Design foundation | 11–12 | G03: identity, professional baseline, first slice and current pilot ready |
| Vertical slices | 19–28 plus 13/15/17 | G04 first slice design approval, then repeat |
| Functional completion | 23/24, 14/16/18, 29 and selected optionals | G05: all `Must` journeys pass |
| Security/public/hardening | 38–54 as applicable | G06: no critical finding; evidence complete |
| Delivery/operations | 55–60 as applicable | G07: CI/CD, SLO, DR and runbooks ready |
| Acceptance/review | 61–63 | G08: immutable candidate accepted and independently reviewed |
| Release | 64 | G09: authorize the exact candidate before 64; after deploy, revalidate that same candidate/environment plus smoke tests and rollback readiness |
| Continuous operations | 65–73 as applicable | G10: recurring owners/cadences established |

The numeric stage folders organize ownership; they are not a command to finish all layout before backend. After prompt 12, use the slice loop.

## 3. Vertical-slice routing

Define an active slice with:

- stable requirement IDs;
- one user outcome;
- kind: `page` or `feature`;
- surface: `ssr`, `web`, or `maui`;
- acceptance criteria;
- out of scope;
- data, actor and permission;
- expected states;
- evidence plan.

When prompt 12 leaves the lifecycle in `waiting_decision`, select the first
authorized prompt through `software-lifecycle.ps1 select`; never edit
`currentPrompt` directly. Use prompt 19 for the first backend foundation when
needed, otherwise select 25 or 27 with the approved slice metadata.

Queue:

```text
first slice foundation, when needed: 19 -> 20 -> 21 -> 22
page: 25 -> 13|15|17 -> 26
feature: 27 -> 13|15|17 -> 28
```

The surface prompt is repeatable per slice. After each slice, obtain design/engineering critique and test usability when required. Do not propagate a visual pattern until G04 passes.

When every `Must` journey passes:

1. execute 23/24 for global requirements;
2. execute 14/16/18 only for active surfaces;
3. complete 29 if transactional email is required;
4. run selected optional capabilities;
5. cross G05.

## 4. Optional capabilities

Start optional prompts as `not_selected`. Select them only when an approved requirement or architecture decision identifies applicability.

- 30–37: billing, localization, external login, passkeys, jobs, realtime, push/deep links, uploads;
- 38: operational privacy/data rights;
- 45–47: advertising, retention and loyalty;
- 50: PWA/offline/update;
- 56: infrastructure as code;
- 57: store distribution;
- 65/66/69/71: cache, public SEO, RUM and cost monitoring where applicable.

Record `not_applicable` with evidence instead of silently skipping. A future requirement reopens the prompt.

Use the lifecycle `decide` command for those exclusions. Before G05, explicitly
decide unused foundation, surface, page/feature and email prompts; before later
gates, decide every optional prompt owned by that gate. Use the standalone
`gate` command when the gate is reached between prompt executions.

## 5. Release and operations

Prompt 62 accepts a specific candidate. Prompt 63 reviews the same SHA/digest in a separate read-only task. A finding creates a new candidate and invalidates the old approval.

Prompt 64 requires:

- G08 passed;
- exact environment, SHA, digest and release window;
- explicit release authorization;
- migration strategy, smoke tests, observability and rollback.

G09 is deliberately two-phase: its authorization snapshot must pass before
prompt 64 can be selected; after deployment, prompt 64 cannot complete until
the deployment section for the same candidate, digest and environment passes
again. Authorization is never inferred from a successful deploy.

After release, run 65–67 immediately/as scheduled, then establish 68–73 with owners and cadence. Automate recurring tasks only after they run reliably by hand and use read-only defaults.

## 6. Recovery rules

- `blocked`: keep the same prompt, record the exact missing decision/access/evidence.
- `partial`: preserve useful work, list incomplete criteria, and retry the same prompt.
- gate failure: return to the smallest upstream prompt that owns the missing evidence.
- changed requirement: update traceability and invalidate downstream approvals affected by the change.
- changed SHA, digest, environment or visual baseline: re-run the relevant acceptance/review gate.
- process/catalog change: mark the pilot stale and revalidate before G03.
- existing application without lifecycle: use path-based `continue`; do not run
  greenfield `start` in the application and do not copy the boilerplate over it.
