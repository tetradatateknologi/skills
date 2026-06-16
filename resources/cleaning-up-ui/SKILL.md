---
name: cleaning-up-ui
description: >-
  Audit and fix messy existing UI — overflow, spacing, alignment, typography,
  and layout inconsistencies. Brings pages in line with common UI patterns.
  Use when the user says the UI is messy, cluttered, needs cleanup, or mentions
  overflow, layout issues, rapihkan, or berantakan.
user-invocable: true
---

# Cleaning Up UI

Fix existing UI that looks messy or unprofessional. Focus on layout integrity
first (especially overflow), then spacing and visual consistency.

## When to use

- User asks to clean up, tidy, or polish the UI
- Overflow, horizontal scroll, overlapping elements, or broken layout
- Inconsistent spacing, alignment, or typography on an existing page

Do **not** use for full redesigns or new feature UI — use `using-ui-stack` instead.

## Workflow

### 1. Audit

1. Ensure the dev server is running; open the target page in the browser
2. Take a full-page screenshot at **375px** and **1280px**
3. Check the console for layout-related errors
4. Read the relevant component and page files
5. Walk the **Overflow & layout checklist** below

### 2. Fix (priority order)

1. **Overflow & layout** — remove unintended scroll, clipping, overlap
2. **Spacing & alignment** — consistent padding, gaps, centering
3. **Typography & hierarchy** — heading scale, readable line length
4. **Interactive states** — hover, focus, disabled where missing
5. **Responsive** — stack/collapse patterns on small screens

Apply design tokens from `using-ui-stack` (8px grid, type scale, 5 states).

### 3. Verify

1. Re-screenshot affected viewports
2. Confirm no horizontal scroll at 375px
3. Report using the template in **Report format**

## Overflow & layout checklist

- [ ] No unintended horizontal scroll
- [ ] Long text handled (`truncate`, `break-words`, `line-clamp`)
- [ ] Flex children that shrink: `min-w-0` where needed
- [ ] Tables/lists: `overflow-x-auto` on wrapper only
- [ ] Images: `max-w-full h-auto`
- [ ] Page container: `max-w-* mx-auto` + responsive `px-*`
- [ ] Modals/dropdowns not clipped by parent `overflow-hidden`
- [ ] Fixed/sticky elements do not cover main content

## Common fixes

| Symptom | Likely fix |
|---------|------------|
| Page scrolls sideways | Find fixed widths; add `min-w-0`; wrap tables in `overflow-x-auto` |
| Text spills out of card | `break-words` or `truncate`; ensure card has bounded width |
| Cramped or uneven gaps | Normalize to `gap-4` / `gap-6`, `p-6` on cards |
| Content too wide on desktop | `max-w-7xl mx-auto px-4 md:px-6` |
| Buttons misaligned | `flex items-center gap-2` or a consistent grid |
| Sidebar breaks mobile | Collapse to drawer/hamburger — flag if out of polish scope |

## Report format

```markdown
## UI Cleanup Report

### Fixed
- [category] file/area — what changed

### Needs follow-up
- Items outside polish scope (e.g. new hamburger nav)

### Verified
- Viewports tested; overflow status
```

## Related skills

- `using-ui-stack` — design tokens when applying fixes
- `visual-qa-testing` — browser verification steps
- `responsive-testing` — full breakpoint pass after major layout fixes

## Notes

- Fix root causes — do not hide overflow with `overflow-x-hidden` on `body` without fixing the offending element
- Keep changes minimal; match existing project conventions
- Acknowledge what already looks good, not only what was broken
