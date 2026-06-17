#!/usr/bin/env bash
# permissions-report.sh — read-only audit of Claude Code permission posture
# across your project folders. Never writes anything.
#
# Usage: bash permissions-report.sh [BASE_DIR]   (BASE_DIR defaults to $HOME)
#
# For each project folder (a dir containing .git and/or .claude) it reports:
#   repo remote, which settings files exist, file-access posture,
#   Bash posture (none/specific/blanket + deny-net), worktree.bgIsolation,
#   enabled MCP servers, and credential-hygiene flags.

set -uo pipefail
BASE="${1:-$HOME}"
HOME_CLAUDE="$HOME/.claude"

have_jq=1; command -v jq >/dev/null 2>&1 || have_jq=0
if [ "$have_jq" -eq 0 ]; then
  echo "NOTE: jq not found — falling back to text scanning (less precise). Install jq for full detail."
  echo
fi

# Read a JSON path from a file; empty string if missing/invalid. Falls back to grep without jq.
jget() { # $1=file $2=jq-filter
  [ -f "$1" ] || return 0
  if [ "$have_jq" -eq 1 ]; then jq -r "$2 // empty" "$1" 2>/dev/null; fi
}

# Classify Bash posture from an allow array in a settings file.
bash_posture() { # $1=file
  local f="$1"; [ -f "$f" ] || { echo "none"; return; }
  local allow
  if [ "$have_jq" -eq 1 ]; then
    allow="$(jq -r '.permissions.allow[]? // empty' "$f" 2>/dev/null)"
  else
    allow="$(grep -o '"Bash([^"]*)"' "$f" 2>/dev/null)"
  fi
  if printf '%s\n' "$allow" | grep -qE '"?Bash\(\*\)"?$|^Bash\(\*\)$'; then echo "blanket"
  elif printf '%s\n' "$allow" | grep -q 'Bash('; then echo "specific"
  else echo "none"; fi
}

has_denynet() { # $1=file -> "yes"/"no"
  local f="$1"; [ -f "$f" ] || { echo "no"; return; }
  if grep -qE 'rm -rf|reset --hard|push --force|push -f' "$f" 2>/dev/null; then echo "yes"; else echo "no"; fi
}

file_posture() { # $1=folder $2,$3=settings files
  local folder="$1"; shift
  for f in "$@"; do
    [ -f "$f" ] || continue
    if grep -qE "(Edit|Write)\($folder|(Edit|Write)\(\./|(Edit|Write)\(\*\*" "$f" 2>/dev/null; then
      echo "R/W/E scoped to folder"; return
    fi
  done
  echo "none (Edit/Write will prompt)"
}

# Resolve bgIsolation: folder settings win over global; default is 'worktree'.
bgiso() { # $1=folder-settings $2=global-settings
  local v; v="$(jget "$1" '.worktree.bgIsolation')"
  [ -n "$v" ] || v="$(jget "$2" '.worktree.bgIsolation')"
  [ -n "$v" ] || v="worktree (default — subagents gated)"
  echo "$v"
}

secret_scan() { # $@=files -> count + sample types
  local files=() ; for f in "$@"; do [ -f "$f" ] && files+=("$f"); done
  [ "${#files[@]}" -eq 0 ] && { echo "0"; return; }
  grep -cEo 'eyJ[A-Za-z0-9_-]{10,}|Basic [A-Za-z0-9+/=]{20,}|[A-Z0-9_]*_KEY=|[A-Z0-9_]*_SECRET=|SERVICE_ROLE|BEGIN [A-Z ]*PRIVATE KEY' "${files[@]}" 2>/dev/null \
    | awk -F: '{s+=$2} END{print s+0}'
}

mcp_enabled() { # $1=file
  jget "$1" '.enabledMcpjsonServers | join(", ")'
}

echo "=================================================================="
echo " Claude Code — permission posture audit"
echo " base: $BASE"
echo "=================================================================="
echo
# ---- global header ----
g="$HOME_CLAUDE/settings.json"; gl="$HOME_CLAUDE/settings.local.json"
echo "GLOBAL  ~/.claude/"
echo "  bash:        $(bash_posture "$g") (settings.json) / $(bash_posture "$gl") (settings.local.json)"
echo "  deny-net:    $(has_denynet "$g")/$(has_denynet "$gl") (settings / local)"
echo "  bgIsolation: $(bgiso "" "$g")"
gsec="$(secret_scan "$g" "$gl")"
echo "  secrets in settings files: ${gsec} flagged $( [ "$gsec" != "0" ] && echo '  <-- REMOVE & ROTATE' )"
echo
echo "------------------------------------------------------------------"
echo " PROJECT FOLDERS"
echo "------------------------------------------------------------------"

# Find candidate folders: dirs containing .git or .claude, excluding noise.
folders="$(
  {
    find "$BASE" -maxdepth 3 -type d -name .git 2>/dev/null
    find "$BASE" -maxdepth 3 -type d -name .claude 2>/dev/null
  } | sed -E 's#/\.(git|claude)$##' \
    | grep -vE '/node_modules/|/\.claude/worktrees/|/\.git/' \
    | grep -vxF "$HOME" \
    | grep -vxF "$HOME_CLAUDE" \
    | sort -u
)"

if [ -z "$folders" ]; then echo "  (no project folders found under $BASE)"; fi

while IFS= read -r d; do
  [ -z "$d" ] && continue
  ps="$d/.claude/settings.json"; pl="$d/.claude/settings.local.json"
  [ -f "$ps" ] || [ -f "$pl" ] || [ -d "$d/.git" ] || continue
  remote="$(git -C "$d" remote get-url origin 2>/dev/null)"; [ -z "$remote" ] && remote="(no git remote)"
  echo
  echo "~${d#$HOME}    repo: $remote"
  echo "  settings:    project $( [ -f "$ps" ] && echo OK || echo '-' )   local $( [ -f "$pl" ] && echo OK || echo '-' )"
  echo "  files:       $(file_posture "$d" "$ps" "$pl")"
  bp="$(bash_posture "$ps")"; blp="$(bash_posture "$pl")"
  echo "  bash:        project=$bp  local=$blp   deny-net: $(has_denynet "$ps")/$(has_denynet "$pl")"
  echo "  subagents:   bgIsolation = $(bgiso "$ps" "$g")"
  mcp="$(mcp_enabled "$ps")"; [ -z "$mcp" ] && mcp="$(mcp_enabled "$pl")"; [ -z "$mcp" ] && mcp="(none)"
  echo "  mcp enabled: $mcp"
  # credential hygiene
  sec="$(secret_scan "$ps" "$pl")"
  envwarn=""
  if [ -f "$d/.env" ] && git -C "$d" rev-parse >/dev/null 2>&1; then
    git -C "$d" check-ignore -q .env 2>/dev/null || envwarn="  .env NOT gitignored <-- fix"
  fi
  if [ "$sec" != "0" ] || [ -n "$envwarn" ]; then
    echo "  credentials: ${sec} secret(s) in settings$( [ "$sec" != "0" ] && echo ' <-- REMOVE & ROTATE')${envwarn}"
  else
    echo "  credentials: clean"
  fi
done <<< "$folders"

echo
echo "------------------------------------------------------------------"
echo " LEGEND  bash: none = every cmd prompts | specific = new cmds prompt | blanket = Bash(*) no prompts"
echo "         deny-net protects force-push/reset/rm even at blanket trust"
echo "         bgIsolation 'worktree' gates subagents; 'none' lets them write directly"
echo "------------------------------------------------------------------"
