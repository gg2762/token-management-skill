# Claude Code Foundations

**The things I wish I knew before starting a project with Claude Code.**

A toolkit for managing the one resource that quietly decides whether your AI agent stays sharp or slowly falls apart: its **context** — what it loads, what it remembers, and how it's all structured.

You don't need to be an engineer. If you use Claude Code for anything that lasts more than a few sessions — writing, research, running a business, a codebase — this is for you.

---

## Why this exists (read this first)

Here's the story almost everyone lives.

You start a project with Claude Code and it's brilliant. It knows your goals, your preferences, your files. Then a few months in, something's off. It's slower. It **forgets things you were sure were saved in memory.** Long sessions get "compacted" and key details quietly vanish. You catch yourself re-explaining the same context again and again.

This is not the model getting dumber. It's **unmanaged context.** Every project accumulates instructions, notes, and skills — and by default they all pile into the agent's working memory, re-read on every single message, until the signal you actually need is buried under months of noise and the window fills up until older context gets dropped.

The fix isn't "remember more." It's **structure**:
- decide up front how your project talks to Claude Code,
- keep what loads on *every* message small and high-signal,
- and pull in depth only when it's actually needed.

**Do this at the START of a project** — pause before you build skills and architect the relationship. It's the highest-leverage hour you'll spend. But it's also a **retrofit** for a project that's already degrading — which is probably why you're here. (It was for me.)

---

## The moves

### 1. `skill-architecture` — start here
Decide the structure *before* you build. Think of it like an org chart: a thin steering layer (`CLAUDE.md`), a few **"employee" personas** with real judgment (e.g. an engineering lead, a growth lead), narrow **doers** working under them, and **context that loads only when each persona is actually working.** Get this right and the other two moves are easy. Most people skip it and end up with a pile of random, overlapping skills that misfire and bloat.

### 2. `context-budget` — keep every-turn small
Audit and trim what's re-read on **every single message** (your instruction files, your memory index, every skill's description). This is the budget that, left unmanaged, causes the "it's gotten slower / it forgets the rules" feeling. The skill measures it for you and gives you a method to cut it.

### 3. `ingestion-compression` — control what comes in
When you hand the agent a big document, reading it directly dumps all of it into the session — and you **can't take it back out** (a session's memory only grows). This skill routes large documents through a *subagent* so only a short, useful synthesis enters your session, not 20 pages you'll never unload.

> Together: **how your project is structured, what loads every turn, and what enters mid-session.** The three ways context bloats — covered.

### 4. `permission-setup` — stop fighting the prompts
The first three keep the agent *sharp*. This one keeps it *usable*. Spend a week in Claude Code and you hit the wall: it asks to approve the same commands over and over, and the moment you run parallel subagents (the fast way to work) every file write needs another "yes." The escape hatch everyone reaches for — launching in `--dangerously-skip-permissions` ("dangerous mode") — is reckless: it switches off *every* check at once, so a stray `rm -rf` or force-push runs with nothing to stop it. `permission-setup` is the calibrated middle: it audits every project folder, asks how much you want to trust each one, and writes permissions that let the agent work prompt-free **while keeping a hard deny-net under the dangerous commands**. It also catches secrets that have leaked into your settings files. A different axis from the first three — friction and trust, not context — but the same lesson: set it up early, and it's also the fix when the prompts are already driving you up the wall.

---

## The problems, in detail

### Problem 1 — Unstructured skills (where it all starts)
Most people accumulate skills as a flat pile of task-named scripts ("fix-bug", "write-post") that overlap, fire on the wrong triggers, and carry no judgment. For context it's the worst case: a flat pile either crams everything into always-loaded metadata, or stuffs each skill with its full context inline — so invoking one dumps a wall of text, and the skill still runs *generically* because nothing tells it which context to load first. **`skill-architecture`** fixes this with the org-chart model and a required "Load-Context" block so each persona pulls its identity, playbook, and safety checks exactly when invoked.

### Problem 2 — Always-on bloat (the every-turn tax)
Every message you send re-sends the agent's entire standing context before it even reads your request. In a healthy setup that's small; by accumulation it grows into thousands of words of dated notes. Two things break: **the rules that matter drown** in history (the model follows them less reliably — "context rot"), and **documented lessons stop firing** because they live in an archive the agent rarely opens, so the same mistakes recur. **`context-budget`** measures the always-on tier and shows you what to relocate to on-demand.

### Problem 3 — Uncontrolled ingestion (the RAG problem)
Say "read this 20-page article" and the agent reads it directly — ~12,000 tokens land in the session and **stay there**, because session memory is append-only; you can't unload them even after you've used the one fact you needed. **`ingestion-compression`** sends the document to a subagent (its own separate memory), which returns a short synthesis + a map of where to find details + a pointer to the original. The bulk never touches your session.

