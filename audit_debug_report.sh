#!/usr/bin/env bash

# audit_debug_report.sh
# Simple, robust audit script that generates a real DEBUG_REPORT.md.
#
# What it does:
# - Captures ALL `swift build` output (stdout+stderr) into audit_log.txt
# - Parses common Swift compiler diagnostics (errors/warnings)
# - Categorizes findings (CRITICAL/HIGH/MEDIUM) with suggested fixes
# - Writes DEBUG_REPORT.md even when the build fails

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

DEBUG_REPORT_PATH="${DEBUG_REPORT_PATH:-DEBUG_REPORT.md}"
AUDIT_LOG_PATH="${AUDIT_LOG_PATH:-audit_log.txt}"

NOW_UTC="$(date -u "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date)"

swift_exists() {
  command -v swift >/dev/null 2>&1
}

git_available() {
  command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

stat_size() {
  local f="$1"
  if stat -f "%z" "$f" >/dev/null 2>&1; then
    stat -f "%z" "$f"
  else
    stat -c "%s" "$f" 2>/dev/null || echo "?"
  fi
}

stat_mtime() {
  local f="$1"
  if stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$f" >/dev/null 2>&1; then
    stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$f"
  else
    stat -c "%y" "$f" 2>/dev/null | cut -d'.' -f1 || echo "?"
  fi
}

append_file_as_fenced_code() {
  local file="$1"
  local lang="${2:-text}"

  printf "\n\n\`\`\`%s\n" "$lang"
  if [[ -f "$file" ]]; then
    cat "$file"
  else
    printf "(missing file: %s)\n" "$file"
  fi
  printf "\`\`\`\n"
}

# Environment info (never hard-fail)
SWIFT_VERSION="(swift not found)"
if swift_exists; then
  SWIFT_VERSION="$(swift --version 2>&1 || true)"
fi

UNAME_A="$(uname -a 2>/dev/null || true)"
PWD_NOW="$(pwd)"
GIT_STATUS=""
if git_available; then
  GIT_STATUS="$(git status -sb 2>/dev/null || true)"
fi

# Project structure check
STRUCTURE_FINDINGS=""
add_structure_finding() {
  STRUCTURE_FINDINGS+="$1"$'\n'
}

[[ -f "Package.swift" ]] && add_structure_finding "- [OK] Found: Package.swift" || add_structure_finding "- [MISSING] Package.swift"
[[ -d "Sources" ]] && add_structure_finding "- [OK] Found: Sources/" || add_structure_finding "- [MISSING] Sources/"
[[ -d "Tests" ]] && add_structure_finding "- [OK] Found: Tests/" || add_structure_finding "- [WARN] Missing: Tests/"

# List Swift files in Sources/
SWIFT_FILE_COUNT=0
SWIFT_FILES_TABLE=""
if [[ -d "Sources" ]]; then
  while IFS= read -r -d '' f; do
    SWIFT_FILE_COUNT=$((SWIFT_FILE_COUNT + 1))
    local_size="$(stat_size "$f")"
    local_mtime="$(stat_mtime "$f")"
    SWIFT_FILES_TABLE+="| \`$f\` | $local_size | $local_mtime |"$'\n'
  done < <(find "Sources" -type f -name "*.swift" -print0 2>/dev/null)
fi

# Run swift build and capture ALL output
BUILD_EXIT_CODE=127
: > "$AUDIT_LOG_PATH" 2>/dev/null || true

if swift_exists; then
  # Do not crash the script if the build fails.
  swift build 2>&1 | tee "$AUDIT_LOG_PATH" >/dev/null
  BUILD_EXIT_CODE=${PIPESTATUS[0]}
  {
    echo ""
    echo "[audit_debug_report] swift build exit code: $BUILD_EXIT_CODE"
  } >> "$AUDIT_LOG_PATH" 2>/dev/null || true
else
  echo "swift not found in PATH; cannot run swift build" | tee "$AUDIT_LOG_PATH" >/dev/null
  BUILD_EXIT_CODE=127
fi

# Issue parsing
# Supported patterns:
#   path/file.swift:line:col: error: message
#   path/file.swift:line:col: warning: message
#   path/file.swift:line: error: message
#   Package.swift:line:col: error: message
#   error: message
#   fatal error: message

declare -a CRITICAL_ISSUES
declare -a HIGH_ISSUES
declare -a MEDIUM_ISSUES

suggest_fix() {
  local msg="$1"

  if [[ "$msg" =~ ([Aa]ctor-isolated|actor-isolated) ]]; then
    echo "Make the caller async and use 'await', or move the call inside the same actor. If safe, mark the API 'nonisolated'."; return
  fi
  if [[ "$msg" =~ ([Mm]ain[[:space:]]actor-isolated|@MainActor|main[[:space:]]actor) ]]; then
    echo "Run on the main actor: mark the enclosing API '@MainActor' or wrap in 'Task { @MainActor in ... }'."; return
  fi
  if [[ "$msg" =~ ([Ss]endable|[Nn]on-sendable) ]]; then
    echo "Make the type 'Sendable' (preferred), or isolate behind an actor. Last resort: '@unchecked Sendable' with justification."; return
  fi
  if [[ "$msg" =~ (NSLock|os_unfair_lock) ]]; then
    echo "Avoid locks across 'await'. Prefer actors / isolation for mutable state, or restructure to keep locking strictly synchronous."; return
  fi
  if [[ "$msg" =~ (if_msghdr|if_msghdr2|NET_RT_IFLIST|sysctl) ]]; then
    echo "Update to SDK-compatible Darwin networking structs/APIs (e.g. prefer if_msghdr2/if_data64 patterns) and avoid deprecated layouts."; return
  fi
  if [[ "$msg" =~ (UInt32).*([Uu]Int64|UInt64) || "$msg" =~ (UInt64|Int64).*UInt32 ]]; then
    echo "Fix integer width mismatches by converting explicitly (e.g. 'UInt64(value32)') or standardize types across the boundary."; return
  fi
  if [[ "$msg" =~ ([Ff]ile[[:space:]]not[[:space:]]found|No such file or directory|could not find file) ]]; then
    echo "Fix the path (or remove the reference). For SwiftPM resources, verify resource paths in Package.swift."; return
  fi

  echo "(no specific suggestion)"
}

classify_severity() {
  local kind="$1" # error|warning
  local msg="$2"

  if [[ "$kind" == "error" ]]; then
    echo "CRITICAL"; return
  fi

  # warning
  if [[ "$msg" =~ ([Ff]ile[[:space:]]not[[:space:]]found|No such file or directory|could not find file) ]]; then
    echo "HIGH"; return
  fi
  if [[ "$msg" =~ (actor-isolated|Main[[:space:]]actor-isolated|Sendable|non-sendable|data race|concurrency|NSLock|if_msghdr|if_msghdr2) ]]; then
    echo "HIGH"; return
  fi

  echo "MEDIUM"
}

add_issue() {
  local severity="$1"
  local kind="$2"
  local file="$3"
  local line="$4"
  local col="$5"
  local msg="$6"
  local fix="$7"

  local record
  record="${kind}"$'\t'"${file}"$'\t'"${line}"$'\t'"${col}"$'\t'"${msg}"$'\t'"${fix}"

  case "$severity" in
    CRITICAL) CRITICAL_ISSUES+=("$record") ;;
    HIGH) HIGH_ISSUES+=("$record") ;;
    MEDIUM) MEDIUM_ISSUES+=("$record") ;;
    *) MEDIUM_ISSUES+=("$record") ;;
  esac
}

