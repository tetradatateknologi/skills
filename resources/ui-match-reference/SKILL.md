---
name: ui-match-reference
description: >-
  Implement or update frontend UI to match an attached reference image, mockup,
  or screenshot. Maps layout, spacing, typography, and components to the project's
  existing stack and design tokens. Use when the user attaches a design image,
  shares a reference URL, or asks to replicate, match, or implement UI from a
  visual reference (mockup, Figma export, competitor page, mirip gambar, sesuai desain).
user-invocable: true
---

# UI Match Reference

Implement UI that closely matches a visual reference — attached image, page URL,
or existing code the user points to. Prioritize what is **feasible** in the
project's stack over pixel-perfect cloning.

## When to use

- User attaches a screenshot, mockup, or design export
- User shares a reference URL and asks to match that UI
- User mentions existing code and wants it updated to match a reference
- User says: replicate, match, implement from design, mirip gambar, sesuai desain

## When not to use

- No visual reference — user only wants general UI polish → `ui-cleanup`
- User wants a plan before coding → `creating-plan`

## Reference inputs

| Input | How to use |
|-------|------------|
| **Attached image** | Primary source — read and analyze before writing code |
| **Page URL** | Open in browser; screenshot for full-page context and interactions |
| **Code mention** | Baseline to modify — extend existing components, don't rewrite unless asked |
| **Text notes** | Scope (which section), viewport (mobile/desktop), behavior beyond the image |

## Workflow

### 1. Analyze reference

Read the attached image (or browser screenshot of the URL) and extract:

- **Layout** — header, sidebar, grid, columns, card placement
- **Hierarchy** — titles, subtitles, body, metadata, CTAs
- **Spacing** — section padding, gaps (estimate in 4px/8px multiples)
- **Colors** — backgrounds, primary, borders, text (map to project tokens)
- **Typography** — relative sizes and weights
- **Components** — buttons, inputs, badges, tables, avatars, icons
- **Visible states** — default only, or hover/active shown in reference

Write a short mental spec before coding. If the reference is large, confirm scope
with the user or implement top-to-bottom in sections.

### 2. Map to project

1. Detect stack — framework, styling (Tailwind/CSS modules), UI library
2. Find reusable components (`Button`, `Card`, `Input`, layout shells)
3. Apply tokens from `using-ui-stack` — reuse project colors/fonts, don't invent new hex values
4. Identify target files from the user's URL route or code mention
5. Run **feasibility check** (below)

### 3. Implement

1. Compose from **existing components** before writing custom CSS
2. Use realistic mock data so spacing and truncation look correct
3. Match **structure and hierarchy** first, then spacing, then fine details
4. For large layouts, implement one section at a time (hero → content → sidebar)
5. Do not add new npm dependencies without flagging the user

### 4. Compare and iterate

1. Start dev server; open the target page
2. Screenshot the result at the same viewport as the reference
3. Walk the **match checklist** below; fix the most visible gaps first
4. Re-screenshot until structure and styling are acceptably close

### 5. Report

Use the template in **Report format**.

## Feasibility rules

**Implement fully when:**
- Standard layout (flex/grid, cards, forms, lists, tables)
- Styling with the project's existing tools (Tailwind, CSS, UI library)
- Components already exist or are simple compositions

**Approximate when:**
- Custom illustrations, complex charts, heavy animations
- Proprietary fonts — use the nearest project font
- Exact shadows/gradients — approximate with existing tokens
- Dynamic data — use placeholder content with correct structure

**Flag to user when out of scope:**
- Custom assets needed (logo, illustration) — use placeholder and note
- New library required (charts, 3D, rich text editor)
- Reference requires auth/login the agent cannot access
- Behavior not visible in a static image (animations, API-driven states)

## Match checklist

- [ ] Overall layout structure matches reference
- [ ] Section order and grouping correct
- [ ] Typography hierarchy (size, weight) roughly matches
- [ ] Spacing feels similar (padding, gaps, alignment)
- [ ] Colors mapped to project tokens, not random hex from screenshot
- [ ] Buttons, inputs, and cards use consistent project components
- [ ] Icons present where reference shows them (or noted as placeholder)
- [ ] Images use placeholders with correct aspect ratio when assets unavailable
- [ ] No unintended overflow or layout breakage (`ui-cleanup` fixes if needed)
- [ ] Viewport matches reference (mobile vs desktop)

## Report format

```markdown
## UI Match Report

### Reference analyzed
- Layout, key components, notable styling

### Implemented
- Files changed
- Components reused vs newly created

### Approximations
- What could not match 1:1 and why

### Needs follow-up
- Missing assets, new dependencies, auth-gated reference, larger scope

### Verified
- Viewport tested; screenshot compared to reference
```

## Notes

- Read the reference image **before** writing code — don't guess layout from the user's text alone
- Project conventions beat pixel-perfect cloning — match the reference within the design system
- If reference and existing code conflict, prefer the reference unless the user says otherwise
- Ask only when blocked: missing route/file, login wall, or ambiguous scope on a large page