### Problem 4 — Permission friction (and the dangerous-mode trap)
By default Claude Code asks before running commands or editing files it hasn't been told are safe. Healthy at first — but you end up approving the same things endlessly, and subagents prompt on *every* write because of a separate worktree-isolation gate most people never discover. Worn down, many flip to `--dangerously-skip-permissions`, which removes **all** guardrails at once. Both extremes are bad: death-by-prompts, or an agent that can `rm -rf` your repo unchecked. **`permission-setup`** finds the middle — per-folder trust *you* choose, always paired with a deny safety-net (force-push, hard reset, `rm -rf`) that holds even at full trust — plus a credential-hygiene check, because the "always allow" button quietly bakes any secret in your command (a service-role key, an API token) straight into a plaintext settings file.

### Proof (from the project that produced this)
Auditing one real project: always-on context dropped from **~11,900 → ~5,600 tokens per turn (−53%)**; the project instruction file went **~5,800 → ~800 words**; and 20 of the highest-value lessons were converted from inert archive entries into rules that auto-recall. Honest framing: the win is **signal-to-noise**, not raw cost (the agent now gets the right ~4,000 tokens instead of a noisy ~12,000).

---

## What each skill ships with
- **`skill-architecture`** — the 4-layer org-chart model, the skill-vs-agent rule (when to nest inline vs dispatch an isolated agent), the Load-Context block pattern, a drop-in persona template, and a worked example structure.
- **`context-budget`** — a measurement script (`context-report.sh`) for always-on vs on-demand tokens, the story/rule/procedure classification, an admission test for what earns always-on space, and how to gate recurring bugs.
- **`ingestion-compression`** — a size-check helper (`doc-size.sh`) and the subagent procedure with a 3-part `.synth.md` template (synthesis + map + pointer) and a fidelity dial.
- **`permission-setup`** — a read-only audit script (`permissions-report.sh`) that maps every project folder's trust posture, repo, and any leaked secrets; a trust-model reference (Read-only / Standard / Full tiers, the mandatory deny-net, and which settings file each rule belongs in); and copy-paste permission blocks per tier.

---

## Install

### 1. Get it
```bash
git clone https://github.com/gg2762/claude-code-foundations.git
cd claude-code-foundations
```
(Or **Fork** on GitHub first, then clone your fork — recommended if you'll customize.)

### 2. Install the skills (architecture first — that's the order you'll use them)
```bash
cp -R skills/skill-architecture    ~/.claude/skills/skill-architecture
cp -R skills/context-budget        ~/.claude/skills/context-budget
cp -R skills/ingestion-compression ~/.claude/skills/ingestion-compression
cp -R skills/permission-setup       ~/.claude/skills/permission-setup
```
Then just ask, in plain language: *"help me structure my skills"*, *"audit my context budget"*, or *"read this doc"* — the skills self-activate.

### 3. Wire the ingestion one-liner into your project's CLAUDE.md (easy win)
```markdown
## Document ingestion
When asked to read/understand a reference document, check its size first. If it's
over ~1,500 words, do NOT read it directly — dispatch a subagent to read it and
return a synthesis + section map + file path (see the ingestion-compression skill).
Read the full document directly only when I say "ingest the full X".
```

### 4. Audit what you have today
```bash
bash skills/context-budget/scripts/context-report.sh /path/to/your/project
# and your permission/trust posture across all project folders:
bash skills/permission-setup/scripts/permissions-report.sh ~
```

---

## Roadmap — a living toolkit
Context optimization isn't a one-time cleanup; it's ongoing as a project grows. Candidate directions: exact token counts via a real tokenizer; a persisted synthesis library so repeated docs are never re-read; a memory health-check (broken index links, split memory dirs); delegated-search patterns; output/tool-result hygiene. Issues and PRs welcome.

## Honest caveats
- These tools **relocate** load (always-on → on-demand) and **prevent** load (subagent ingestion); they don't shrink your total knowledge base. Per-turn cost drops; the library stays.
- Token counts are **approximate** (`words × 1.33`). Use a real tokenizer for exact figures.
- The loading model, the memory-dir layout, and the skill format are **Claude-Code-specific**. The *method* — structure first, keep every-turn small, ingest through subagents — transfers to any agent.
- A subagent's power is **isolation** — it prevents a load, it can't undo one that already happened. And it works on **files**, not pasted text.
- Claude Code internals change between versions; re-check after upgrades.

## License
MIT — see [LICENSE](LICENSE). Use it, fork it, ship it.