TOTAL_PARSED=0
if [[ -f "$AUDIT_LOG_PATH" ]]; then
  while IFS= read -r line; do
    if [[ "$line" =~ ^(.+\.swift):([0-9]+):([0-9]+):[[:space:]](error|warning):[[:space:]](.*)$ ]]; then
      file="${BASH_REMATCH[1]}"; ln="${BASH_REMATCH[2]}"; col="${BASH_REMATCH[3]}"; kind="${BASH_REMATCH[4]}"; msg="${BASH_REMATCH[5]}"
      severity="$(classify_severity "$kind" "$msg")"
      fix="$(suggest_fix "$msg")"
      add_issue "$severity" "$kind" "$file" "$ln" "$col" "$msg" "$fix"
      TOTAL_PARSED=$((TOTAL_PARSED + 1))
      continue
    fi

    if [[ "$line" =~ ^(.+\.swift):([0-9]+):[[:space:]](error|warning):[[:space:]](.*)$ ]]; then
      file="${BASH_REMATCH[1]}"; ln="${BASH_REMATCH[2]}"; col=""; kind="${BASH_REMATCH[3]}"; msg="${BASH_REMATCH[4]}"
      severity="$(classify_severity "$kind" "$msg")"
      fix="$(suggest_fix "$msg")"
      add_issue "$severity" "$kind" "$file" "$ln" "$col" "$msg" "$fix"
      TOTAL_PARSED=$((TOTAL_PARSED + 1))
      continue
    fi

    if [[ "$line" =~ ^Package\.swift:([0-9]+):([0-9]+):[[:space:]](error|warning):[[:space:]](.*)$ ]]; then
      file="Package.swift"; ln="${BASH_REMATCH[1]}"; col="${BASH_REMATCH[2]}"; kind="${BASH_REMATCH[3]}"; msg="${BASH_REMATCH[4]}"
      severity="$(classify_severity "$kind" "$msg")"
      fix="$(suggest_fix "$msg")"
      add_issue "$severity" "$kind" "$file" "$ln" "$col" "$msg" "$fix"
      TOTAL_PARSED=$((TOTAL_PARSED + 1))
      continue
    fi

    if [[ "$line" =~ ^(fatal[[:space:]]error|error):[[:space:]](.*)$ ]]; then
      kind="error"; file=""; ln=""; col=""; msg="${BASH_REMATCH[2]}"
      severity="CRITICAL"
      fix="$(suggest_fix "$msg")"
      add_issue "$severity" "$kind" "$file" "$ln" "$col" "$msg" "$fix"
      TOTAL_PARSED=$((TOTAL_PARSED + 1))
      continue
    fi
  done < "$AUDIT_LOG_PATH"
