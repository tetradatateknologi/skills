---
name: how-it-works
description: >-
  Walk through how a named feature works in the current codebase — entry
  points, data flow, key files, auth, and side effects. Use when the user asks
  how something works, "how it works", "how does X work", "bagaimana cara
  kerja", "jelaskan fitur", or wants a feature walkthrough before changing code.
user-invocable: true
---

# How It Works

Trace **how one named feature works** in the current codebase and deliver a structured walkthrough — read-only, evidence-based, no code changes unless the user asks.

For bugs in this feature, use `tracing-bug` after the walkthrough. For incidents, use `analyzing-root-cause`.

## When to Use

- The user asks how something works ("how does checkout work?", "bagaimana cara kerja checkout?")
- They say "how it works", "jelaskan fitur", "explain the flow", or "walk me through"
- They want to understand a flow before changing or debugging it
- They need a feature map: entry points, data flow, key files, side effects

## When Not to Use

- Something is broken and needs fixing → use `tracing-bug`
- They want root cause of an incident → use `analyzing-root-cause`
- They just cloned the repo and need a full overview → use `code-onboarding`
- They want a conceptual discussion without reading code → use `brainstorming`
- They want feasibility or trade-offs for a new idea → use `what-do-you-think`
- They want improvement recommendations → use `what-to-improve`
- A single file or function is enough → answer directly with Grep/Read

## Workflow

### 1. Intake the feature

From the user's message, capture what you can. Ask only for gaps that block investigation:

| Field | What to capture |
|-------|-----------------|
| **Feature name** | What they call it ("payment webhook", "user invite") |
| **Scope** | UI only, API only, or full stack (default: full stack) |
| **Perspective** | New dev onboarding, pre-refactor, security audit |
| **Output** | Chat only, or save to `docs/features/<slug>.md` |

If the feature name is ambiguous ("payment" could mean checkout, refund, or webhook), ask once to narrow scope.

### 2. Find entry points

Search from multiple angles — do not assume a single entry:

- **UI**: routes, pages, components, button handlers, hooks
- **API**: route handlers, GraphQL resolvers, tRPC procedures
- **Background**: cron jobs, queue workers, webhooks, event listeners
- **Data**: models, migrations, triggers, DB listeners

Use `SemanticSearch` and `Grep`, then read the files that look like true entry points.

### 3. Trace the flow

Follow the **happy path** first, then note important branches:

```
User action → Handler → Service / use case → DB or external API → Response / side effect
```

Rules while tracing:

- **Read-only** — do not edit code
- **Evidence-based** — every claim ties to a file and function; cite with `startLine:endLine:path`
- **Label inference** — mark anything not verified in code as "likely" or "inferred"
- **Depth on demand** — overview first; go deeper only where the user cares

### 4. Parallel investigation (cross-layer features)

When the feature spans frontend, backend, data, and async paths, launch parallel `explore` subagents (see `parallel-exploring`). Example prompts — replace `[FEATURE]` with the actual name:

**Agent 1 — Frontend**
> "Trace feature [FEATURE] in the frontend. Find UI entry points, components, state management, and API calls. Report file paths, function names, and the user-visible flow."

**Agent 2 — Backend**
> "Trace feature [FEATURE] in the backend. Find routes, controllers, services, validation, and middleware. Report endpoints, auth checks, and business logic locations."

**Agent 3 — Data**
> "Trace feature [FEATURE] in the data layer. Find models, tables, queries, migrations, and relationships touched. Report what is read vs written."

**Agent 4 — Async / integrations**
> "Trace feature [FEATURE] in background jobs, webhooks, queues, cron, and external service calls. Report triggers and side effects."

Synthesize agent results into one coherent narrative. For a small or single-layer feature, skip subagents — use Grep and Read directly.

### 5. Deliver the walkthrough

Use this template. Fill every section; write "None" or "Not found" when applicable — do not omit sections.

```markdown
# Feature: [name]

## Summary
[One paragraph — what the feature does in plain language]

## Entry points
| Layer | File | Symbol | Trigger |
|-------|------|--------|---------|
| ... | `path/to/file` | `FunctionName` | User clicks / webhook / cron |

## Main flow (happy path)
1. ...
2. ...

## Flow diagram
```mermaid
sequenceDiagram
  ...
```

## Key files
- `path/to/file` — role in this feature

## Data & side effects
- Tables/collections read or written
- Events published
- External services called

## Auth & permissions
[Who can use this? Which middleware or guards apply?]

## Edge cases & error handling
[Validation failures, retries, idempotency, fallbacks]

## Dependencies
[Other features or modules this feature relies on]

## How to verify manually
[Short steps to observe the flow in dev]

## Confidence
**High / Medium / Low** — [reason, especially if parts could not be traced]
```

Match the user's language (Indonesian or English) unless they ask otherwise.

### 6. Save (optional)

If the user wants persistence, write to `docs/features/<slug>.md` or use `saving-workspace-context` to store durable project knowledge.

## Related skills

| Situation | Skill |
|-----------|-------|
| Broad codebase unfamiliar | `parallel-exploring` |
| Full repo onboarding doc | `code-onboarding` |
| Bug in this feature | `tracing-bug` (after walkthrough) |
| Why something broke | `analyzing-root-cause` |
| Feasibility of a new idea | `what-do-you-think` |
| What to improve in this feature | `what-to-improve` |
| Persist findings | `saving-workspace-context` |

## Rules

- Explain the system **as it is** — not how it should be refactored (unless asked)
- Start from the **user journey**, not a random file
- Include a **mermaid diagram** when the flow has 3+ steps or crosses layers
- Never guess — if a path cannot be traced, say so and lower confidence
- The deliverable is the **walkthrough**, not code changes
