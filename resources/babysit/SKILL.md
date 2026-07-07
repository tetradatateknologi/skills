---
name: babysit
description: >-
  Monitor an MR/PR for CI failures, review comments, and merge conflicts — then
  fix them automatically. Supports GitHub (gh) and GitLab (glab). Reports in
  natural Bahasa Indonesia. Use when a PR/MR is open and you want the agent to
  keep it merge-ready.
---

# Babysit MR/PR

Pantau merge request / pull request, perbaiki CI yang gagal, tangani komentar review yang jelas, selesaikan konflik merge, dan laporkan hasilnya dalam Bahasa Indonesia yang natural — seperti update dari kolega, bukan status bot.

Pair with `explain-code-review` (briefing feedback sebelum fix) and `review-pr` (review AI).

## When to Use

- MR/PR terbuka dan perlu dibuat siap merge
- CI gagal setelah push
- Ada komentar review yang jelas dan bisa langsung diperbaiki
- Ada konflik merge dengan base branch

## When Not to Use

- Hanya mau pahami feedback review — use `explain-code-review`
- Review kode baru tanpa MR/PR — use `code-review` atau `review-pr`
- Keputusan desain / arsitektur belum jelas — use `what-do-you-think` dulu

## Posture

- **Implementer** — fix yang jelas, skip yang butuh keputusan desain
- **Laporan wajib Bahasa Indonesia**, naratif dan natural
- **Jangan** sebut nama skill, istilah internal agent, atau format changelog kaku di output user-facing
- **Jangan** post komentar ke MR/PR kecuali user minta eksplisit

---

## Steps

### 1. Detect platform

Tentukan GitHub vs GitLab (berurutan):

1. URL yang user berikan (`github.com` → GitHub, `gitlab.com` → GitLab)
2. `git remote -v` — infer dari host
3. Tanya sekali kalau masih ambigu

Set `CLI`: `gh` (GitHub) atau `glab` (GitLab).

### 2. Resolve MR/PR

Identifikasi target (berurutan):

1. URL atau nomor MR/PR dari user
2. Branch saat ini:
   - GitHub: `gh pr view --json number,url,title,state,baseRefName,headRefName`
   - GitLab: `glab mr view -F json` (parse `iid`, `web_url`, `target_branch`, `source_branch`)
3. Tanya sekali kalau tidak ketemu

Catat `owner/repo` (GitHub) atau namespace path (GitLab). Tambahkan `--repo owner/repo` (gh) atau `-R namespace/project` (glab) kalau tidak di direktori repo tersebut.

### 3. Preflight

**GitHub:**

```bash
gh auth status
gh pr view <number> --json number,title,state,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,baseRefName,headRefName
```

**GitLab:**

```bash
glab auth status
glab mr view <iid> -F json
```

Stop dan laporkan kalau CLI belum terautentikasi atau MR/PR tidak ditemukan.

Field konflik merge:
- GitHub: `mergeStateStatus`, `mergeable`
- GitLab: `merge_status`, `has_conflicts` di JSON MR

### 4. Check CI status

**GitHub:**

```bash
gh pr checks <number>
```

Lihat juga `statusCheckRollup` dari `gh pr view --json statusCheckRollup`.

**GitLab:**

```bash
glab ci status
glab ci view <source_branch>
```

Dari `glab mr view -F json`, cek status pipeline terkait MR. Identifikasi job yang `failed` atau `canceled`.

Tunggu kalau masih `pending` / `running` — jangan analisis kegagalan sebelum selesai.

### 5. Fix CI failures

Ambil log job yang gagal:

**GitHub:**

```bash
gh run view <run-id> --log-failed
```

**GitLab:**

```bash
glab ci view <source_branch>          # daftar job + ID
glab ci trace <job-id>                # log job gagal
```

Kalau perlu pipeline ID eksplisit: `glab ci list` lalu `glab ci get <pipeline-id>`.

Analisis dan perbaiki:

- **Lint**: `npm run lint -- --fix` (atau linter proyek), sisa error manual
- **Type errors**: `npx tsc --noEmit` atau type-check setara
- **Test failures**: jalankan suite yang gagal lokal, baca assertion
- **Build failures**: `npm run build` atau build command proyek

