---
name: creating-qa-testcases
description: Create detailed manual QA test cases in JSON format from the active branch or PR changes using Indonesian for description.
user-invocable: true
---

# Creating QA Test Cases

Use this skill when the user wants to create detailed QA test cases based on the changes in their active Git branch or active Pull Request. This skill analyzes the code changes and outputs a structured JSON file containing detailed test scenarios written in Indonesian.

## Steps

1. **Detect active changes**:
   Identify the files changed in the active branch or active Pull Request compared to the base branch (typically `origin/main` or `main`).
   
   Run the following commands to inspect the branch name and code changes:
   ```bash
   # Get current branch name
   git branch --show-current

   # Get names of files changed in this branch relative to main
   git diff --name-only origin/main...HEAD
   ```
   
   If the changes are not yet pushed or there is no remote, compare with the local `main` branch or use the latest commits:
   ```bash
   git diff --name-only main...HEAD
   ```
   
   If there is a PR associated with the branch and GitHub CLI is available:
   ```bash
   gh pr diff
   ```

2. **Retrieve the diff content**:
   Fetch the actual code changes (diff) for the affected files to understand the modified logic, UI elements, API endpoints, or database structures:
   ```bash
   git diff origin/main...HEAD
   ```
   *Note: If the diff is extremely large, read it file-by-file or focus on the core logical files to avoid token limits.*

3. **Analyze the changes**:
   Analyze the diff to understand:
   - What features, bug fixes, or enhancements were introduced.
   - Which user interactions or API endpoints are affected.
   - Potential edge cases, validation rules, or error states introduced or modified.

4. **Generate QA test cases in JSON**:
   Draft highly detailed test cases in **Indonesian (Bahasa Indonesia)**.
   Ensure the following formatting rules are met:
   - **`task_code`**: Must be empty (`""`).
   - **`due_date`**: Must be empty (`""`).
   - **`status`**: Must be `"open"`.
   - **`priority`**: Must be determined by you (`"low"`, `"medium"`, or `"high"`) based on the complexity, severity, and business impact of the changes.
   - **`description`**: Must contain clear markdown headers:
     - `## Konteks`: Explaining what this test case covers.
     - `### Langkah reproduksi`: Step-by-step instructions on how to perform the test.
     - `### Ekspektasi`: The expected result of the test clearly defined.
     - `### Catatan`: Any additional notes (affected endpoints, browser/device requirements, etc.).
   
   Structure the JSON exactly as follows:
   ```json
   {
     "metadata": {
       "description": "Daftar skenario test case untuk QA berdasarkan perubahan branch aktif",
       "format_version": "2"
     },
     "tasks": [
       {
         "task_code": "",
         "title": "Title in Indonesian (e.g. 'Verifikasi validasi input pada Halaman Login')",
         "description": "## Konteks\n\nPenjelasan singkat konteks pengujian...\n\n### Langkah reproduksi\n- Langkah 1\n- Langkah 2\n\n### Ekspektasi\nHasil akhir yang diharapkan...\n\n### Catatan\nInformasi tambahan...",
         "status": "open",
         "priority": "high",
         "due_date": "",
         "labels": ["bug", "auth", "qa"],
         "checklist": [
           "Buka halaman login",
           "Masukkan username salah",
           "Verifikasi muncul pesan error"
         ]
       }
     ]
   }
   ```

5. **Write the output file**:
   Save the generated JSON content to `qa-testcases.json` in the root of the workspace. If the file already exists, ask the user whether to overwrite it or merge the test cases.

6. **Summarize your work**:
   Provide the user with a summary of the analyzed files, how many test cases were generated, their priorities, and confirm that the JSON has been written to `qa-testcases.json`.