fi

critical_count=${#CRITICAL_ISSUES[@]}
high_count=${#HIGH_ISSUES[@]}
medium_count=${#MEDIUM_ISSUES[@]}

render_issues_section() {
  local title="$1"
  shift
  local -a arr=("$@")

  printf "## %s\n\n" "$title"

  if [[ ${#arr[@]} -eq 0 ]]; then
    printf "No issues detected in this category.\n\n"
    return
  fi

  local idx=0
  local rec
  for rec in "${arr[@]}"; do
    idx=$((idx + 1))

    local kind file ln col msg fix
    IFS=$'\t' read -r kind file ln col msg fix <<< "$rec"

    local loc="(no file)"
    if [[ -n "$file" && -n "$ln" ]]; then
      loc="\`$file:$ln\`"
    elif [[ -n "$file" ]]; then
      loc="\`$file\`"
    fi

    printf "### %s.%d %s\n\n" "$title" "$idx" "$loc"
    printf "- **Kind:** %s\n" "$kind"
    printf "- **Location:** %s\n" "$loc"
    if [[ -n "$col" ]]; then
      printf "- **Column:** %s\n" "$col"
    fi
    printf "- **Message:** %s\n" "$msg"
    printf "- **Exact fix needed:** %s\n\n" "$fix"
  done
}

# Write the report (always)
{
  printf "# DEBUG_REPORT.md (Generated)\n\n"
  printf "**Generated (UTC):** %s\n\n" "$NOW_UTC"

  printf "## Progress Tracker\n\n"
  printf "- [ ] Build succeeds (swift build)\n"
  printf "- [ ] CRITICAL issues fixed\n"
  printf "- [ ] HIGH issues fixed\n"
  printf "- [ ] Re-run audit and confirm clean\n\n"

  printf "## Environment Info\n\n"
  printf "- **pwd:** \`%s\`\n" "$PWD_NOW"
  printf "- **uname -a:** \`%s\`\n\n" "$UNAME_A"
  printf "### swift --version\n"
  printf "\n\`\`\`text\n%s\n\`\`\`\n\n" "$SWIFT_VERSION"
  if [[ -n "$GIT_STATUS" ]]; then
    printf "### git status\n"
    printf "\n\`\`\`text\n%s\n\`\`\`\n\n" "$GIT_STATUS"
  fi

  printf "## Project Structure Check\n\n"
  printf "%s\n" "$STRUCTURE_FINDINGS"

  printf "## Swift Files (Sources/)\n\n"
  printf "Found **%d** Swift files under \`Sources/\`.\n\n" "$SWIFT_FILE_COUNT"
  printf "| File | Size (bytes) | Modified |\n|---|---:|---|\n"
  if [[ -n "$SWIFT_FILES_TABLE" ]]; then
    printf "%s\n" "$SWIFT_FILES_TABLE"
  else
    printf "| (none found) | | |\n\n"
  fi

  printf "## Build\n\n"
  printf "- **Command:** \`swift build 2>&1\`\n"
  printf "- **Exit code:** \`%s\`\n\n" "$BUILD_EXIT_CODE"

  printf "## Issues Summary\n\n"
  printf "| Severity | Count |\n|---|---:|\n"
  printf "| CRITICAL | %d |\n" "$critical_count"
  printf "| HIGH | %d |\n" "$high_count"
  printf "| MEDIUM | %d |\n" "$medium_count"
  printf "| **Total Parsed** | **%d** |\n\n" "$((critical_count + high_count + medium_count))"

  render_issues_section "CRITICAL" "${CRITICAL_ISSUES[@]}"
  render_issues_section "HIGH" "${HIGH_ISSUES[@]}"
  render_issues_section "MEDIUM" "${MEDIUM_ISSUES[@]}"

  printf "## Raw Build Output (audit_log.txt)\n\n"
  printf "Complete captured output from 'swift build' (stdout + stderr).\n"
  append_file_as_fenced_code "$AUDIT_LOG_PATH" "text"

  printf "\n"
} > "$DEBUG_REPORT_PATH" 2>/dev/null || {
  echo "Failed to write $DEBUG_REPORT_PATH" >&2
  exit 2
}

# Console summary
printf "\n[audit_debug_report] Build exit code: %s\n" "$BUILD_EXIT_CODE"
printf "[audit_debug_report] Parsed issues: total=%d critical=%d high=%d medium=%d\n" "$((critical_count + high_count + medium_count))" "$critical_count" "$high_count" "$medium_count"
printf "[audit_debug_report] Wrote: %s\n" "$DEBUG_REPORT_PATH"
printf "[audit_debug_report] Wrote: %s\n\n" "$AUDIT_LOG_PATH"

exit 0
