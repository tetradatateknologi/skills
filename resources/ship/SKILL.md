---
name: ship
description: >-
  User's "OK" to start implementation. Invoking this skill means proceed with
  the agreed plan or discussion — no re-confirmation. Use after creating-plan
  or when the user is ready to code.
user-invocable: true
---

# Ship

**Invoke this skill = "OK, go."** Do not ask "are you sure?" — start implementing.

## Steps

1. **Lock scope** from the conversation, latest plan in chat, or `plans/*.md`. Do not expand scope.

2. **Implement** — execute agreed work phase by phase. Ask only on real blockers (wrong assumption, destructive action, missing secrets).

3. **Verify** — run relevant tests, lint, or type-check.

4. **Summarize** — what was done, files touched, check results, anything left open.

## Notes

- Pair with `creating-plan` to plan first, then ship.
- "Ship" means implement and verify — not open a PR unless asked.
