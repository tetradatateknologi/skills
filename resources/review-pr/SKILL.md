---
name: review-pr
description: >-
  Review a GitHub pull request and produce a single summary comment tagged
  <!-- pranalyzer:pr-review -->. Optionally post it to the PR via gh. Use when the user asks
  to review a PR, comment on a PR, post an AI review, or says "review pr",
  "komentar pr", or shares a PR URL/number.
user-invocable: true
---

# Review PR

Review an open pull request and deliver **one summary comment** (Option B — not inline line comments). Every posted comment must start with **`<!-- pranalyzer:pr-review -->`**.

Pair with `code-review` for review criteria. Do not fix code or push commits — that is `babysit`'s job.

## When to Use

- "Review PR #42 and post the comment"
- "Review this PR: https://github.com/org/repo/pull/123"
- "Kasih review AI ke PR ini"
- User shares a PR link or number and wants feedback on GitHub

## When Not to Use

- Review local uncommitted changes only — use `code-review` or `review-bugbot`
- Monitor/fix an open PR (CI, merge conflicts, addressing human comments) — use `babysit`
- Create a new PR — use `creating-pr`

## Steps

### 1. Resolve the PR

Identify the target from (in order):

1. PR URL or number the user gave
2. Current branch: `gh pr view --json number,url,title,state,baseRefName,headRefName`
3. Ask once if none of the above apply

Record `owner/repo` from `gh repo view --json nameWithOwner` when not in the URL.

### 2. Preflight

```bash
gh auth status
gh pr view <number> --json number,title,state,url,author,additions,deletions,changedFiles
```

Stop and report if:

- `gh` is not authenticated
- PR `state` is not `OPEN` (do not post to merged/closed PRs)
- User lacks permission to comment

*Pengecekan Ukuran (Threshold Check)*:
- Cek parameter `changedFiles`, `additions`, dan `deletions` dari PR. Jika `changedFiles > 10` atau `additions + deletions > 500`, tandai PR sebagai ukuran besar (Large PR) untuk menggunakan strategi pengambilan diff bertahap.

### 3. Fetch the change

- **Daftar Berkas Terubah**: Jika PR ditandai sebagai Large PR, jalankan `gh pr diff <number> --name-only` terlebih dahulu untuk memetakan berkas apa saja yang berubah.
- **Penyaringan Diff (Diff Filtering)**:
  - **Abaikan** berkas manifes dependensi (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `go.sum`, `Cargo.lock`, `composer.lock`), berkas biner/gambar, aset statis raksasa, dan kode hasil generator otomatis (`*.gen.*`, `*.pb.go`, `.min.js`, tailwind/css kompilasi).
  - Tarik diff penuh hanya untuk berkas kode logika utama yang relevan menggunakan perintah selektif atau jalankan `gh pr diff <number>` secara default jika ukuran PR kecil/sedang.
- **Pengambilan Informasi Tambahan**:
  ```bash
  gh pr checks <number>   # optional context — note failing checks in review
  ```
- Jika diff saja tidak cukup (misal untuk memahami dependensi simbol baru), baca berkas terkait secara terfokus. Batasi pembacaan hanya pada cakupan fungsi atau blok kode yang dimodifikasi.

### 4. Review

Apply `code-review` dimensions: correctness, maintainability, performance, type safety, testing.

Assess risk and categorize findings as follows:
- **Risk Score (0.0–10.0)**: Estimate the overall risk profile of the PR.
  - `🟢 Low Risk (0.0 - 3.9)`: Low impact, well-structured, negligible risks.
  - `🟡 Medium Risk (4.0 - 6.9)`: Moderate complexity, some concerns or edge cases to address.
  - `🔴 High Risk (7.0 - 10.0)`: Critical bugs, security vulnerabilities, or major architectural/data integrity risks.
- **Categorization**: Group findings into:
  - **Isu** (Bugs, logic errors, incorrect behaviors)
  - **Keamanan** (Security flaws, injection risk, credential leaks)
  - **Performa** (Inefficiencies, N+1 queries, unindexed queries)
  - **Logika** (Flawed assumptions, design mistakes, race conditions)
  - **OWASP Top 10** (Explicitly map findings to OWASP categories if relevant)
- **Severity Levels**: Assign to each finding:
  - `🔴 tinggi` (Must fix: blockers, bugs, security issues, data loss risk)
  - `🟠 sedang` (Should fix: major performance or maintainability issues)
  - `🟡 rendah` (Nit / Nice to have: minor enhancements, readability)
- **Fokus Berkas Pengujian**: Lakukan peninjauan berkas pengujian (`*_test.go`, `*.spec.ts`, dsb.) secara minimal/sekilas saja untuk memastikan ketersediaan tes, tanpa melakukan audit baris-per-baris secara mendalam guna menghemat token.
- Include `file:line` references when known.
- Acknowledge what is done well (1–2 bullets max) in the summary.
- Do not bikeshed formatter/linter issues.
- If nothing actionable: say so honestly — do not invent nits.

### 5. Format the summary comment

