---
name: what-to-improve
description: >-
  Review how an existing feature works and recommend prioritized improvements
  — maintainability, performance, security, testability, and architecture.
  Use after how-it-works or when the user asks what can be improved, "apa yang
  bisa di improve", "saran perbaikan", or "menurut kamu apa yang kurang".
user-invocable: true
---

# What to Improve

Be an **advisor**, not an implementer. Deliverable: **prioritized improvement recommendations grounded in how the feature actually works** — not code changes, unless the user asks.

Pair with `how-it-works`: understand first, then improve. If no walkthrough exists yet, run `how-it-works` (or a shortened trace) before recommending.

## Posture

- Ground every recommendation in **evidence from the codebase** — cite files with `startLine:endLine:path`
- Label **fact**, **opinion**, and **assumption** explicitly
- Prioritize by **impact vs effort** — not everything needs fixing
- Say what is **fine as-is** — avoid refactor for refactor's sake
- Match the user's language (Indonesian or English)
- Do not implement — decision support first

## When to Use

- "Dari cara kerja tersebut, apa yang bisa di improve?"
- "Apa yang bisa diperbaiki menurut kamu?"
- "Saran perbaikan untuk fitur X"
- "What can be improved in this flow?"
- After `how-it-works` when the user wants recommendations
- Pre-refactor audit of an existing feature

## When Not to Use

- They only want to understand how it works — use `how-it-works`
- Something is broken — use `tracing-bug` or `analyzing-root-cause`
- They have a **new idea** to validate — use `what-do-you-think`
- They want a line-by-line review of a **diff** — use `code-review`
- Single-dimension audit only — use `auditing-security` or `auditing-performance`
- They want an implementation plan now — use `creating-plan`
- They want code written now — switch to `ship`

## Workflow

### 1. Intake

Extract from the user's message:

| Field | What to capture |
|-------|-----------------|
| **Feature / area** | What to review ("checkout", "auth middleware") |
| **Prior walkthrough** | Existing `how-it-works` output in chat, or none |
| **Focus** | All dimensions, or one (perf, security, tests, DX) |
| **Constraints** | No breaking changes, small team, deadline pressure |
| **Output** | Chat only, or save to `docs/improvements/<slug>.md` |

If the feature is ambiguous, ask once. If no walkthrough exists and the feature is non-trivial, establish how it works before recommending (follow `how-it-works` steps 2–3).

### 2. Establish baseline (if needed)

When the current behavior is not already clear:

1. Trace entry points and main flow (see `how-it-works`)
2. Note key files, data paths, and side effects
3. Keep this section brief in the final output — the user asked for improvements, not a full walkthrough

Reuse a prior `how-it-works` walkthrough from the same conversation when available.

### 3. Evaluate dimensions

Review the feature against these lenses. Skip dimensions that do not apply; say "N/A" when skipped.

| Dimension | Look for |
|-----------|----------|
| **Correctness & edge cases** | Missing validation, race conditions, error paths, idempotency |
| **Maintainability** | God functions, duplication, unclear naming, tight coupling |
| **Performance** | N+1 queries, waterfalls, missing indexes, heavy renders |
| **Security** | Auth gaps, injection, exposed secrets, missing rate limits |
| **Testability** | Untested paths, hard-to-mock dependencies, missing integration tests |
| **Observability** | Missing logs, metrics, or error context for failures |
| **DX & operations** | Config sprawl, manual steps, fragile deploy/migration path |

Use `auditing-security` or `auditing-performance` checklists when a dimension needs depth — do not duplicate full audits here.

### 4. Prioritize recommendations

For each finding, assign:

| Priority | Meaning |
|----------|---------|
| **P0** | Fix soon — correctness, security, or data risk |
| **P1** | Worth doing — meaningful maintainability or perf gain |
| **P2** | Nice to have — polish, minor DX |
| **Skip** | Not worth the churn right now — say why |

Effort tiers (same as `what-do-you-think`):

| Level | Meaning |
|-------|---------|
| **S** | Hours to 1–2 days |
| **M** | ~1 week |
| **L** | 2–4 weeks |
| **XL** | Month+ / architectural |

### 5. Deliver the report

Use this template. Fill every section; write "None" when nothing applies.

```markdown
# What to Improve: [feature name]

## Baseline (brief)
[2–4 sentences: how the feature works today — or "See prior how-it-works walkthrough"]

## Executive summary
[Top 1–3 recommendations in plain language]

## Recommendations

| Priority | Area | Issue | Recommendation | Effort | Evidence |
|----------|------|-------|----------------|--------|----------|
| P0 | Security | ... | ... | S | `path:line` |
| P1 | Performance | ... | ... | M | `path:line` |

## By dimension

### Correctness & edge cases
- ...

### Maintainability
- ...

### Performance
- ...

### Security
- ...

### Testability
- ...

### Observability
- ...

### What's fine as-is
[Explicitly call out parts that do not need change — builds trust]

## Quick wins (≤ S effort)
1. ...

## Larger bets (M+ effort)
1. ...

## Trade-offs to consider
[What you give up if you pursue the top recommendations]

## Suggested order
1. ... → 2. ... → 3. ...

## Confidence
**High / Medium / Low** — [reason if codebase was only partially read]
```

Match the user's language unless they ask otherwise.

### 6. After the report

- **Recommendations only** — stop unless the user asks to proceed
- **Validate a big idea** — offer `what-do-you-think` for a specific proposed change
- **Ready to implement** — offer `creating-plan`, then `ship`
- **Save** — write to `docs/improvements/<slug>.md` or use `saving-workspace-context`

## Anti-Patterns

| Avoid | Prefer |
|-------|--------|
| Generic best practices with no file references | Evidence from this codebase |
| "Refactor everything" | Prioritized list with effort and skip items |
| Re-explaining the entire feature | Brief baseline + link to prior walkthrough |
| Implementing without being asked | Advisory report first |
| Duplicating `code-review` on unchanged code style nitpicks | Feature-level structural improvements |

## Related skills

| Situation | Skill |
|-----------|-------|
| Understand the feature first | `how-it-works` |
| Validate a specific new approach | `what-do-you-think` |
| Deep security or perf only | `auditing-security`, `auditing-performance` |
| Review a PR diff | `code-review` |
| Plan the work | `creating-plan` |
| Implement | `ship` |
| Persist findings | `saving-workspace-context` |

## Rules

- The deliverable is the **improvement report**, not code changes
- Every P0/P1 item must cite evidence or be labeled as assumption
- Distinguish **bugs** (use `tracing-bug`) from **improvement opportunities**
- If the feature is already in good shape, say so clearly
- Offer `creating-plan` only when the user decides to move forward
