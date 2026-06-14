# Context Budget — Doctrine

The longer rationale behind the skill. Read when you want the *why*, not just the steps.

## Why always-on is the only budget that matters
Inference is stateless: the entire prompt — system instructions, `CLAUDE.md`, memory index, skill metadata, and the whole conversation so far — is re-sent on every turn. Prompt caching makes re-sending a stable prefix cheap (~10% of input price within the cache TTL), so **cost is a weak argument**. The strong argument is **context rot**: model instruction-following degrades as irrelevant tokens accumulate. A rule buried in 6,000 words of dated changelog is followed less reliably than the same rule in a 1,000-word file where everything is load-bearing.

So the objective is not "spend fewer tokens." It's "raise the hit-rate on the context that matters." You do that by keeping the always-on tier small and entirely high-signal, and pushing everything else to on-demand.

## Story / Rule / Procedure — the conversion most setups skip
A documented lesson has three possible useful forms:
- **Story** → an archive entry. Narrative, retrospective, good for writing/learning, *inert as an instruction*. Loads only when deliberately read.
- **Rule** → a short, indexed memory the agent recalls automatically when relevant.
- **Procedure** → a checklist wired into the skill that does the work, gated before "done."

One incident usually deserves a story (the full account) *and* a rule or procedure (the durable guardrail). Writing only the story is journaling — the agent will repeat the mistake because nothing fires at the decision point.

## The always-on admission test
Keep a line always-on only if ALL hold:
1. **Not derivable from code.** If reading the repo tells the agent, it doesn't belong.
2. **Broad.** Surfaces across many tasks, not one domain.
3. **Stable.** A durable rule, not a dated entry.
Everything else → an on-demand reference doc, or a skill.

## Gating recurring failures
Some bug classes are runtime/behavioral and a normal test suite can't catch them (auth/permission failures, environment drift, classifier routing). For these, a compile/test green is necessary but not sufficient. Add a **preflight checklist** inside the skill that performs the risky work, with a hard gate: "before marking this done, run these checks." This converts a lesson that lives in an archive nobody opens into a step that executes at exactly the right moment.

## Ingestion compression (RAG offloading)
The always-on tier is only half the problem. The other half is **what enters context during a session** when you read documents.

Key fact: **a session's context is append-only.** Once the main agent reads a 20-page document, those tokens stay until the session is compacted — you cannot selectively "unload" them. So the discipline is to **never let large source material enter the main context in the first place.**

The mechanism: **dispatch a subagent.** A subagent has its own separate context window. It reads the full document, synthesizes it to a few hundred tokens of the key concepts an agent needs to act, and returns *only the synthesis*. The full document never touches the parent context. The subagent's context is discarded when it finishes.

Two flavors:
- **Ephemeral** — "read X, return a structured synthesis." Use when you need the gist now.
- **Persisted** — subagent reads X, writes a compressed `*.synth.md` to disk, returns a pointer + brief. Future reads use the compressed file; the original stays available for targeted drill-down.

Caveats: synthesis is lossy. Keep a pointer to the original for facts the synthesis dropped, and don't aggressively compress material where exact detail matters (specs, legal, code). Tune fidelity to the task.

## What good looks like
- Always-on tier is small and 100% load-bearing rules + product/strategy steering that can't be derived from code.
- Lessons exist as rules/procedures that fire, not just stories in a log.
- One canonical memory dir, clean index, no dangling references.
- Large documents are ingested through subagents, so the main context holds syntheses, not raw source.
