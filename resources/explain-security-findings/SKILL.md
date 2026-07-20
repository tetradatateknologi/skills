---
name: explain-security-findings
description: >-
  Explain and triage security testing report findings in Bahasa Indonesia.
  Input from pasted text or a text file — not GitHub/GitLab. Assesses each
  finding as valid, invalid, needs verification, or accepted risk. Drafts
  remediation guidance and pentester reply suggestions. Use when the user asks
  to explain pentest findings, triage vulnerability reports, validasi temuan
  keamanan, or invokes /explain-security-findings.
user-invocable: true
---

# Explain Security Findings

Jelaskan dan evaluasi temuan dari **laporan security testing** (pentest, VA scan, SAST/DAST) kepada developer — **bukan** auto-fix. Input dari teks yang di-paste atau file teks; verifikasi terhadap codebase lokal bila tersedia.

Pair with `auditing-security` (kriteria verifikasi di codebase), `how-it-works` (konteks fitur), and `babysit` (menerapkan perbaikan setelah developer siap).

## When to Use

- "Jelaskan temuan pentest ini"
- "Valid atau tidak finding ini?"
- "Triage laporan keamanan dari file ini"
- User pastes or attaches a security report and wants validity assessment
- User invokes `/explain-security-findings`

## When Not to Use

- Audit proaktif codebase tanpa report eksternal — use `auditing-security`
- Feedback review MR/PR dari GitHub/GitLab — use `explain-code-review`
- Auto-fix temuan — use `babysit` (setelah briefing)
- RCA insiden produksi — use `analyzing-root-cause`
- Evaluasi hipotesis arsitektur — use `what-do-you-think`

## Posture

- **Advisor untuk developer / security champion** — jelaskan, jangan implement kecuali diminta
- Label semua argumen balasan pentester sebagai **draft** — bukan keputusan final
- Seluruh output wajib **Bahasa Indonesia**
- Never commit, push, or send reports to third parties without explicit user request
- **Evidence-based** — setiap klaim validitas harus punya alasan dari report, kode, atau konfigurasi

---

## Steps

### 1. Intake report

Accept input from (in order):

1. **Pasted text** in chat
2. **File path** — read with `Read` tool (`.txt`, `.md`, `.csv`, `.json`, `.xml`, `.html` exports)
3. Ask once if neither is provided

Capture metadata when present:

| Field | Examples |
|-------|----------|
| **Report title** | "Web Application Pentest Q3 2026" |
| **Target** | URL, hostname, API base, environment (staging/prod) |
| **Scope** | In-scope / out-of-scope assets |
| **Tester / tool** | Manual pentest, Burp, OWASP ZAP, Nessus, Snyk, Semgrep |
| **Date** | Report date, retest date |
| **User goal** | Triage all / one finding / draft reply to pentester |

State assumptions when environment or scope is unclear.

### 2. Parse findings

Extract a normalized list — one row per finding. Handle varied formats (tables, numbered lists, XML/JSON exports).

| Field | Required | Notes |
|-------|----------|-------|
| **ID** | If present | Finding #, plugin ID, CVE |
| **Title** | Yes | Short name |
| **Severity** | If present | Critical / High / Medium / Low / Info |
| **Category** | If present | OWASP, CWE, CVSS |
| **Location** | If present | URL, endpoint, parameter, host, file path |
| **Description** | Yes | What the tester claims |
| **Evidence / PoC** | If present | Request/response, screenshot ref, steps |
| **Recommendation** | If present | Tester's suggested fix |

**Large reports:** If findings count > 15, summarize counts by severity first, then process in batches (Critical/High first). Ask user if they want full triage or priority-only.

**Duplicates:** Merge identical findings across hosts/parameters; note variants in one item.

### 3. Gather codebase context

Verify findings against the **local workspace** when relevant. Do not assume the report target matches production unless stated.

| Finding type | Where to look |
|--------------|---------------|
| Auth / session | Middleware, guards, cookie flags, JWT config |
| Injection (SQL/XSS/cmd) | Handlers, ORM queries, template rendering |
| Access control | Route policies, RBAC checks, object-level auth |
| Headers / TLS / CORS | Server config, reverse proxy, framework middleware |
| Secrets exposure | `.env`, config files, git history (if asked) |
| Dependency CVE | `package.json`, lockfiles, `go.mod`, etc. |
| Misconfiguration | Docker, nginx, cloud IaC in repo |

Use `Grep`, `Read`, and `how-it-works` patterns — limit reads to files tied to each finding.

If codebase is unavailable or finding is purely infrastructure outside the repo, say so and lower confidence.

### 4. Assess validity (core)

For each finding, classify:

| Status | Meaning |
|--------|---------|
| **Valid (TP)** | Vulnerability or misconfiguration is real in scope |
| **Invalid (FP)** | Not exploitable, wrong target, already mitigated, or scanner error |
| **Perlu verifikasi** | Plausible but needs manual repro, staging access, or more info |
| **Accepted risk** | Valid but consciously deferred — document why |
| **Informational** | Factual observation, not a vulnerability |

Also tag:

