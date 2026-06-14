# token-management-skill

**A toolkit for managing what an AI coding agent loads — so it stays fast, accurate, and cheap as your project grows.**

Two skills for Claude Code that attack the two ways context silently bloats:

1. **`context-budget`** — trims the *always-on* context re-read on every single turn.
2. **`ingestion-compression`** — stops large documents from flooding context when you ask the agent to read them.

Static hygiene + dynamic hygiene = the agent gets the **right** context at the **right time**, instead of *everything, all the time.*

---

## The problem

AI agents get *worse* as they accumulate context, not better. There are two distinct ways this happens, and they need two different fixes.

### Problem 1 — Always-on context bloat (the every-turn tax)

Every time you send a message, the agent re-reads its entire standing context: the instruction files (`CLAUDE.md`), the memory index, and a one-line description of every installed skill. This is **re-sent on every single turn** before the agent even looks at your actual request.

In a healthy setup this is small. But it grows by accumulation — every schema note, every changelog entry, every "remember this" gets appended to an always-on file that's now thousands of words. Two things break:

- **Context rot.** Model instruction-following degrades as irrelevant tokens pile up. The 15 rules that matter drown in 5,000 words of dated history. The agent is technically "informed" and practically distracted.
- **Documented lessons stop firing.** Hard-won fixes get written into a giant archive the agent only reads if it happens to. So the same class of bug keeps recurring — *the knowledge exists, it just never fires at the right moment.*

The insight: **not all context loads equally.** There's an *always-on* tier (re-read every turn) and an *on-demand* tier (loaded only when relevant). The waste is concentrated almost entirely in always-on. That's the budget to protect.

### Problem 2 — Uncontrolled document ingestion (the RAG problem)

When you say *"read this 20-page article"* and the agent reads it directly, those ~12,000 tokens land in the main context — and **a session's context is append-only.** You cannot unload them. They sit there for the rest of the session, crowding out everything else, even after you've extracted the one fact you needed.

Most of a long document is irrelevant to the task. Reading it whole is like photocopying a book to quote one sentence.

The insight: **a subagent has its own separate context window.** Send the document there. The subagent reads all 20 pages in *its* throwaway context, returns a few-hundred-token synthesis, and the raw source **never touches your main context.** You keep the substance; you discard the bulk.

---

## What this repo does

### `context-budget` — fix the always-on tax
- A **measurement script** (`context-report.sh`) that reports your always-on vs on-demand context in words and approximate tokens, and what share of your stack is always-on.
- A **method**: the two-tier load model; classify every piece of knowledge as **Story** (archive, on-demand) / **Rule** (short memory that auto-recalls) / **Procedure** (checklist wired into the skill, fires at work-time); an *admission test* for what earns always-on space; and how to **gate recurring bugs** with a preflight checklist.

### `ingestion-compression` — fix uncontrolled ingestion
- A **size-check helper** (`doc-size.sh`) that decides read-directly vs dispatch-subagent by document size.
- A **procedure**: route large reference docs through a subagent that returns a 3-part `.synth.md` — **Synthesis** (the substance), **Map** (a section index so missing details are cheap to fetch), and **Pointer** (the path back to the original) — with a fidelity dial and an explicit override.

### Proof (from the project that produced this)
Auditing one real project: always-on context dropped from **~11,900 → ~5,600 tokens per turn (−53%)**; the project instruction file went **~5,800 → ~800 words**; 20 of the highest-value lessons were converted from inert archive entries into rules that auto-recall. Honest framing: the win is **signal-to-noise**, not raw cost (prompt caching makes re-reads cheap) — the agent now gets the right ~4,000 tokens instead of a noisy ~12,000.

---

## Install

### 1. Get the repo
```bash
git clone https://github.com/gg2762/token-management-skill.git
cd token-management-skill
```
(Or **Fork** it on GitHub first, then clone your fork — recommended if you want to customize.)

### 2. Install the skills
Copy each skill folder into your Claude Code skills directory:
```bash
cp -R skills/context-budget        ~/.claude/skills/context-budget
cp -R skills/ingestion-compression ~/.claude/skills/ingestion-compression
```
Then in any session just ask: *"audit my context budget"* or *"read this doc"* — the skills self-activate.

### 3. Wire the one-liner into CLAUDE.md (the easy win)
Add this block to your project's `CLAUDE.md` so the agent compresses large docs by default. **This one line is the whole behavior change** — everything else is on-demand detail in the skill:

```markdown
## Document ingestion
When asked to read/understand a reference document, check its size first. If it's
over ~1,500 words, do NOT read it directly — dispatch a subagent to read it and
return a synthesis + section map + file path (see the ingestion-compression skill).
Read the full document directly only when I say "ingest the full X".
```

That gives you **compress-by-default, full-ingest-on-request** — the override is built in.

### 4. Run the budget audit
```bash
bash skills/context-budget/scripts/context-report.sh /path/to/your/project
```

---

## Roadmap — this is a living toolkit

Context optimization isn't a one-time cleanup; it's ongoing as a project grows. Planned / candidate directions:
- **Exact token counts** via a real tokenizer (replace the `words × 1.33` estimate).
- **Persisted synthesis library** — a manifest of `.synth.md` files so repeated docs are never re-read.
- **Memory health check** — auto-detect split memory dirs, broken index links, dangling references.
- **Delegated-search patterns** — codify "send the file-sweep to a subagent, keep the conclusion."
- **Output discipline & tool-result hygiene** — patterns for keeping the agent's own verbosity and large tool outputs from bloating context.

Issues and PRs welcome — the goal is to keep producing token optimization as agents and projects scale.

---

## Caveats (read these)
- These tools **relocate** load (always-on → on-demand) and **prevent** load (subagent ingestion); they don't shrink your total knowledge base. Per-turn cost drops; the library stays.
- Token counts are **approximate** (`words × 1.33`). Use a real tokenizer for exact figures.
- The two-tier loading model, the memory-dir slug derivation, and the skill format are **Claude-Code-specific**. The *method* (tiers; story/rule/procedure; gating; subagent ingestion) transfers to any agent.
- A subagent's power is **isolation** — it prevents a load, it can't undo one that already happened. And it works on **files**, not pasted text (a paste is already in context).
- Claude Code internals change between versions; re-check after upgrades.

## License
MIT — see [LICENSE](LICENSE). Use it, fork it, ship it.