Jangan ubah workflow CI hanya supaya lolos. Jangan ubah assertion test kecuali perubahan behavior memang disengaja.

Setelah fix:

```bash
git add -A && git commit -m "fix: resolve CI failures" && git push
```

### 6. Handle review comments

Ambil komentar **belum resolved** dulu. Saat fetch GitHub, filter thread resolved; baca hanya body komentar dan lokasi minimum yang dibutuhkan — jangan baca seluruh payload JSON.

| Source | GitHub (`gh`) | GitLab (`glab`) |
|--------|---------------|-----------------|
| Inline / diff | `gh api repos/{owner}/{repo}/pulls/{n}/comments` | `glab mr note list <iid> -F json --state unresolved --type diff` |
| General / review | `gh api repos/{owner}/{repo}/issues/{n}/comments` + `gh api .../pulls/{n}/reviews` | `glab mr note list <iid> -F json --state unresolved --type general` |
| Fallback unresolved | filter thread belum resolved | `glab mr view <iid> --comments --unresolved -F json` |

**AI review** (Bugbot, `review-pr`): body berisi `<!-- pranalyzer:pr-review -->`. Validasi dulu — hanya fix yang memang valid.

Per komentar:
- Fix jelas (typo, naming, null check, style) → terapkan
- Butuh keputusan desain → skip, laporkan ke user, atau handoff ke `explain-code-review`

```bash
git add -A && git commit -m "fix: address review feedback" && git push
```

### 7. Resolve merge conflicts

Kalau ada konflik, gunakan base branch dari metadata MR/PR (bukan asumsikan `main`):

```bash
git fetch origin <base-branch>
git merge origin/<base-branch>
```

Selesaikan konflik dengan membaca kedua sisi. Kalau intent bentrok, abort merge dan tanya user.

```bash
git add -A && git commit -m "fix: resolve merge conflicts" && git push
```

### 8. Re-check status

**GitHub:**

```bash
gh pr checks <number> --watch
```

**GitLab:**

```bash
glab ci status
# ulangi glab ci view / trace kalau masih ada job gagal
```

Kalau masih gagal, kembali ke step 5. **Maksimal 3 siklus** fix → push → re-check.

### 9. Mark ready (opsional)

Kalau semua hijau dan MR/PR masih draft:

- GitHub: `gh pr ready <number>`
- GitLab: `glab mr update <iid> --ready`

### 10. Report

