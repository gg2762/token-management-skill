---
name: skill-architecture
description: Use when structuring or auditing how an agent's skills are organized — turning a flat pile of ad-hoc skills into a layered system (orchestrator → persona/"employee" skills → executor sub-skills/agents → on-demand context files). Invoke when the user mentions skill structure, nested skills, orchestrator/agent design, "my skills are messy / random", how to organize skills for a new project, separating workflows from agents, or how to guarantee the right context loads when a persona is invoked.
---

# Skill Architecture

Most people accumulate skills as a flat pile of task-named scripts ("fix-bug", "write-post") that overlap, misfire, and carry no judgment. The fix is to structure them like an **org chart**: a thin always-on steering layer, a few persona "employees" with judgment, narrow executors that do the work, and per-persona context files loaded only when that employee works.

Done well, this is also **token optimization**: only the orchestrator + persona *descriptions* are always-on; each persona's heavy context (brand, playbooks, checklists) loads on demand, exactly when invoked. (Pairs with the `context-budget` and `ingestion-compression` skills.)

## The four layers (the org chart)

```
Project folder + CLAUDE.md        ← steering: what this project is + the always-on rules (tiny)
        │
   Orchestrator (optional)        ← routes & sequences a multi-persona "shift". Knows WHO/WHEN, not HOW.
        │
   Employees / persona skills     ← domain leads with judgment (engineering-manager, growth-lead…).
        │                            Each owns a domain, plans, dispatches. Loaded into context on invoke.
   Executors (sub-skills / agents)← narrow doers. A sub-skill (inline) or a dispatched subagent (isolated).
        │
   Context files (the handbook)   ← per-persona nested .md: brand doctrine, playbooks, checklists/preflights,
                                     templates. Loaded ONLY when that persona works.
```

- **Layer 0 — CLAUDE.md:** always-on, tiny, steering only. See `context-budget`.
- **Layer 1 — Orchestrator:** one entry-point skill that pulls work and routes it to personas in a safe order. It should know *who does what and in what sequence*, never *how to do it*. Optional — only add it if you run multi-persona shifts; otherwise invoke personas directly.
- **Layer 2 — Employees (persona skills):** organized by **domain, not by task** (an "engineering manager", a "growth lead" — not "fix-bug"). 2–6 is healthy. Each plans and dispatches within its lane.
- **Layer 3 — Executors:** the ICs. Either a sub-skill loaded inline, or a dispatched subagent with its own context (see Skill-vs-Agent below).
- **Layer 4 — Context files:** the employee's handbook — brand/identity, domain playbooks, preflight checklists, output templates. Nested `.md` files referenced by the persona, loaded on demand.

## Skill vs Agent — nest inline or dispatch isolated?

- **Skill (inline)** = a persona/procedure loaded into the **current** context. Use when you need the judgment in the conversation and the work is light and sequential.
- **Agent / subagent (isolated)** = a **separate** context window that returns only its result. Use when the work is heavy (reads many files, processes a big document), when you want parallelism, or when you want the bulk kept out of the main context.
- **Rule of thumb:** *judgment + light → skill; volume + isolation → agent.* (Heavy executors should almost always be agents — see `ingestion-compression`.)

## The Load-Context block — guarantee the right context at invocation

This is the mechanism people miss. Metadata (always-on) tells the agent **when** to invoke a persona. But once invoked, a persona runs *generically* unless it is told **what** to load. So every persona skill must open with an explicit **Required reading / Load context** block:

```markdown
## Step 0 — Load context (REQUIRED before anything else)
Read these in order, skip none:
1. brand.md      — identity/voice FIRST, so output is brand-specific, not generically smart
2. playbook.md   — the domain method
3. <task>.md     — task-specific templates
Before marking work done, run preflight.md (the recurring-failure gate for this domain).
```

Rules for the block:
- **Identity first.** Load the brand/domain-identity file before any universal method, or the persona produces "generically smart, brand-blind" output.
- **Gate recurring failures.** For surfaces with a recurring bug class, end with "run `preflight.md` before done" — a checklist that fires at work-time (e.g. an edge-function/auth checklist for an engineering persona).
- **Keep the body lean.** The SKILL.md is a router + the Load-Context block. The substance lives in the nested files it points to — that's what keeps the always-on metadata small while the persona is still deeply context-aware on demand.

## Recipe — structure a new project's skills
1. Start from the folder + a lean `CLAUDE.md` (steering only).
2. Name the **personas** you need, by domain (not task). 2–6.
3. For each persona: a lean `SKILL.md` (router + Load-Context block) + nested context files (its handbook).
4. Add **executors** as sub-skills or agents per the skill-vs-agent rule.
5. Add an **orchestrator** only if you run multi-persona shifts.
6. Write **precise descriptions** — that's the always-on routing surface; vague descriptions cause mis-invocation.

See `templates/persona-skill-template.md` for a drop-in persona skeleton and `references/example-structure.md` for a full worked tree.

## Anti-patterns
- **Flat pile of task-named skills** — no judgment layer, overlapping triggers, routing ambiguity.
- **Fat SKILL.md with all context inline** — always-on bloat across many skills, or a huge load on every invoke.
- **Persona with no Load-Context block** — runs generically; the handbook never gets read.
- **Everything a skill, nothing an agent** — main context bloats on heavy work.
- **Orchestrator that knows HOW** — it should only know WHO and WHEN; the how lives in the personas.
