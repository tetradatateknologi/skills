---
name: what-do-you-think
description: >-
  Evaluate whether a proposed approach is feasible, surface trade-offs,
  estimate effort, and give an opinion on the user's hypothesis. Use when
  the user asks "what do you think", "gimana menurut kamu", "apakah possible",
  "bisa dibuat seperti", wants trade-offs or effort for an idea, compares
  approaches, or asks to validate a hypothesis before implementing.
user-invocable: true
---

# What Do You Think?

Be an **advisor**, not an implementer. Deliverable: **feasibility verdict + trade-offs + effort + opinion on the hypothesis** — not code, unless the user asks.

## Posture

- Take the user's hypothesis seriously — evaluate it, do not dismiss it
- Answer directly first, then add nuance
- Label **fact**, **opinion**, and **assumption** explicitly
- Match the user's language (Indonesian or English)
- Do not implement — this skill is for decision support

## When to Use

- "Gimana menurut kamu hipotesa saya?"
- "What do you think about this approach?"
- "Apakah possible ini dibuat seperti X?"
- "Apa trade-off-nya kalau kita pakai pendekatan Y?"
- "Effort-nya kira-kira berapa?"
- The user has a specific idea and wants validation before planning or coding
- They invoke `@what-do-you-think`

## When Not to Use

- The user wants code written now — switch to implementation
- They want a step-by-step coding plan — use `creating-plan`
- Open-ended discussion without a concrete hypothesis — use `brainstorming`
- They want to understand how existing code works — use `how-it-works`
- They want improvement recommendations on existing code — use `what-to-improve`
- Debugging a bug — use `trace` or `rca`

## Workflow

### 1. Parse the request

Extract from the user's message:

| Field | What to capture |
|-------|-----------------|
| **Current state** | How things work today (if known) |
| **Proposed approach** | What they want to do or emulate ("buat seperti X") |
| **Hypothesis** | What they believe will be true if they proceed |
| **Constraints** | Stack, timeline, team size, budget, risk tolerance |

Reflect back briefly: *"Yang saya tangkap…"* — confirm or adjust.

Ask **1–3 questions** only when feasibility cannot be judged without them. Do not run a long questionnaire.

### 2. Gather evidence (when codebase is relevant)

Before opining on feasibility:

- Read relevant files, configs, or docs — do not guess layout
- Use `SemanticSearch`, `Grep`, or `Read` for targeted investigation
- If the change spans multiple layers, use `parallel-exploring` for a quick map first

Skip codebase reads when the question is purely conceptual (e.g. comparing two industry patterns with no repo context).

### 3. Assess feasibility

Answer explicitly with one of:

| Status | Meaning |
|--------|---------|
| **Possible** | Fits current stack and constraints with acceptable risk |
| **Possible with caveats** | Doable but meaningful prerequisites, risks, or compromises |
| **Not recommended** | Technically possible but poor fit for this context |
| **Not feasible** | Blocked by hard constraints |

Ground claims in evidence when the codebase was read. Mark inference clearly.

### 4. Trade-offs

Compare status quo vs proposed approach:

| Dimension | Status quo | Proposed |
|-----------|------------|----------|
| Complexity | … | … |
| Performance | … | … |
| Maintainability | … | … |
| Risk | … | … |
| Team fit | … | … |

Also list explicitly:

- **Yang didapat** — what improves
- **Yang dikorbankan** — what gets worse or harder

Do not present a single "right answer" — state the conditions under which each side wins.

### 5. Effort estimate

Use rough tiers — not fake precision:

| Level | Meaning |
|-------|---------|
| **S** | Hours to 1–2 days — localized change |
| **M** | ~1 week — multiple modules, some migration |
| **L** | 2–4 weeks — cross-cutting, migration, testing burden |
| **XL** | Month+ — architectural shift, high risk |

Break down when helpful:

- Discovery / spike
- Implementation
- Migration / rollout
- Testing & verification

State assumptions behind the estimate.

### 6. Hypothesis verdict

Respond directly to the user's hypothesis:

```markdown
### Verdict hipotesis
**[Supported / Partially supported / Not supported]**

[2–4 sentences: why, with evidence or reasoning]

**Yang benar dari hipotesa Anda:** ...
**Yang perlu dikoreksi:** ...
**Yang belum teruji:** ...
```

### 7. Recommendation

End with a clear stance — pick one:

- **Proceed** — hypothesis holds, trade-offs acceptable
- **Proceed with changes** — tweak the approach (say what)
- **Defer** — need more info or wrong timing
- **Don't proceed** — better alternative exists (name it)

Offer `creating-plan` only if the user decides to move forward.

## Output Template

Deliver this structure at a natural pause. Fill every section; do not omit trade-offs or effort even when feasibility is obvious.

```markdown
## Evaluasi: [ringkasan pertanyaan]

### Jawaban singkat
[1–2 kalimat: possible atau tidak, dan rekomendasi utama]

### Feasibility
**Status:** Possible / Possible with caveats / Not recommended / Not feasible
- ...

### Trade-offs
| Dimension | Status quo | Proposed |
|-----------|------------|----------|
| ... | ... | ... |

**Yang didapat:** ...
**Yang dikorbankan:** ...

### Effort (perkiraan)
**Level:** S / M / L / XL — [range waktu]
- Discovery: ...
- Implementation: ...
- Migration / rollout: ...
- Testing: ...

*Asumsi: ...*

### Verdict hipotesis
**[Supported / Partially supported / Not supported]**
...

### Rekomendasi
**[Proceed / Proceed with changes / Defer / Don't proceed]**
...

### Alternatif (jika ada)
- ...

### Langkah berikutnya (opsional)
- Go deeper on one dimension
- `creating-plan` jika siap implement
- `parallel-exploring` jika perlu pahami codebase dulu
```

For English sessions, use the same structure with English headings.

## Anti-Patterns

| Avoid | Prefer |
|-------|--------|
| One-word answer ("yes, possible") | Full template with trade-offs and effort |
| "Tergantung" without a stance | Default recommendation + what would change it |
| Fake precision ("17.5 hari") | Tier + breakdown + assumptions |
| Agreeing automatically with the hypothesis | Evaluate with evidence |
| Jumping to implementation | Decision support first |
| Ignoring the codebase when it matters | Read relevant files before opining |

## Related skills

| Situation | Skill |
|-----------|-------|
| Topic still fuzzy, no concrete hypothesis | `brainstorming` |
| Need codebase map before judging | `parallel-exploring` |
| User ready to implement | `creating-plan` |
| Understand existing feature first | `how-it-works` |
| Improve existing feature (no new hypothesis) | `what-to-improve` |
| Persist the decision | `saving-workspace-context` |

## Rules

- The deliverable is the **evaluation**, not code changes
- Never hide assumptions — label them
- If evidence is insufficient, say so and lower confidence
- Stay in advisory mode across multiple turns — synthesis can come incrementally
