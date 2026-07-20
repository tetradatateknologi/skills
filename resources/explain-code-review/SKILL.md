---
name: explain-code-review
description: >-
  Explain MR/PR code review feedback to the developer in Bahasa Indonesia.
  Combines diff context with human and AI review comments (including
  <!-- pranalyzer:pr-review -->). Drafts reply suggestions and fix guidance.
  Supports GitHub (gh) and GitLab (glab). Use when the user asks to explain
  review feedback, understand MR comments, jawab review, or invokes
  /explain-code-review.
user-invocable: true
---

# Explain Code Review

Jelaskan feedback review MR/PR kepada developer — **bukan** auto-fix. Gabungkan konteks perubahan kode dengan komentar review (manusia + AI), lalu output briefing Bahasa Indonesia dengan draft jawaban dan arah perbaikan.

Pair with `review-pr` (menghasilkan review AI) and `babysit` (menerapkan perbaikan otomatis setelah developer siap).

## When to Use

- "Jelaskan review MR ini"
- "Apa maksud komentar reviewer?"
- "Gimana jawab feedback PR #42?"
- "Explain code review untuk merge request ini"
- User shares PR/MR URL or number and wants to understand review feedback

## When Not to Use

- Menulis review baru — use `review-pr`
- Auto-fix CI, konflik, atau komentar — use `babysit`
- Review kode lokal tanpa MR/PR — use `code-review`
- Evaluasi hipotesis arsitektur tanpa MR — use `what-do-you-think`

## Posture

- **Advisor untuk developer** — jelaskan, jangan implement kecuali diminta
- Label semua jawaban balasan sebagai **draft** — bukan keputusan final
- Seluruh output wajib **Bahasa Indonesia**
- Never commit, push, or post replies without explicit user request

---

## Steps

### 1. Detect platform

Determine GitHub vs GitLab (in order):

1. URL the user gave (`github.com` → GitHub, `gitlab.com` → GitLab)
2. `git remote -v` — infer from host
3. Ask once if ambiguous

Set `CLI`: `gh` (GitHub) or `glab` (GitLab).

### 2. Resolve the MR/PR

Identify target from (in order):

1. MR/PR URL or number the user gave
2. Current branch:
   - GitHub: `gh pr view --json number,url,title,state,baseRefName,headRefName`
   - GitLab: `glab mr view -F json` (parse `iid`, `web_url`)
3. Ask once if none apply

Record `owner/repo` (GitHub) or namespace path (GitLab) when not in the URL.

### 3. Preflight

**GitHub:**

```bash
gh auth status
gh pr view <number> --json number,title,state,url,author,additions,deletions,changedFiles,headRefName,baseRefName
```

**GitLab:**

```bash
glab auth status
glab mr view <iid> -F json
```

Stop and report if CLI is not authenticated or MR/PR cannot be resolved.

**Large MR/PR threshold:** If `changedFiles > 10` or `additions + deletions > 500`, use staged diff fetching (step 4).

### 4. Fetch the change

Reuse diff strategy from `review-pr`:

- **File list first** on large MR/PR:
  - GitHub: `gh pr diff <number> --name-only`
  - GitLab: parse changed files from `glab mr view <iid> -F json`, or `glab mr diff <iid> --color=never`
- **Diff filtering** — skip lockfiles, binaries, generated assets (`*.gen.*`, `*.pb.go`, `.min.js`, compiled CSS).
- **Full diff** for small/medium MR/PR:
  - GitHub: `gh pr diff <number>`
  - GitLab: `glab mr diff <iid>`

Read referenced files locally when diff alone is insufficient. Limit reads to modified functions/blocks tied to review comments.

### 5. Fetch review feedback

Collect **unresolved** feedback first; include resolved only when the user asks.

| Source | GitHub (`gh`) | GitLab (`glab`) |
|--------|---------------|-----------------|
| Inline / diff comments | `gh api repos/{owner}/{repo}/pulls/{n}/comments` | `glab mr note list <iid> -F json --state unresolved --type diff` |
| General / review summary | `gh api repos/{owner}/{repo}/issues/{n}/comments` and `gh api repos/{owner}/{repo}/pulls/{n}/reviews` | `glab mr note list <iid> -F json --state unresolved --type general` |
| Unresolved fallback | filter comments where thread unresolved | `glab mr view <iid> --comments --unresolved -F json` |

**AI review filter:** Match comments/reviews whose body contains `<!-- pranalyzer:pr-review -->` (from `review-pr`).

**Human review:** All other unresolved inline and general comments from reviewers.

If `glab mr note list` fails (experimental), fall back to `glab mr view <iid> --comments --unresolved`.

Optional CI context:

