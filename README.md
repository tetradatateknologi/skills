# Awesome AI Agent Skills

A collection of custom `SKILL.md` instruction files to automate software engineering workflows with AI agents like Cursor and Gemini (Antigravity).

## Installation

To install these skills, clone this repository and create symbolic links (`ln -s`) from the `resources` directory to your agent's configuration directory. This ensures the skills stay updated whenever you run `git pull`.

### 1. Clone the Repository

```bash
git clone https://github.com/tetradatateknologi/skills.git ~/skills
```

### 2. Symlink the Skills

#### For Cursor (Personal Skills)

```bash
mkdir -p ~/.cursor/skills
ln -sf ~/skills/resources/* ~/.cursor/skills/
```

#### For Gemini / Antigravity IDE

```bash
mkdir -p ~/.gemini/config/skills
ln -sf ~/skills/resources/* ~/.gemini/config/skills/
```

---

## Available Skills

Here is a list of the available workflows in this repository:

### Core Workflows
- [ship](resources/ship/SKILL.md) - User's "OK" to start implementation. Proceed without re-confirmation.
- [ship-isolated](resources/ship-isolated/SKILL.md) - Implement plan in an isolated git worktree, push, and create a PR.
- [creating-plan](resources/creating-plan/SKILL.md) - Turn a coding discussion into a detailed, executable implementation plan.
- [commit](resources/commit/SKILL.md) - Stage files and create commits with conventional commit messages.
- [push](resources/push/SKILL.md) - Commit local changes and push to remote.
- [creating-pr](resources/creating-pr/SKILL.md) - Create clean, review-ready pull requests.
- [review-pr](resources/review-pr/SKILL.md) - Perform a thorough pull request review and post summary comments.
- [explain-code-review](resources/explain-code-review/SKILL.md) - Explain MR/PR review feedback in Bahasa Indonesia with draft replies and fix guidance (GitHub + GitLab).
- [babysit](resources/babysit/SKILL.md) - Monitor an open PR for CI failures, reviews, and conflicts, fixing them automatically.

### Code Quality, Testing & Security
- [writing-tests](resources/writing-tests/SKILL.md) - Write comprehensive unit and integration tests.
- [creating-qa-testcases](resources/creating-qa-testcases/SKILL.md) - Create manual QA test cases in JSON format (descriptions in Indonesian).
- [adding-e2e-tests](resources/adding-e2e-tests/SKILL.md) - Set up Playwright end-to-end testing.
- [code-review](resources/code-review/SKILL.md) - Perform a code review focused on correctness, performance, and style.
- [auditing-security](resources/auditing-security/SKILL.md) - Audit codebase for OWASP Top 10 vulnerabilities and secrets exposure.
- [auditing-performance](resources/auditing-performance/SKILL.md) - Audit bundle size, rendering, database queries, and Core Web Vitals.

### Analysis & Troubleshooting
- [what-do-you-think](resources/what-do-you-think/SKILL.md) - Evaluate feasibility, trade-offs, and effort of a proposed approach.
- [brainstorming](resources/brainstorming/SKILL.md) - Explore ideas and trade-offs before jumping to implementation.
- [how-it-works](resources/how-it-works/SKILL.md) - Walk through how a named feature works in the codebase.
- [what-to-improve](resources/what-to-improve/SKILL.md) - Recommend improvements for an existing feature.
- [code-onboarding](resources/code-onboarding/SKILL.md) - Fast parallel onboarding to a new codebase.
- [tracing-bug](resources/tracing-bug/SKILL.md) - Trace bugs from symptoms to verified fixes.
- [analyzing-root-cause](resources/analyzing-root-cause/SKILL.md) - Investigate bugs and produce structured Root Cause Analyses (RCA).

### Tech Integrations
- [adding-auth](resources/adding-auth/SKILL.md) - Add NextAuth.js (Auth.js) authentication.
- [adding-midtrans](resources/adding-midtrans/SKILL.md) - Integrate Midtrans payment gateway for PHP/Go backends.
- [adding-docker](resources/adding-docker/SKILL.md) - Dockerize applications with multi-stage Dockerfiles.
- [adding-ci](resources/adding-ci/SKILL.md) - Add GitHub Actions CI (PR validation) pipelines.
- [adding-cd](resources/adding-cd/SKILL.md) - Setup a Zero-Downtime Docker-Compose deployment flow with GitHub Actions.
- [adding-api-docs](resources/adding-api-docs/SKILL.md) - Generate OpenAPI/Swagger documentation.
- [adding-seo](resources/adding-seo/SKILL.md) - Audit and implement technical SEO improvements.

### UI & Styling
- [ui-cleanup](resources/ui-cleanup/SKILL.md) - Fix messy frontend layouts, spacing, and typography.
- [ui-match-reference](resources/ui-match-reference/SKILL.md) - Match frontend UI to a mockup or design reference image.

### Utilities
- [creating-prompt](resources/creating-prompt/SKILL.md) - Design effective prompts for LLMs.
- [writing-copy](resources/writing-copy/SKILL.md) - Write landing page, CTA, and marketing copy.
- [saving-workspace-context](resources/saving-workspace-context/SKILL.md) - Persist research, decisions, and context to workspace files.
