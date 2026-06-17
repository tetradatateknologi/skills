---
name: analyzing-root-cause
description: >-
  Investigate a user-defined problem or bug and produce a structured root cause
  analysis with evidence, contributing factors, and recommended actions. Use when
  the user asks for RCA, rca, root cause analysis, why something broke,
  post-incident analysis, or wants to understand the cause before fixing.
user-invocable: true
---

# Analyzing Root Cause

Investigate a problem the user defines and deliver a **structured root cause analysis** — not a fix unless they ask for one.

## When to Use

- The user asks for RCA, root cause, or "why did this happen?"
- They describe a bug or incident and want analysis before fixing
- They need a blameless post-incident write-up from a defined problem
- Historical or intermittent issues where understanding matters more than a quick patch

## When Not to Use

- The user wants an immediate fix with no analysis → use `tracing-bug`
- A production incident is **still active** and needs mitigation first → use `incident-response`, then return here for RCA after stable
- The task is trivial (typo, one-line fix) → skip formal RCA

## Workflow

### 1. Intake the problem

From the user's description, capture what you can. Ask only for gaps that block investigation:

| Field | What to capture |
|-------|-----------------|
| **Symptoms** | What happened vs what was expected |
| **When** | Start time, duration, frequency (always / intermittent) |
| **Where** | Local, staging, production, CI |
| **Impact** | Who or what was affected |
| **Reproduction** | Steps to trigger, if known |
| **Recent changes** | Deploys, config, migrations, dependency updates |
| **Goal** | RCA only, or RCA then fix |

State assumptions explicitly when the user did not provide a detail and risk is low.

### 2. Classify and route

| Situation | Also use |
|-----------|----------|
| Active codebase bug | `tracing-bug` for investigation steps (reproduce → isolate → hypothesize → verify) |
| Live production outage | `incident-response` first — mitigate, then RCA |
| CI failures | `parallel-ci-triage` |
| Errors in dev server / terminal | `monitoring-terminal-errors` |
| Large or unfamiliar codebase | `parallel-exploring` |

Do **not** duplicate `tracing-bug` here — follow its process for steps 1–4 and **document evidence** as you go.

### 3. Investigate with evidence

- Never guess — every claim in the RCA must tie to logs, code, commits, configs, or reproduction
- Record hypotheses tested and whether they were confirmed or ruled out
- Build a timeline when timing matters
- If reproduction is impossible, say so and lower confidence; investigate from logs, git history, and code paths instead

### 4. Deliver the RCA report

Use this template. Fill every section; write "None identified" or "Unknown" when applicable — do not omit sections.

```markdown
# Root Cause Analysis: [title]

## Problem statement
[One paragraph from the user's report]

## Impact
[Users, systems, duration, severity]

## Timeline
- [time] — [event]

## Investigation summary
[What was checked and what evidence was found]

## Hypotheses tested
| Hypothesis | Result | Evidence |
|------------|--------|----------|
| ... | Confirmed / Ruled out | ... |

## Root cause
[Direct cause — specific: file, function, commit, config, or process gap]

## Contributing factors
[Conditions that allowed the root cause to occur or go undetected]

## Why it wasn't caught earlier
[Testing, review, monitoring, or process gaps]

## Recommended actions
| Action | Type | Priority |
|--------|------|----------|
| ... | fix / preventive / monitoring | P0 / P1 / P2 |

## Confidence level
**High / Medium / Low** — [reason, especially if Low or reproduction was not possible]
```

### 5. After the RCA

- **RCA only** — stop after the report unless the user asks to proceed
- **RCA then fix** — ask once: "Proceed with fix?" If yes, switch to `tracing-bug` (steps 5: fix and verify)
- **Save** — if the user wants it persisted, offer `docs/rca/[slug].md` or `postmortems/[date]-[slug].md`

## Rules

- The deliverable is the **RCA report**, not code changes
- Fix the root cause in analysis, not symptoms — distinguish proximate cause from underlying cause
- Blameless tone — focus on systems and process, not individuals
- Document what you tried so failed approaches are not repeated
- If stuck after 15 minutes, step back, re-isolate, or ask the user for missing context
