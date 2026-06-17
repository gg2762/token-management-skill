# Trust Model — tiers, safety net, and credential hygiene

The vocabulary the interview draws on. These are *not* a forced menu — the conversation adapts — but every applied config maps to one of these postures plus the mandatory deny-net.

## The two failure modes this avoids

- **Death by prompts.** Under-permissioned. You approve the same commands forever; parallel subagents make it unbearable. People give up on good workflows to escape it.
- **The reckless bypass.** `claude --dangerously-skip-permissions` ("dangerous mode") turns *every* check off. One bad `rm -rf` or `git push --force` now runs with zero friction. This is not a permissions strategy — it's the absence of one.

Calibrated trust is the answer: open where it's safe, hard floor everywhere.

## Trust tiers (per folder)

| Tier | File access | Bash | Subagents | Good for |
|---|---|---|---|---|
| **Read-only** | `Read(<folder>/**)` | none | gated | folders you want the agent to consult but not change |
| **Standard** | `Read/Edit/Write(<folder>/**)` | safe families only (`git`, `npm`, common unix) + deny-net | gated | most projects; unusual commands still prompt once |
| **Full** | `Read/Edit/Write(<folder>/**)` | `Bash(*)` + deny-net | write directly (`bgIsolation: none`) | folders you actively develop in and want zero friction |

"Gated" subagents = the default `worktree` isolation; they prompt before writing to the main checkout. "Write directly" removes that gate.

## The deny safety-net (always attached to Standard and Full)

Deny beats allow at every layer, so these hold even under `Bash(*)`:

```
"deny": [
  "Bash(git push --force*)",
  "Bash(git push -f*)",
  "Bash(git push --force-with-lease*)",
  "Bash(git reset --hard*)",
  "Bash(rm -rf *)",
  "Bash(rm -fr *)"
]
```

This is the floor that makes Full trust acceptable and makes dangerous mode unnecessary.

## Scope steering — which file gets the rule

| Rule type | Goes in | Why |
|---|---|---|
| Blanket allows (`Bash(*)`), anything personal | `.claude/settings.local.json` (gitignored) | never commit broad trust or machine-specific paths to a shared repo |
| Team-wide, safe-by-default rules | `.claude/settings.json` (committed) | travels with the repo for everyone |
| Truly global personal defaults | `~/.claude/settings.json` | applies in every folder |

Always confirm `.claude/settings.local.json` is gitignored before writing blanket trust into it.

## Worktree isolation (the subagent gate)

`worktree.bgIsolation` defaults to `"worktree"`: background/sub-agents are blocked from editing the **main checkout** until they enter their own worktree — so they prompt even when the file path is allow-listed. Two resolutions:
- `"none"` — subagents edit the working copy directly, like the main agent. Removes the friction; the trade-off is parallel agents share one tree and can collide on the same file.
- Leave default — agents run in isolated worktrees and you merge their work. Safer, but writes happen elsewhere.

Set in the folder's `.claude/settings.json` (or `~/.claude/settings.json` to apply everywhere).

## Credential hygiene

Secrets must never end up in permission rules. The common leak: clicking "always allow" on a command with an inline secret (`SUPABASE_SERVICE_ROLE_KEY=eyJ... node script.js`) bakes that secret verbatim into an `allow` array — plaintext, easy to commit by accident.

Rules:
- **Never** write a credential-bearing command into an allow-rule. Allow rules are not a vault.
- If secrets are already in settings files, **remove and rotate** them — assume exposure.
- Secrets live in per-project `.env` (gitignored) with a committed `.env.example`. Per-project scoping limits blast radius. Global, identity-level creds (a personal token) belong in the shell profile or OS keychain, not a project.
- Higher-assurance option: a secrets manager that injects at runtime (e.g. `op run`, `dotenvx`) so plaintext never sits on disk — worth it for God-mode keys like service-role.

Patterns worth flagging in settings files: `eyJ` (JWT), `Basic [A-Za-z0-9+/=]{20,}`, `*_KEY=`, `*_SECRET=`, `SERVICE_ROLE`, `BEGIN ... PRIVATE KEY`, `id_rsa`.
