---
name: ingestion-compression
description: Use before reading any large reference document (article, report, spec, PDF, long markdown) into context. Invoke when the user says "read this document / article / file", "look into this", "summarize this doc", or drops a large file to understand. Routes large documents through an isolated subagent so the raw source never enters the main context — returns a compact synthesis + a section map + a pointer to the original. Skip for files you must EDIT (code), and skip when the user explicitly says to ingest the full document.
---

# Ingestion Compression (RAG offloading)

The main context is **append-only within a session** — once you read a 20-page document, those tokens stay until the session is compacted. You cannot selectively unload them. So the rule is: **never let large source material enter the main context in the first place.** Instead, read it in a subagent (which has its own throwaway context) and bring back only a synthesis.

## When to apply
- The user points you at a **reference document** to understand (article, report, spec, transcript, PDF, long `.md`).
- Skip when: (a) it's a **code file you must edit** — you need the real bytes; (b) the user explicitly says **"ingest / read the full X"** (the override); (c) it's small (under the threshold).

## Procedure
1. **Check size first.** `bash scripts/doc-size.sh <file>` (threshold ~1500 words ≈ 2000 tokens). Under threshold → read directly, done. Over → continue.
2. **Dispatch a subagent** (Agent / Task tool) to read the full document. The subagent has a separate context window; the raw document never touches yours.
3. The subagent **returns a synthesis** in the `.synth.md` shape below — substance + map + pointer — sized to the requested fidelity.
4. **Optionally persist** it next to the original as `<name>.synth.md` so future reads (this session or later) use the compressed version. Return the synthesis to the main thread; that's all that enters your context.
5. **Drill down on demand.** If you later need a detail the synthesis dropped, use the **map** to read just that slice of the original (offset/grep) — never re-ingest the whole thing.

## Fidelity levels (pick per task)
- **Gist** (~1%) — 5–10 bullets, the thesis and conclusions only.
- **Structured extract** (~5–10%) — claims, numbers, named entities, decisions, caveats. Default.
- **Full outline** (~15%) — section-by-section, preserves structure and most facts.

## The `.synth.md` shape (three parts — always include all three)
```markdown
---
source: /abs/path/to/original.md
original_tokens: ~12000   synth_tokens: ~600   fidelity: structured-extract
---
## Synthesis        # the SUBSTANCE — key concepts an agent needs to act
- …
## Map              # the NAVIGATION — where to drill down in the original
- §1 framing — lines 1–40
- §3 the tariff figures — lines 210–340   ← exact numbers here
## Pointer          # the ADDRESS — already in frontmatter `source:`; restate if helpful
```
- **Synthesis** = the compressed content (what enters context).
- **Map** = a section index so missing details are cheap to fetch from the original.
- **Pointer** = the path back to the full source for targeted re-reads.

## Caveats
- Synthesis is **lossy.** Keep the pointer + map so exact facts are recoverable. Don't aggressively compress where precise detail is load-bearing (specs, legal, code).
- Works on **files**, not pastes. If the user pastes a long document into the chat, it's already in context — too late to offload; note that and suggest a file next time.
- A subagent's value is **isolation**, not deletion — it prevents the load, it can't undo one that already happened.

## Pairs with
The `context-budget` skill (same repo) governs the static always-on tier; this skill governs the dynamic per-session intake. Static + dynamic = full context hygiene.
