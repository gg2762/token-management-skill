---
name: context-budget
description: Use to audit and reduce a Claude Code agent's context. Invoke when the user mentions context optimization, token budget, "why is my agent slow/sloppy", bloated CLAUDE.md, memory cleanup, context rot, or wants to know how much is loaded every turn. Measures always-on vs on-demand context, classifies knowledge as story/rule/procedure, and recommends what to relocate, gate, or cut.
---

# Context Budget

A meta-skill for keeping a Claude Code setup lean. The goal is not "less knowledge" — it's getting the **right** context in front of the agent at the **right time**.

## Core model: two load tiers

| Tier | What loads | When | Cost |
|---|---|---|---|
| **Always-on** | account + project `CLAUDE.md`, the memory index (`MEMORY.md`), and every skill's frontmatter/description | **Every turn** | Permanent tax — protect this budget |
| **On-demand** | a skill's full body, nested skill files, individual memory files | Only when invoked / recalled | Cheap — load freely |

The waste is almost always concentrated in the always-on tier. Most setups carry a large always-on `CLAUDE.md` that is mostly derivable-from-code or historical changelog.

## Step 1 — Measure
Run the report:
```
bash scripts/context-report.sh /path/to/project   # defaults to $PWD
```
It prints always-on vs on-demand totals (words + approximate tokens) and the always-on share of the stack. Treat the always-on number as the metric to drive down.

## Step 2 — Classify every piece of knowledge
For anything you're tempted to keep always-on, decide what it is:
- **Story** — a one-time retrospective ("we tried X, it broke"). Keep in an archive/log. Useless as a live instruction. Loads on demand only.
- **Rule** — a durable prescription ("always do X"). Make it a short, indexed memory so it auto-recalls.
- **Procedure** — a repeatable checklist ("when touching Y, run these steps"). Wire it into the relevant skill so it fires at the moment of work — not a hope-it-gets-read doc.

Most teams write everything as stories and never convert them. That's why documented lessons keep getting violated.

## Step 3 — The always-on admission test
A line earns always-on space only if **all three** hold:
1. **Not derivable from code** (the agent can read `package.json`, migrations, configs).
2. **Broad** (relevant across many tasks, not one narrow domain).
3. **Stable** (a durable rule, not a dated changelog entry).
Fail any → relocate to an on-demand reference doc or a skill.

## Step 4 — Gate recurring failures
If a class of bug keeps recurring, the fix is almost never "write it down again" — it's already written somewhere. Convert it into a **preflight checklist** inside the skill that does the risky work, with an explicit "before you mark this done, run these checks" gate. Passive knowledge → active gate.

## Step 5 — Memory hygiene
- One canonical memory dir per project (Claude Code keys it by working directory). Split dirs fragment recall.
- Keep large reference docs out of the index — they should be path-read on demand, not auto-recalled.
- Verify the index has no broken links and no dangling path references after any move.

## What this does NOT do
- It does not shrink your knowledge base — it relocates load from always-on to on-demand. The total stack stays roughly the same; the per-turn tax drops.
- Token counts are approximate (`words × 1.33`). For exact figures, use a real tokenizer.
- The loading model is Claude-Code-specific; the *method* (tiers, story/rule/procedure, gating) transfers to other agents.
