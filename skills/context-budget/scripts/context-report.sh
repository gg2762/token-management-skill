#!/usr/bin/env bash
# context-report.sh — audit the always-on vs on-demand context budget of a Claude Code project.
#
# "Always-on" = re-sent to the model on EVERY turn (instruction files + memory index + each
# skill's frontmatter/description). This is the scarce budget worth protecting.
# "On-demand"  = loaded only when relevant (skill bodies, nested skill files, individual memories).
#
# Usage:  ./context-report.sh [project_dir]      (defaults to current directory)
# Token estimate is approximate: words * 1.33. For exact counts, pipe files through a real tokenizer.
set -uo pipefail

PROJ="${1:-$PWD}"
PROJ="$(cd "$PROJ" 2>/dev/null && pwd)" || { echo "no such dir: ${1:-$PWD}"; exit 1; }
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
TOKR=1.33

words(){ wc -w < "$1" 2>/dev/null | tr -d ' ' || echo 0; }
tok(){ awk -v w="${1:-0}" -v r="$TOKR" 'BEGIN{printf "%.0f", w*r}'; }
sumwords(){ local t=0 n; for f in "$@"; do [ -f "$f" ] && { n=$(words "$f"); t=$((t+n)); }; done; echo "$t"; }

# Claude Code derives the per-project memory dir by replacing / and _ in the abs path with -.
slug="$(printf '%s' "$PROJ" | sed 's|[/_]|-|g')"
MEMDIR="$CLAUDE_HOME/projects/$slug/memory"

acct="$CLAUDE_HOME/CLAUDE.md"
projcm="$PROJ/CLAUDE.md"
memidx="$MEMDIR/MEMORY.md"

# frontmatter words (between the first two --- lines) = the always-on slice of a skill
frontmatter_words(){
  local total=0 f n
  for f in "$@"; do
    [ -f "$f" ] || continue
    n=$(awk '/^---[[:space:]]*$/{c++; next} c==1{print} c>=2{exit}' "$f" | wc -w | tr -d ' ')
    total=$((total + n))
  done
  echo "$total"
}

shopt -s nullglob
gskills=( "$CLAUDE_HOME"/skills/*/SKILL.md )
pskills=( "$PROJ"/.claude/skills/*/SKILL.md )
gmeta=$(frontmatter_words "${gskills[@]}")
pmeta=$(frontmatter_words "${pskills[@]}")

# on-demand: full skill bodies + nested skill files, minus the frontmatter already counted
allskillfiles=( "$CLAUDE_HOME"/skills/*/*.md "$PROJ"/.claude/skills/*/*.md "$PROJ"/.claude/skills/*/**/*.md )
skill_total=$(sumwords "${allskillfiles[@]}")
skill_ondemand=$(( skill_total - gmeta - pmeta )); [ "$skill_ondemand" -lt 0 ] && skill_ondemand=0

# on-demand: memory files (everything in the memory dir except the index)
memfiles=()
if [ -d "$MEMDIR" ]; then while IFS= read -r f; do [ "$(basename "$f")" = "MEMORY.md" ] || memfiles+=("$f"); done < <(find "$MEMDIR" -maxdepth 1 -name '*.md'); fi
mem_ondemand=$(sumwords "${memfiles[@]}")

w_acct=$(words "$acct"); w_proj=$(words "$projcm"); w_idx=$(words "$memidx")
always=$(( w_acct + w_proj + w_idx + gmeta + pmeta ))
ondemand=$(( skill_ondemand + mem_ondemand ))

printf '\n=== Claude Code context budget — %s ===\n' "$PROJ"
printf 'memory dir: %s%s\n\n' "$MEMDIR" "$( [ -d "$MEMDIR" ] || echo '  (NOT FOUND — slug mismatch?)')"

printf 'ALWAYS-ON (every turn)              words    ~tokens\n'
printf '  account CLAUDE.md             %8s  %8s\n' "$w_acct" "$(tok "$w_acct")"
printf '  project CLAUDE.md             %8s  %8s\n' "$w_proj" "$(tok "$w_proj")"
printf '  memory index (MEMORY.md)      %8s  %8s\n' "$w_idx"  "$(tok "$w_idx")"
printf '  skill frontmatter (%2s global) %8s  %8s\n' "${#gskills[@]}" "$gmeta" "$(tok "$gmeta")"
printf '  skill frontmatter (%2s project)%8s  %8s\n' "${#pskills[@]}" "$pmeta" "$(tok "$pmeta")"
printf '  ------------------------------------------------\n'
printf '  TOTAL ALWAYS-ON              %8s  %8s\n\n' "$always" "$(tok "$always")"

printf 'ON-DEMAND (loaded only when used)   words    ~tokens\n'
printf '  skill bodies + nested files  %8s  %8s\n' "$skill_ondemand" "$(tok "$skill_ondemand")"
printf '  memory files (%2s)             %8s  %8s\n' "${#memfiles[@]}" "$mem_ondemand" "$(tok "$mem_ondemand")"
printf '  ------------------------------------------------\n'
printf '  TOTAL ON-DEMAND              %8s  %8s\n\n' "$ondemand" "$(tok "$ondemand")"

ratio=$(awk -v a="$always" -v o="$ondemand" 'BEGIN{ if(a+o>0) printf "%.0f", 100*a/(a+o); else print 0 }')
printf 'Always-on is %s%% of your total memory+skill stack.\n' "$ratio"
printf 'Rule of thumb: anything always-on that is derivable-from-code, narrow, or historical\n'
printf 'belongs on-demand. See references/doctrine.md.\n\n'