Use this template.

```markdown
<!-- pranalyzer:pr-review -->
## [EMOJI_WARNA] Tinjauan PR — risiko **[SKOR]/10**

@[username] — peninjauan kode otomatis di bawah ini. Harap tinjau sebelum menggabungkan (ini **bukan** persetujuan).

**Ringkasan.** <1–2 kalimat: ringkasan apa yang dilakukan PR ini, aspek positif, dan penjelasan ringkas mengenai tingkat risikonya>

**[JUMLAH_ISU]** isu · **[JUMLAH_KEAMANAN]** keamanan · **[JUMLAH_PERFORMA]** performa · **[JUMLAH_LOGIKA]** logika

> **Sebelum menggabungkan:**
> 1. <Tindakan perbaikan prioritas tinggi/sedang 1>
> 2. <Tindakan perbaikan prioritas tinggi/sedang 2>

### 🐞 Isu (<JUMLAH_ISU>)
- <warna_lingkaran> **<keparahan>** · **<Judul Temuan>** — `path/to/file.ext:line`<br><Deskripsi mendalam masalah><br>💡 <Saran perbaikan konkret>
(Jika tidak ada, tulis "Tidak ada.")

### 🔒 Keamanan (<JUMLAH_KEAMANAN>)
- <warna_lingkaran> **<keparahan>** · **<Judul Temuan>** — `path/to/file.ext:line` · _<Kategori OWASP jika ada>_<br><Deskripsi mendalam masalah><br>💡 <Saran perbaikan konkret>
(Jika tidak ada, tulis "Tidak ada.")

### ⚡ Performa (<JUMLAH_PERFORMA>)
- <warna_lingkaran> **<keparahan>** · **<Judul Temuan>** — `path/to/file.ext:line`<br><Deskripsi mendalam masalah><br>💡 <Saran perbaikan konkret>
(Jika tidak ada, tulis "Tidak ada.")

### 🧠 Logika (<JUMLAH_LOGIKA>)
- <warna_lingkaran> **<keparahan>** · **<Judul Temuan>** — `path/to/file.ext:line`<br><Deskripsi mendalam masalah><br>💡 <Saran perbaikan konkret>
(Jika tidak ada, tulis "Tidak ada.")

### 🛡️ OWASP Top 10
- **<Kategori OWASP>** — <Deskripsi ringkas hubungan temuan keamanan dengan OWASP Top 10>
(Jika tidak ada temuan terkait keamanan/OWASP, tulis "Tidak ada.")
```

Aturan pengisian template:
- `[EMOJI_WARNA]`: Gunakan 🟢 untuk risiko 0.0 - 3.9, 🟡 untuk risiko 4.0 - 6.9, dan 🔴 untuk risiko 7.0 - 10.0.
- `[SKOR]`: Skor risiko numerik dalam format satu angka di belakang koma (misal: `4.0`, `1.5`, `7.2`).
- `<warna_lingkaran>`: Gunakan 🔴 untuk tinggi, 🟠 untuk sedang, dan 🟡 untuk rendah.
- `<keparahan>`: Gunakan `tinggi`, `sedang`, atau `rendah` (dalam huruf kecil tebal).
- Pastikan teks deskripsi dan saran perbaikan ditulis secara mendalam namun ringkas.
- Seluruh teks keluaran wajib menggunakan **Bahasa Indonesia**.
- Pertahankan ukuran total komentar di bawah ~4000 karakter.

### 6. Show draft in chat

Always show the formatted comment in chat before posting. Include a compact table of findings (Severity | Location | Finding) for quick scanning.

### 7. Post to GitHub (when requested)

Post **only** when the user explicitly asks — e.g. "post", "upload", "kirim ke pr", "post the review". Review-only requests stop at step 6.

Post as a PR review comment (shows under Reviews):

```bash
gh pr review <number> --comment --body "$(cat <<'EOF'
<!-- pranalyzer:pr-review -->
## 🟢 Tinjauan PR — risiko **2.0/10**

@username — peninjauan kode otomatis di bawah ini...

EOF
)"
```

Add `--repo owner/repo` when not run from that repository's directory.

On success, reply with the PR URL and confirm the review was posted.

On failure, show the `gh` error and leave the draft in chat for manual copy-paste.

## Posting Rules

- **One summary comment per skill invocation** — no inline line comments, no comment spam
- **Never** post without explicit user request to post
- **Never** approve (`--approve`) or request changes (`--request-changes`) — comment only
- **Never** post to PRs you did not review in this session
- **Selalu gunakan Bahasa Indonesia** untuk seluruh isi komentar review, terlepas dari bahasa PR atau codebase

## Output When Not Posting

End with:

> Draft siap. Ketik **post** untuk mengunggah ini sebagai komentar review PR pada #\<number\>.

## Notes

- For deeper bug-focused scans, optionally run `review-bugbot` first, then merge findings into this summary format
- Inline comments require fragile line positions — out of scope for v1; use this summary-only skill instead
- If the user wants ongoing PR maintenance after posting, hand off to `babysit`
