#!/usr/bin/env bash
# doc-size.sh — decide whether a document should be read directly or ingested via a subagent.
# Reading a large doc into the MAIN context is irreversible for the session (context is append-only).
# Over the threshold, route it through an isolated subagent that returns a synthesis instead.
#
# Usage:  ./doc-size.sh <file> [threshold_words]   (default threshold 1500 words ≈ 2000 tokens)
set -uo pipefail
f="${1:?usage: doc-size.sh <file> [threshold_words]}"
thr="${2:-1500}"
[ -f "$f" ] || { echo "no such file: $f"; exit 1; }

w=$(wc -w < "$f" | tr -d ' ')
t=$(awk -v w="$w" 'BEGIN{printf "%.0f", w*1.33}')

printf 'file:    %s\n' "$f"
printf 'words:   %s   ~tokens: %s   threshold: %s words\n' "$w" "$t" "$thr"
if [ "$w" -gt "$thr" ]; then
  printf 'VERDICT: DISPATCH SUBAGENT — over threshold.\n'
  printf '         Read it in an isolated subagent; return synthesis + section map + file path.\n'
  printf '         Do NOT read it into the main context (you cannot unload it afterwards).\n'
else
  printf 'VERDICT: READ DIRECTLY — under threshold, safe to ingest into the main context.\n'
fi
