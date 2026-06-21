---
name: ship-isolated
description: >-
  Implement the agreed plan in an isolated git worktree, push the branch, and create a Pull Request on GitHub, keeping the user's active workspace completely untouched.
user-invocable: true
---

# Ship Isolated

Use this skill when you want to execute code changes and create a Pull Request on GitHub without polluting or modifying the user's active/unstaged files in the main workspace directory. This is especially useful for background tasks or when the user has ongoing work in their current branch.

## Prerequisites

- **Git**: Installed and initialized in the repository.
- **GitHub CLI (`gh`)**: Installed and authenticated (`gh auth status` must succeed).

## Workflow

### 1. Identify Target and Setup
- Determine the base branch (usually `main`, `master`, or the user's current branch) and target branch name (e.g. `feat/my-feature`).
- Decide on a temporary directory name under `.git-worktrees/` in the workspace root (e.g., `.git-worktrees/feat-my-feature`).
- Ensure `.git-worktrees/` is added to the local `.gitignore` so temporary files are not tracked.
  ```bash
  # Check if .gitignore contains .git-worktrees/
  grep -q "^.git-worktrees/" .gitignore || echo ".git-worktrees/" >> .gitignore
  ```

### 2. Create the Git Worktree
- Add the worktree pointing to a new branch:
  ```bash
  git worktree add -b <new-branch> .git-worktrees/<branch-folder> origin/<base-branch>
  ```
- *Note:* If the branch already exists remotely, adjust accordingly.

### 3. Share/Symlink Dependencies (Critical)
- To avoid running a slow dependency install, symlink the existing dependencies from the workspace root into the worktree directory if possible.
- **For Node.js (npm/yarn/pnpm)**:
  ```bash
  ln -s ../../node_modules .git-worktrees/<branch-folder>/node_modules
  ```
- **For Python/virtualenvs**:
  Configure the python executable in the worktree to point to the root virtual environment (e.g. `../../.venv`).
- **For other ecosystems**: Setup similar symlinks or configurations.

### 4. Implement Changes in the Worktree
- Modify files **only** under the `.git-worktrees/<branch-folder>/` path.
  - **CRITICAL**: Use the absolute path or path relative to the workspace root starting with `.git-worktrees/<branch-folder>/` for all file writes/edits (e.g., `.git-worktrees/feat-my-feature/src/index.js`).
  - Do NOT modify files directly in the root workspace (e.g., `src/index.js`).
- Run any commands (compilation, linting, tests) using `.git-worktrees/<branch-folder>/` as the current working directory (`Cwd`).

### 5. Verify the Implementation
- Inside `.git-worktrees/<branch-folder>/`, run test and verification commands to ensure the build and tests pass:
  ```bash
  # Example: Run lint and tests
  npm run lint
  npm test
  ```

### 6. Commit, Push, and Create PR
- Once verified, stage, commit, and push the changes from the worktree:
  ```bash
  cd .git-worktrees/<branch-folder>
  git add .
  git commit -m "<type>: <short description>"
  git push -u origin <new-branch>
  ```
- Create the Pull Request using GitHub CLI (`gh`):
  ```bash
  gh pr create --title "<title>" --body "<description>"
  ```
  *(Follow standard PR description templates with Summary, Changes, and Test Plan)*

### 7. Clean Up (Always Execute)
- Remove the git worktree and clean up the directory to free space and keep the repository clean:
  ```bash
  # From root directory
  git worktree remove --force .git-worktrees/<branch-folder>
  ```

## Error Handling
- If any step fails (e.g., test failures, build errors), stop and report to the user.
- Always run the **Clean Up** step even if the implementation or PR creation fails, to avoid leaving orphaned worktrees.
