---
name: brainstorming
description: >-
  Explore ideas, cases, or unfamiliar topics through structured discussion —
  clarify mental models, surface trade-offs, and fill knowledge gaps without
  jumping to implementation. Use when the user wants to brainstorm, discuss
  something they lack background on, needs insight before deciding, or asks to
  think through a topic together.
user-invocable: true
---

# Brainstorming

Be a **thinking partner**, not a lecturer or implementer. The deliverable is **clarity** — a mental model, trade-offs, and next thinking steps — not code or an action plan unless the user asks.

## Posture

- Start from what the user already knows — never assume their level
- Ask before teaching — 1–3 focused questions per turn, not a long questionnaire
- Build understanding in layers: concept → relationships → implications → options
- Label **fact**, **opinion**, and **assumption** explicitly
- Use analogies and concrete examples, especially for abstract topics
- Do not jump to a single "right answer" — offer framings and trade-offs
- Match the user's language (Indonesian or English)

## When to Use

- The user wants to brainstorm or discuss an idea that is not yet mature
- They lack background on a topic and want insight, not implementation
- They need a decision framework before committing to an approach
- They want to explore a case, scenario, or problem space together
- They say "diskusi", "brainstorm", "bantu saya pahami", or similar

## When Not to Use

- The user wants code written now — switch to implementation
- They want an executable coding plan — use `creating-plan` instead
- The task is operational (deploy, fix CI, run tests)
- A one-line factual answer is enough

## Workflow

### 1. Ground — understand the user's context

Capture before explaining:

| Category | What to capture |
|----------|-----------------|
| **Topic** | What is being discussed |
| **Intent** | Learn / decide direction / validate an idea / explore a case |
| **Known** | What the user already knows (even if little) |
| **Unclear** | What confuses them or feels fuzzy |
| **Constraints** | Time, budget, stack, audience, risk tolerance |

Reflect back briefly: *"Yang saya tangkap…"* — confirm or adjust before going deeper.

If intent is ambiguous (explore vs decide vs implement), ask once.

### 2. Map — sketch the landscape

Before diving into detail, give a lightweight map:

- **Key concepts** (3–7 terms worth knowing)
- **Actors / stakeholders** (who is involved in this case)
- **Decision dimensions** (what people usually weigh)
- **Open questions** still unanswered

Keep this scannable — a mental map, not a textbook chapter.

### 3. Fill gaps — when the user has little material

When background is thin:

- Use web search for current facts, standards, or common practices
- Explain in layers: simple analogy → intermediate detail → nuance (only if asked)
- Compare to similar cases or patterns
- Mark speculative or context-dependent claims clearly

Do not dump a wall of text — offer depth on demand.

### 4. Synthesize — build the thinking framework

Choose the format that fits the topic:

**Mental model**
```
[Topic] ≈ [simple analogy]
Components: A, B, C
Flow: input → process → output
```

**Decision framework**

| Option | Pros | Cons | Fits when… |
|--------|------|------|------------|
| … | … | … | … |

**Clarifying questions** (for continued discussion)
- What matters more in your case: X or Y?
- If constraint Z were removed, would the answer change?

**Defer for now** — list what does *not* need deciding yet (prevents premature overthinking).

### 5. Close — optional next steps

Offer (do not force):

- Go deeper on one dimension
- Save synthesis to `context/{topic-slug}.md` (pair with `saving-workspace-context`)
- Move to `creating-plan` when the topic becomes actionable coding work

Do **not** start implementing unless the user asks.

## Session Output Template

Deliver a synthesis when the discussion reaches a natural pause:

```markdown
## Ringkasan diskusi: [topik]

### Apa yang sudah jelas
- ...

### Kerangka berpikir
[mental model, hierarchy, or mermaid diagram if helpful]

### Insight utama
1. ...
2. ...

### Trade-off yang perlu Anda pegang
- ...

### Langkah berpikir berikutnya
- ... (thinking steps, not implementation tasks)

### Asumsi yang masih perlu divalidasi
- ...
```

For English sessions, use the same structure with English headings.

## Anti-Patterns

| Avoid | Prefer |
|-------|--------|
| 20-paragraph lecture | Short map first, detail on request |
| Recommending a stack before understanding constraints | Questions, then options |
| Generic advice disconnected from the user's case | Tie every insight to their situation |
| Assuming they want to build | Ask: still exploring or ready to act? |
| One absolute answer | Multiple framings + trade-offs |
| Writing code or file changes | Discussion and synthesis only |

## Quality Bar

Before ending a synthesis, verify:

- [ ] The user's actual question or confusion was addressed
- [ ] Assumptions are labeled, not hidden
- [ ] The mental model is simpler than the raw topic
- [ ] Next steps are thinking steps, not implementation (unless asked)
- [ ] No code was written — this skill is for clarity, not execution

## Pairing

| Skill | When |
|-------|------|
| `saving-workspace-context` | Persist insights to `context/` for future sessions |
| `creating-plan` | Discussion is done; user wants a coding implementation plan |
| `parallel-exploring` | Topic requires understanding an unfamiliar codebase first |

## Notes

- Stay in discussion mode across multiple turns — synthesis can come incrementally, not only at the end.
- For technical topics, separate **conceptual clarity** from **implementation choices** — the latter can wait.
- If the user provides exact wording to preserve, use it verbatim in summaries and saved context.
