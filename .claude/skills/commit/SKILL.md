---
name: commit
description: Automatically create a git commit message based on current staged changes
allowed-tools: Bash(git status), Bash(git diff --staged)
---

# Instructions for Claude

Staged changes:
!`git diff --staged`

Analyze the staged changes above and generate a concise conventional commit message.

- If multiple changes exist, use dashes to list them.
- Do not capitalize the first character.
- Only output the commit message; do not explain it.
