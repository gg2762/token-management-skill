# Folder permission blocks (copy-paste)

Replace `<FOLDER>` with the absolute folder path (e.g. `/Users/you/myproject`).
**Merge** these into the target file's existing `permissions` object — do not overwrite. Then validate with `jq -e . <file>`.

Choose the file by scope: blanket trust → `<FOLDER>/.claude/settings.local.json` (gitignored). Team-safe rules → `<FOLDER>/.claude/settings.json` (committed).

---

## Read-only

```json
{
  "permissions": {
    "allow": [
      "Read(<FOLDER>/**)"
    ]
  }
}
```

## Standard (file edits + safe command families + deny-net)

```json
{
  "permissions": {
    "allow": [
      "Read(<FOLDER>/**)",
      "Edit(<FOLDER>/**)",
      "Write(<FOLDER>/**)",
      "Bash(git *)",
      "Bash(gh *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(node *)",
      "Bash(ls *)",
      "Bash(cat *)",
      "Bash(grep *)",
      "Bash(find *)"
    ],
    "deny": [
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git push --force-with-lease*)",
      "Bash(git reset --hard*)",
      "Bash(rm -rf *)",
      "Bash(rm -fr *)"
    ]
  }
}
```

## Full (zero friction in this folder + deny-net)

Put this in `<FOLDER>/.claude/settings.local.json` (gitignored), never the committed file.

```json
{
  "permissions": {
    "allow": [
      "Read(<FOLDER>/**)",
      "Edit(<FOLDER>/**)",
      "Write(<FOLDER>/**)",
      "Bash(*)"
    ],
    "deny": [
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git push --force-with-lease*)",
      "Bash(git reset --hard*)",
      "Bash(rm -rf *)",
      "Bash(rm -fr *)"
    ]
  }
}
```

---

## Subagents write directly (remove the worktree gate)

Top-level key (not inside `permissions`). Folder `.claude/settings.json`, or `~/.claude/settings.json` to apply everywhere:

```json
{
  "worktree": {
    "bgIsolation": "none"
  }
}
```

## Ensure `.env` and local settings are gitignored

Add to `<FOLDER>/.gitignore` if missing:

```
.env
.env.*
!.env.example
.claude/settings.local.json
```
