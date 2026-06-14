# Example — a layered skill structure for a real project

A worked example of the org-chart model. Names are illustrative; copy the *shape*, not the labels.

```
my-project/
├── CLAUDE.md                        # Layer 0 — steering only: what the project is + always-on rules (lean)
└── .claude/skills/
    │
    ├── orchestrator/                # Layer 1 — routes a multi-persona "shift". Knows WHO/WHEN, not HOW.
    │   └── SKILL.md                 #   pulls a work-list, sequences personas, reports back
    │
    ├── engineering-lead/            # Layer 2 — persona "employee" (judgment, plans, dispatches)
    │   ├── SKILL.md                 #   lean router + Step 0 Load-Context block
    │   ├── preflight.md             # Layer 4 — gate: the recurring-failure checklist (e.g. auth/401, env)
    │   └── conventions.md           # Layer 4 — domain handbook (paths, patterns)
    │
    ├── growth-lead/                 # Layer 2 — another persona
    │   ├── SKILL.md
    │   ├── brand.md                 # Layer 4 — identity FIRST (loaded before method)
    │   ├── playbook.md              # Layer 4 — the domain method
    │   └── keywords.md              # Layer 4 — task data
    │
    └── content-producer/            # Layer 3 — executor sub-skill (narrow doer, invoked by growth-lead)
        └── SKILL.md
```

## How a request flows
1. User invokes the **orchestrator** (or a persona directly).
2. Orchestrator routes "ship feature X" → **engineering-lead**.
3. engineering-lead runs **Step 0**: reads `conventions.md`, plans the work.
4. For the heavy implementation it **dispatches a subagent** (isolated context) so the file-by-file work never bloats the main thread; only the result returns.
5. Before "done", engineering-lead runs **`preflight.md`** — the gate that catches the runtime-failure class tests can't.

## What's always-on vs on-demand here
- **Always-on (every turn):** `CLAUDE.md` + each skill's one-line `description`. Small and flat.
- **On-demand (only when that persona works):** every `SKILL.md` body + all the Layer-4 `.md` handbooks.

That asymmetry is the whole point: a deep, capable system whose *per-turn* cost stays tiny because depth lives in on-demand layers. Audit it with the `context-budget` skill.

## Contrast — the anti-pattern this replaces
```
.claude/skills/
├── fix-bug/           # task-named, no judgment, overlaps with...
├── fix-other-bug/     # ...this one. ambiguous routing.
├── write-post/        # no brand context loaded → generic output
└── do-the-thing/      # fat SKILL.md, everything inline → always-on bloat
```
No personas, no context loading, no gates. It "works" until the project grows — then it misfires and bloats.