```bash
gh pr checks <number>          # GitHub
glab ci status                 # GitLab — if relevant to review questions
```

### 6. Explain (core deliverable)

For each review item (AI + human), analyze and classify:

- **Pertanyaan** — reviewer butuh klarifikasi
- **Permintaan perubahan** — reviewer minta ubah kode
- **Nit / saran** — preferensi, non-blocker
- **Blocker** — must fix sebelum merge

Per item, determine:

1. **Konteks kode** — bagian diff/file yang disentuh
2. **Maksud reviewer** — apa yang mereka maksud dan mengapa
3. **Validitas** — `Valid` / `Perlu klarifikasi` / `Mungkin nit` / `Tidak setuju (dengan alasan)`
4. **Draft respons** — jika pertanyaan, tulis kalimat balasan draft
5. **Arah perbaikan** — jika permintaan perubahan valid, langkah konkret tanpa commit

Apply `code-review` lens when assessing validity: correctness, maintainability, performance, security, testing.

### 7. Format output

Use this template in chat:

```markdown
## Briefing Review — [judul MR/PR] ([#number/iid])

**Platform:** GitHub / GitLab · **Status:** open/merged · **Branch:** `head` → `base`

### Ringkasan perubahan
<2–4 kalimat: PR/MR ini ubah apa, scope utama, risiko singkat>

### Statistik feedback
- **Belum resolved:** N komentar (X manusia · Y AI)
- **Blocker:** N · **Perlu jawaban:** N · **Saran perbaikan:** N

---

### Item review

#### [1/N] [Pertanyaan | Permintaan perubahan | Nit | Blocker] — `path/to/file:line`

**Sumber:** @reviewer / AI review (`pranalyzer`) · **Lokasi:** `file:line`

**Komentar asli:**
> <quote singkat>

**Konteks kode:**
<jelaskan apa kode di area ini lakukan dan hubungannya dengan perubahan MR>

**Maksud reviewer:**
<parafrase plain language>

**Validitas:** Valid / Perlu klarifikasi / Mungkin nit / Tidak setuju

**Draft respons** *(jika pertanyaan):*
> <kalimat balasan draft — tandai sebagai saran, bukan final>

**Arah perbaikan** *(jika permintaan perubahan):*
1. <langkah konkret>
2. <opsi alternatif jika ada trade-off>

---

(Ulangi untuk setiap item. Prioritaskan blocker dan unresolved.)

### Prioritas tindakan

| Prioritas | Item | Tindakan |
|-----------|------|----------|
| 🔴 Blocker | ... | Fix / jawab |
| 🟠 Should fix | ... | Fix / diskusi |
| 🟡 Nit | ... | Opsional |

### Rekomendasi berikutnya
- **Implement sendiri** — terapkan arah perbaikan di atas
- **`babysit`** — jika ingin agent auto-fix CI dan komentar yang jelas
- **Balas reviewer** — copy draft respons (edit dulu), post hanya jika user minta
```

### 8. Handoff

End with:

> Briefing selesai. Mau **implement** perbaikan, **balas** reviewer (post draft), atau **`babysit`** untuk auto-fix?

Do not implement or post unless the user explicitly asks in a follow-up.

---

## Platform Reference

| Langkah | GitHub | GitLab |
|---------|--------|--------|
| Auth | `gh auth status` | `glab auth status` |
| Metadata | `gh pr view <n> --json ...` | `glab mr view <iid> -F json` |
| Diff | `gh pr diff <n>` | `glab mr diff <iid>` |
| Inline comments | `gh api .../pulls/{n}/comments` | `glab mr note list <iid> -F json --type diff` |
| General comments | `gh api .../issues/{n}/comments` | `glab mr note list <iid> -F json --type general` |
| Reviews | `gh api .../pulls/{n}/reviews` | discussions in `glab mr view --comments` |

Add `--repo owner/repo` (gh) or `-R namespace/project` (glab) when not in that repository's directory.

---

## Rules

- **Read-only by default** — explain, do not fix
- **Draft only** — never present reply text as final without user review
- **Unresolved first** — unless user asks for full history
- **No invented feedback** — if no comments exist, say so honestly
- **Bahasa Indonesia** for all output regardless of comment/code language
- **Never** approve, request changes, commit, push, or post without explicit request
- If a comment needs a design decision the codebase cannot answer, flag it and ask the user

## Related Skills

| Situation | Skill |
|-----------|-------|
| Generate AI review | `review-pr` |
| Auto-fix after briefing | `babysit` |
| Review criteria reference | `code-review` |
| Triage pentest / VA report (text input) | `explain-security-findings` |
| Evaluate approach before coding | `what-do-you-think` |
