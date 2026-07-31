# Programmer-controlled lifecycle workflow

## Operating loop

For every task:

1. inspect `status`;
2. run `validate`;
3. prepare/read the current `NEXT_TASK.md`;
4. inspect the real application and previous prompt history;
5. execute exactly one prompt;
6. validate and perform an adversarial self-review;
7. record result, summary, evidence, and remaining implementation;
8. stop and wait for the programmer.

The programmer chooses `next`, `repeat`, `correct`, `skip and advance`, or a
specific prompt. No deterministic route authorizes a second prompt in the same
task.

## Existing applications and reruns

For brownfield work, keep the lifecycle outside the application. Do not modify
Git history, remotes, branches, or unrelated local changes.

Before a requested prompt:

- show its previous result, summary, evidence, and remaining work when it ran;
- when lifecycle history is absent, say that the existing implementation does
  not prove the prompt ran and identify likely overlap;
- require confirmation and a concrete rerun objective before changing files;
- preserve all previous attempts and evidence.

Useful objectives include fixing listed gaps, revalidating after product/code
changes, or replacing a previous decision. “Run it again” without a reason is
not enough.

## Stages and advisory gates

| Stage | Prompts/work | Quality checkpoint |
|---|---|---|
| Product definition | 01–04 | G01 product clarity and requirements |
| Architecture/foundation | 05–10 | G02 architecture and repository foundation |
| Design/surfaces | 11–18 | G03/G04 implementation and experience quality |
| Backend/functions | 19–37 | G05 complete user journeys |
| Security/public/hardening | 38–54 | G06 security and quality |
| Delivery/operations | 55–60 | G07 operational readiness |
| Acceptance/release | 61–64 | G08/G09 candidate, review, and authorization |
| Continuous operations | 65–73 | G10 measured operation and improvement |

During normal local development, G01–G08 and G10 are advisory: report missing
evidence and let the programmer decide whether to correct, repeat, or advance.
They never silently become `passed`.

G09 and the safety boundaries remain hard: external, destructive, financial,
Git, store, release, or production effects require the exact target and explicit
authorization. Production also requires an immutable candidate, smoke tests,
observability, and rollback.

The catalog pilot evaluates the process itself. A pending pilot does not block
an application from starting normal local implementation.

## Vertical slices and optional prompts

Prefer small complete vertical slices after the foundation. The programmer may
continue numerically or request the next useful page/feature prompt. A typical
slice remains:

```text
foundation when needed: 19 -> 20 -> 21 -> 22
page: 25 -> 13|15|17 -> 26
feature: 27 -> 13|15|17 -> 28
```

This is guidance, not an automatic route. Conditional prompts may be marked not
applicable or skipped with a recorded reason. They must not silently pretend to
be completed.

## Result and recovery rules

- `completed`: the prompt objective and criteria have proportionate evidence;
- `partial`: useful work exists, but specific implementation remains;
- `blocked`: a material dependency prevents safe completion;
- `not_applicable`: the scope does not apply and the reason is evidenced.

After any result, stop. `partial` and `blocked` do not trap the process: the
programmer may correct/repeat, or explicitly accept the gaps with `skip and
advance` plus a reason.

Routine requirement changes update the canonical development documents and
traceability. Formal change control is reserved for approved release baselines
or changes that affect a released system.

The legacy governed profile may still use task ledgers, findings gates,
deterministic selectors, human approvals, and pilot/stable gates. It is an
optional higher-assurance profile, not the default development process.