Laporkan ke user dalam **Bahasa Indonesia natural**. Lihat [Format laporan](#format-laporan-bahasa-indonesia).

Isi yang harus tercakup (dalam bentuk naratif, bukan checklist kaku):
- CI apa yang gagal dan bagaimana diperbaiki
- Komentar review mana yang sudah ditangani
- Apakah konflik merge sudah diselesaikan
- Status saat ini: siap merge, atau apa yang masih menghalangi

**Draft balasan reviewer** — hanya kalau user minta post ke MR/PR. Tandai sebagai draft; jangan post otomatis.

---

## Loop Behavior

```
Cek MR/PR → Temukan masalah → Perbaiki → Push → Cek ulang → Ulangi
```

Berhenti kalau:
- Semua check lolos, tidak ada komentar unresolved, tidak ada konflik → siap merge
- Sudah 3 siklus fix-push-check tanpa resolusi penuh → laporkan apa yang masih gagal
- Fix butuh keputusan desain → tanya user

---

## Format laporan (Bahasa Indonesia)

### Tone

Tulis seperti kolega senior memberi update singkat — sopan, jelas, tidak kaku.

**Lakukan:**
- Paragraf naratif; gabungkan poin terkait dalam satu alur
- Sebut perubahan dengan konteks (*mengapa* diubah, bukan cuma *apa*)
- Pisahkan hal yang sudah beres vs yang masih perlu diskusi
- Kalau minta re-approve, satu kalimat sopan di akhir

**Jangan:**
- Judul dengan nama skill ("Babysit update", "Merge-ready report")
- Section header changelog ("Perbaikan dari review sebelumnya", "Merge conflict terbaru")
- Bullet list teknis tanpa konteks yang terasa seperti dump commit
- Istilah internal: "babysit", "merge-ready", "status check rollup", "triaged"
- Emoji berlebihan atau format tabel prioritas kecuali user minta

### Contoh buruk

```
Babysit update — siap di-review ulang
Branch sudah di-merge dengan main terbaru dan CI hijau.

Perbaikan dari review sebelumnya (sudah di branch)
- Days tampering — backend menghitung ulang via validateAndNormalizeDays
- Write-on-read — GetLeaveBalance read-only
...
Mohon re-approve kalau sudah OK 🙏
```

### Contoh baik

```
Sudah saya bereskan poin-poin dari review sebelumnya.

Perhitungan hari cuti sekarang tidak lagi percaya nilai `days` dari client — backend hitung ulang lewat `validateAndNormalizeDays`. `GetLeaveBalance` juga sudah read-only; snapshot baru ditulis saat create/update/approve/reject. Validasi rentang cuti max 365 hari sudah ditambah di `duration_rules.go`.

Branch juga sudah saya merge dengan `main` terbaru (termasuk konflik di `config.go` dan `employee/repository.go`). Pipeline sudah lulus semua.

Yang mungkin masih perlu didiskusi terpisah: alerting kalau API hari libur down — endpoint sudah pindah ke api.co.id tapi monitoring belum ikut. Menurut saya bukan blocker merge.

Kalau sudah oke, boleh re-approve. Thanks!
```

### Template fleksibel (chat ke user)

Tidak wajib ikuti struktur kaku — sesuaikan situasi:

```markdown
[Satu kalimat konteks: MR/PR mana, kondisi umum]

[Paragraf: apa yang diperbaiki dari review/CI, dengan alasan singkat]

[Paragraf opsional: konflik merge yang diselesaikan]

[Paragraf opsional: yang belum bisa diselesaikan + kenapa butuh diskusi]

[Kalimat penutup: status merge / minta re-approve jika perlu]
```

### Draft balasan reviewer (hanya jika diminta)

Lebih singkat dari laporan ke user. Tanpa jargon internal. Contoh:

> Sudah di-update: perhitungan hari cuti sekarang di server, tidak lagi dari input client. Branch juga sudah di-merge dengan main terbaru dan pipeline hijau. Mohon re-review kalau sempat.

Post ke MR/PR **hanya** kalau user minta eksplisit.

---

## Platform Reference

| Langkah | GitHub (`gh`) | GitLab (`glab`) |
|---------|---------------|-----------------|
| Auth | `gh auth status` | `glab auth status` |
| Metadata | `gh pr view <n> --json ...` | `glab mr view <iid> -F json` |
| CI status | `gh pr checks <n>` | `glab ci status`, `glab ci view <branch>` |
| CI logs | `gh run view <run-id> --log-failed` | `glab ci trace <job-id>` |
| Inline comments | `gh api .../pulls/{n}/comments` | `glab mr note list <iid> -F json --type diff` |
| General comments | `gh api .../issues/{n}/comments` | `glab mr note list <iid> -F json --type general` |
| Reviews | `gh api .../pulls/{n}/reviews` | discussions di `glab mr view --comments` |
| Mark ready | `gh pr ready <n>` | `glab mr update <iid> --ready` |
| Diff | `gh pr diff <n>` | `glab mr diff <iid>` |

Kalau `glab mr note list` gagal (experimental), fallback ke `glab mr view <iid> --comments --unresolved`.

---

## Rules

- Never force-push ke branch MR/PR bersama
- Jangan ubah assertion test hanya supaya lolos kecuali behavior change disengaja
- Jangan resolve komentar yang tidak yakin — skip dan beritahu user
- Tunggu CI selesai sebelum analisis kegagalan
- Semua laporan ke user dalam Bahasa Indonesia natural
- Jangan post komentar ke MR/PR tanpa permintaan eksplisit
- Komentar butuh keputusan desain → handoff ke `explain-code-review` atau tanya user

## Related Skills

| Situation | Skill |
|-----------|-------|
| Briefing feedback review | `explain-code-review` |
| Generate AI review | `review-pr` |
| Review criteria | `code-review` |
| Evaluasi pendekatan | `what-do-you-think` |
