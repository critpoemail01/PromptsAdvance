# Applying the quality gates

Read the lifecycle root `QUALITY_GATES.md` completely for any task that can create or approve architecture, UI, code, security posture, a release candidate, production, or operations.

Use this routing as an advisory quality checklist during normal development:

| Work | Required gate evidence |
|---|---|
| Product/requisites | G01 and `PRODUCT_DEFINITION.md` |
| Architecture/modules/contracts | G02, C4/ADRs, threat model and trade-offs |
| Initial project/design foundation | G03 evidence; catalog pilot is process QA, not an application blocker |
| Visible slice | G04 and `PRODUCT_QUALITY_BASELINE.md` |
| Business functionality | G05 end-to-end traceability |
| Security/compliance/hardening | G06 |
| CI/SLO/DR/runbooks | G07 |
| Acceptance/independent review | G08 |
| Production | G09 |
| Monitoring/improvement | G10 |

Professional UI requires both automation and judgment. Automated checks can prove deterministic behavior, accessibility rules and visual diffs; they cannot alone prove product fit, hierarchy or usability. Preserve human Product Design/UX approval for the first critical slice and release baseline.

Professional code means code appropriate to the repository and problem, not maximum abstraction. Require clear ownership and dependency direction, explicit contracts, cohesive names, small reviewable diffs, secure data/authorization boundaries, tests proportional to risk, observability, and recovery. Reject speculative frameworks, broad rewrites and patterns without a requirement.

Do not prevent `next` merely because routine evidence is incomplete. Report the
gap in the prompt result and let the programmer choose to correct, repeat, or
skip and advance. Release/production and external effects remain blocked until
their exact authorization and safety evidence exist.

For every `passed` decision, record:

- exact version/commit/surface;
- criterion;
- command, report, screenshot, trace or approved document;
- reviewer/approver when applicable;
- limitations and expiry condition.

Use `not verifiable` or `blocked` when the required environment, browser, assistive technology, data, reviewer or authorization is unavailable.