- **Severity disetujui** — agree / over-rated / under-rated (with reason)
- **Exploitability** — Tinggi / Sedang / Rendah / Tidak applicable
- **OWASP mapping** — when helpful (A01 Broken Access Control, etc.)

Apply `auditing-security` checklist when verifying in code. Consider:

- Is the affected asset in scope?
- Does PoC match actual behavior?
- Are compensating controls present (WAF, network segmentation)?
- Is this a known false positive for the stack (e.g. missing header on static CDN)?

### 5. Explain (deliverable)

Per finding, produce:

1. **Konteks** — apa yang dilaporkan dan di mana
2. **Maksud temuan** — plain language impact (confidentiality, integrity, availability)
3. **Bukti verifikasi** — apa yang ditemukan di kode/konfig (atau mengapa belum bisa diverifikasi)
4. **Validitas** — status dari tabel di atas
5. **Draft respons ke pentester** *(jika FP atau perlu klarifikasi)* — argumen sopan dengan bukti
6. **Arah perbaikan** *(jika Valid)* — langkah konkret tanpa commit

### 6. Format output

Use this template in chat:

```markdown
## Briefing Temuan Keamanan — [judul report]

**Sumber:** [pentest / VA scan / tool] · **Target:** [URL/env] · **Tanggal:** [jika ada]

### Ringkasan laporan
<2–4 kalimat: scope, jumlah temuan, tema utama>

### Statistik triage
- **Total temuan:** N
- **Valid (TP):** N · **Invalid (FP):** N · **Perlu verifikasi:** N · **Accepted risk / Info:** N
- **Prioritas:** Critical N · High N · Medium N · Low/Info N

---

### Item temuan

#### [1/N] [Valid | Invalid | Perlu verifikasi | Accepted risk | Informational] — [judul]

**Severity report:** Critical/High/... · **Severity disetujui:** ... · **Exploitability:** ...

**Lokasi:** `URL / endpoint / file` · **Kategori:** CWE-xxx / OWASP A0x

**Temuan asli:**
> <ringkasan dari report>

**Konteks & verifikasi:**
<apa yang dicek di codebase/konfig, hasilnya>

**Maksud temuan:**
<dampak nyata jika valid>

**Validitas:** Valid (TP) / Invalid (FP) / Perlu verifikasi / Accepted risk / Informational

**Alasan:**
<1–3 kalimat evidence-based>

**Draft respons ke pentester** *(jika FP atau perlu klarifikasi):*
> <kalimat draft — saran, bukan final>

**Arah perbaikan** *(jika Valid):*
1. <langkah konkret>
2. <opsi alternatif jika ada trade-off>

---

(Ulangi untuk setiap item. Prioritaskan Critical/High dan Valid.)

### Prioritas tindakan

| Prioritas | Temuan | Validitas | Tindakan |
|-----------|--------|-----------|----------|
| 🔴 P0 | ... | Valid | Fix segera |
| 🟠 P1 | ... | Valid / Perlu verifikasi | Fix / repro |
| 🟡 P2 | ... | Valid rendah / Info | Plan fix |
| ⚪ N/A | ... | FP | Tutup dengan bukti |

### Temuan yang perlu info tambahan
- ...

### Rekomendasi berikutnya
- **Implement sendiri** — terapkan arah perbaikan di atas
- **`babysit`** — auto-fix temuan yang sudah jelas
- **`creating-plan`** — jika perbaikan besar / lintas tim
- **Balas pentester** — copy draft respons (edit dulu), kirim hanya jika user minta
```

### 7. Handoff

End with:

> Briefing selesai. Mau **implement** perbaikan, **reproduksi manual** temuan yang belum pasti, **balas pentester** (draft), atau **`babysit`** untuk auto-fix?

Do not implement or send replies unless the user explicitly asks in a follow-up.

---

## Report Format Hints

Common patterns — adapt parsing, do not require a single format:

| Source | Typical structure |
|--------|-------------------|
| **Manual pentest** | Numbered findings, executive summary, appendices |
| **Burp Suite** | HTML/JSON export, issue name + URL + request/response |
| **OWASP ZAP** | Alert name, risk, URL, evidence |
| **Nessus / Qualys** | Plugin ID, CVE, host, solution text |
| **SAST (Semgrep, Sonar)** | Rule ID, file:line, snippet |
| **Dependency scan** | CVE, package, fixed version |

When structured export fails, treat each numbered section or table row as one finding.

---

## Rules

- **Read-only by default** — explain and triage, do not fix
- **Draft only** — never present pentester reply as final without user review
- **No invented findings** — if report is empty or unreadable, say so
- **Bahasa Indonesia** for all output regardless of report language
- **Never** mark FP without evidence — cite code, config, or missing preconditions
- **Never** downgrade Critical/High to FP without strong justification
- If a finding needs environment access you lack, classify **Perlu verifikasi** — do not guess
- Redact secrets from output; reference location without echoing credentials

## Related Skills

| Situation | Skill |
|-----------|-------|
| Proactive codebase security audit | `auditing-security` |
| Explain MR/PR review comments | `explain-code-review` |
| Auto-fix after briefing | `babysit` |
| Understand affected feature | `how-it-works` |
| Plan large remediation | `creating-plan` |
| Post-incident analysis | `analyzing-root-cause` |
