---
name: permission-setup
description: Use when Claude Code keeps prompting you to approve the same tools, when subagents prompt on every file write, when you're tempted to run --dangerously-skip-permissions just to stop the prompts, or when setting up trust across multiple project folders. Also covers credential hygiene — secrets leaking into settings files.
---

# Permission Setup

A meta-skill for **calibrated trust**. The goal is not "approve everything" — it's letting the agent work freely where it's safe while keeping a hard floor under the dangerous stuff.

Most people live at one of two bad extremes:
- **Death by prompts** — you press "yes" all day, especially once you run parallel subagents. Friction so high you stop using the agent well.
- **The reckless bypass** — fed up, you launch with `--dangerously-skip-permissions` (a.k.a. "dangerous mode"). Now *nothing* is checked — a stray `rm -rf` or force-push has no guardrail. You traded all friction for all risk.

This skill finds the middle: per-folder trust you choose deliberately, always paired with a deny safety-net that holds even at full trust. Set it up early; it's also a retrofit when the prompts are already driving you up the wall.

## Why you get prompted (the model)

A prompt fires when an action isn't pre-approved. Three independent causes — diagnose which one:

| Cause | Symptom | Fix |
|---|---|---|
| **Allow-list miss** | A command/tool isn't in any `allow` rule | Add a rule (a tool family, or blanket `Bash(*)` for a trusted folder) |
| **No file access** | Edit/Write to the folder prompts | `Read/Edit/Write(<folder>/**)` allow rule |
| **Worktree isolation gate** | *Subagents* prompt writing to the main checkout, even though the path is allowed | `worktree.bgIsolation: "none"` |

The isolation gate is separate from the allow-list — an allowed path can still prompt a subagent. People miss this constantly.

## Permission layers (precedence)

`~/.claude/settings.json` (global) → `~/.claude/settings.local.json` → folder `.claude/settings.json` (committed) → folder `.claude/settings.local.json` (gitignored). Later wins; **any `deny` beats any `allow`**.

## Process

### Step 1 — Measure
Run the audit (read-only; never writes):
```
bash scripts/permissions-report.sh ~        # base dir, defaults to $HOME
```
It lists each project folder with its repo, which settings files exist, file-access posture, Bash posture (none / specific / blanket), `bgIsolation` state, enabled MCP servers, and **credential-hygiene flags**.

### Step 2 — Reflect the structure back
Before deciding anything, show the user the schema in plain language: the folders found, their repos, and where each one currently makes them click "yes." Establish a shared mental model first.

### Step 3 — Interview (adaptive, structure-first)
Ask the pivot question:
> "Same trust level across all folders — each folder gets full access to its own files plus a safe command set — or refine folder by folder?"

Branch on the answer and **fine-tune follow-ups as you learn more** (once a folder is "just documents," stop asking about build tools). Draw trust levels from `references/trust-model.md` (Read-only / Standard / Full) as vocabulary, not a forced menu. Before offering blanket trust on a folder, surface any sensitive files found in Step 1.

### Step 4 — Apply (show the diff, then write)
Use `templates/folder-permission-block.md`. Non-negotiable rules:
- **Merge, never overwrite** — read the target file, add to arrays, preserve everything.
- **Deny-net always** with any blanket allow: `git push --force*`, `git push -f*`, `git reset --hard*`, `rm -rf *`, `rm -fr *`.
- **Scope steering** — blanket/personal allows go in `.claude/settings.local.json` (gitignored), **never** the committed `settings.json`. Verify `.local.json` is gitignored; fix if not.
- **bgIsolation: "none"** only when the user opts into subagents writing directly. Otherwise explain the gate.
- Validate JSON after each write (`jq -e . <file>`).

### Step 5 — Credential hygiene
- **Never** write a credential-bearing command into an allow-rule. If the report flags secrets already living in settings files (JWTs, `Basic` tokens, `*_KEY=`, private keys), report them as findings to **remove and rotate** — an allow-list is plaintext and not a vault.
- Confirm `.env*` is gitignored per folder; offer to fix.
- Secrets belong in per-project `.env` (or a secrets manager), not in Claude settings. See `references/trust-model.md`.

### Step 6 — Verify
Re-run the report. Confirm the posture changed as intended and JSON is valid. Remind the user settings load at **session start** — changes take effect next session.

## Red flags — STOP

- About to write `Bash(*)` into a **committed** `settings.json` → use `.local.json`.
- About to bake a token/key into an allow-rule → never; flag for rotation instead.
- Recommending `--dangerously-skip-permissions` to stop prompts → that's the failure mode this skill exists to prevent. Calibrate trust instead.
- Overwriting a settings file → merge.

## What this does NOT do
- It does not manage your secrets or read `.env` contents — only checks they aren't leaking into settings or git.
- It does not make security decisions for you — it surfaces trade-offs so you choose deliberately.
- Claude Code internals change between versions; re-check after upgrades.
