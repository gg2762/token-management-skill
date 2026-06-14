# claude-context-budget

A Claude Code skill + script for auditing and reducing what your agent loads. The goal isn't *less knowledge* — it's getting the **right** context in front of the agent at the **right time**.

Most agent setups grow by accumulation: every lesson, schema note, and changelog gets appended to an always-on instruction file that's re-read on every turn. Past a point this *degrades* the agent (context rot) — the rules that matter drown in history, and documented lessons keep getting violated because they live in an archive nobody opens.

This tool measures the problem and gives you a method to fix it.

## What's here
- **`scripts/context-report.sh`** — measures your **always-on** (every-turn) vs **on-demand** context in words and approximate tokens, and shows what share of your stack is always-on.
- **`SKILL.md`** — the method: the two-tier load model, the story/rule/procedure classification, the always-on admission test, gating recurring bugs, and memory hygiene.
- **`references/doctrine.md`** — the longer rationale, including **ingestion compression / RAG offloading** (using subagents so large documents never enter your main context).

## Quick start
```bash
bash scripts/context-report.sh /path/to/your/project   # defaults to $PWD
```
Example output:
```
ALWAYS-ON (every turn)              words    ~tokens
  account CLAUDE.md                  202       269
  project CLAUDE.md                  805      1071
  memory index (MEMORY.md)           837      1113
  skill frontmatter (35 global)     2097      2789
  skill frontmatter ( 9 project)     510       678
  TOTAL ALWAYS-ON                   4451      5920
```
Drive the **always-on total** down. Anything always-on that is derivable-from-code, narrow, or historical belongs on-demand.

## Install as a skill (optional)
Copy this folder into your skills directory so the agent can invoke it:
```bash
cp -R claude-context-budget ~/.claude/skills/context-budget
```
Then ask the agent to "audit my context budget."

## The method in one screen
1. **Measure** — run the script; treat always-on as the metric.
2. **Classify** each piece of knowledge: **Story** (archive, on-demand) / **Rule** (short indexed memory that auto-recalls) / **Procedure** (checklist wired into the skill, fires at work-time).
3. **Admission test** — keep a line always-on only if it's *not derivable from code* AND *broad* AND *stable*. Otherwise relocate.
4. **Gate recurring bugs** — convert the worst recurring failure class into a preflight checklist inside the skill that does the risky work.
5. **Memory hygiene** — one canonical memory dir, clean index, large docs read on demand.
6. **Ingestion compression** — read large documents through a **subagent** that returns a synthesis, so raw source never enters your main context (it's append-only; you can't unload it later).

## Honest caveats
- It **relocates** load (always-on → on-demand); it does not shrink your total knowledge base. The per-turn tax drops; the library stays.
- Token counts are approximate (`words × 1.33`). For exact numbers, pipe files through a real tokenizer.
- The two-tier loading model and the memory-dir slug derivation are **Claude-Code-specific**. The *method* (tiers, story/rule/procedure, gating, ingestion compression) transfers to any agent.
- Claude Code's internals can change between versions; re-check after upgrades.

## License
MIT (add a LICENSE file before publishing).
