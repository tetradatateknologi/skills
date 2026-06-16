---
name: creating-plan
description: >-
  Synthesize the current conversation into a detailed, executable coding
  implementation plan for new features or bug fixes. Ask clarifying questions
  only when requirements, scope, or trade-offs are unclear. Use when the user
  asks for an implementation plan, wants to plan work from a discussion, or
  says they are ready to plan next steps before coding.
user-invocable: true
---

# Planning From Conversation

Turn a coding discussion into a detailed implementation plan — without writing code yet. Use for **new features** and **bug fixes**.

## When to Use

- The user asks for an implementation plan, roadmap, or "plan dulu sebelum coding"
- A feature or bug has been discussed and the next step is planning, not implementing
- The user wants a handoff document for a future session or another agent

## When Not to Use

- The user wants code written now — switch to implementation
- The request is non-coding (marketing, docs-only, ops) — adapt or skip this skill
- The task is trivial (one-line fix, rename) — a short answer is enough

## Workflow

### 1. Extract context from the conversation

Read the chat and note:

| Category | What to capture |
|----------|-----------------|
| **Goal** | What should work when done |
| **Type** | New feature or bug fix |
| **Decisions** | Approaches already agreed on |
| **Constraints** | Stack, patterns, files not to touch, deadlines |
| **Out of scope** | What was explicitly excluded |

If the codebase is relevant, skim key files (entry points, related modules) so the plan names real paths — don't guess file layout.

### 2. Clarify only when unclear

Ask questions **only** when missing information would block an executable plan. Do not grill for completeness.

**Ask when:**
- Scope is ambiguous (which endpoints, which UI screens, which edge cases)
- Expected behavior conflicts between messages
- Multiple valid approaches exist and the user hasn't picked one
- Bug reproduction steps or "done" criteria are missing

**Do not ask when:**
- The conversation already answers it
- A reasonable default exists and risk is low — state the assumption in the plan instead
- The detail is implementation trivia the executor can decide later

Group questions in one message. Prefer multiple-choice when it speeds decisions.

### 3. Write the plan

Produce a structured plan the user or a future agent can execute step by step. Use the template below.

**For features:** phases from foundation → core logic → UI/API → tests → polish.

**For bugs:** reproduce → root cause → fix → regression test → verify.

Keep file paths and function names specific when known from the codebase. Mark unknowns as `TBD — explore <area>`.

### 4. Offer to save (optional)

Ask whether to save the plan to `plans/{slug}.md`. If yes, write it there. Otherwise deliver in chat only.

Do **not** start implementing unless the user asks.

## Plan Template

```markdown
# [Feature / Bug title]

## Summary
[1–2 sentences: what and why]

## Type
- [ ] New feature
- [ ] Bug fix

## Context from conversation
- **Decisions:** ...
- **Constraints:** ...
- **Assumptions:** ... (only if you inferred without asking)

## Scope
### In scope
- ...

### Out of scope
- ...

## Implementation steps

### Phase 1: [name]
**Goal:** ...

| # | Task | Files / area | Notes |
|---|------|--------------|-------|
| 1 | ... | `src/...` | ... |

**Done when:**
- [ ] ...

### Phase 2: ...

## Dependencies & order
- Step X before Y because ...

## Risks
| Risk | Mitigation |
|------|------------|
| ... | ... |

## Test plan
- [ ] Unit: ...
- [ ] Manual: ...
- [ ] Regression (bugs only): ...

## Open questions
- ... (empty if none)

## How to execute later
> Invoke **`ship-the-plan`** when ready to implement — that is the go-ahead (replaces typing "oke gaskan" or similar).
```

## Quality bar

Before delivering, verify:

- [ ] Every step is actionable (verb + target), not vague ("improve auth")
- [ ] Scope matches what the user actually asked for
- [ ] Assumptions are labeled, not hidden
- [ ] Test plan matches the change type
- [ ] No code was written — this skill outputs the plan only

## Notes

- Match the user's language (Indonesian or English) in the plan body.
- For large features, detail Phase 1 deeply; later phases can stay higher-level.
- Pair with `parallel-exploring` if the codebase area is unfamiliar before planning.
- After approval, invoke `ship-the-plan` to implement.
