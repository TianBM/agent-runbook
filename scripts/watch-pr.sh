#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  watch-pr.sh --repo OWNER/REPO --pr NUMBER --mode checks|merged [options]

Options:
  --repo OWNER/REPO        GitHub repository.
  --pr NUMBER             Pull request number.
  --mode checks|merged    Wait for checks to finish, or wait for mergedAt.
  --interval SECONDS      Poll interval. Default: 30.
  --after-merge COMMAND   Command to run after mergedAt is non-empty. Only valid with --mode merged.
  --timeout SECONDS       Maximum wait time. Default: 1800.
  -h, --help              Show this help.

This script reads PR state with gh pr view. It never merges a PR.
USAGE
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}

repo=""
pr=""
mode=""
interval="30"
after_merge=""
timeout="1800"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -ge 2 ]] || die "--repo requires OWNER/REPO"
      repo="$2"
      shift 2
      ;;
    --pr)
      [[ $# -ge 2 ]] || die "--pr requires NUMBER"
      pr="$2"
      shift 2
      ;;
    --mode)
      [[ $# -ge 2 ]] || die "--mode requires checks or merged"
      mode="$2"
      shift 2
      ;;
    --interval)
      [[ $# -ge 2 ]] || die "--interval requires SECONDS"
      interval="$2"
      shift 2
      ;;
    --after-merge)
      [[ $# -ge 2 ]] || die "--after-merge requires COMMAND"
      after_merge="$2"
      shift 2
      ;;
    --timeout)
      [[ $# -ge 2 ]] || die "--timeout requires SECONDS"
      timeout="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "$repo" ]] || die "missing --repo OWNER/REPO"
[[ -n "$pr" ]] || die "missing --pr NUMBER"
[[ -n "$mode" ]] || die "missing --mode checks|merged"
[[ "$repo" == */* ]] || die "--repo must be OWNER/REPO"
[[ "$pr" =~ ^[0-9]+$ ]] || die "--pr must be a number"
[[ "$mode" == "checks" || "$mode" == "merged" ]] || die "--mode must be checks or merged"
[[ "$interval" =~ ^[0-9]+$ && "$interval" -gt 0 ]] || die "--interval must be a positive integer"
[[ "$timeout" =~ ^[0-9]+$ && "$timeout" -gt 0 ]] || die "--timeout must be a positive integer"
if [[ -n "$after_merge" && "$mode" != "merged" ]]; then
  die "--after-merge is only valid with --mode merged"
fi

command -v gh >/dev/null 2>&1 || die "gh CLI is required"

deadline=$((SECONDS + timeout))
last_status=""

check_pr() {
  gh pr view "$pr" --repo "$repo" --json number,state,mergedAt,mergeStateStatus,statusCheckRollup
}

while true; do
  now=$SECONDS
  if (( now > deadline )); then
    printf 'timeout: repo=%s pr=%s mode=%s timeout=%ss\n' "$repo" "$pr" "$mode" "$timeout" >&2
    exit 124
  fi

  json="$(check_pr)"

  if [[ "$mode" == "merged" ]]; then
    merged_at="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("mergedAt") or "")' <<<"$json")"
    if [[ -n "$merged_at" ]]; then
      printf 'merged: repo=%s pr=%s mergedAt=%s\n' "$repo" "$pr" "$merged_at"
      if [[ -n "$after_merge" ]]; then
        printf 'after-merge: running command\n'
        bash -lc "$after_merge"
      fi
      exit 0
    fi
    status="waiting for merge"
  else
    summary="$(python3 -c '
import json
import sys

data = json.load(sys.stdin)
checks = data.get("statusCheckRollup") or []
pending_states = {"PENDING", "QUEUED", "IN_PROGRESS", "REQUESTED", "WAITING"}
failed_conclusions = {"FAILURE", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED", "STARTUP_FAILURE"}
running = 0
failed = []
passed = 0
unknown = 0

for item in checks:
    name = item.get("name") or item.get("context") or item.get("workflowName") or "check"
    state = (item.get("state") or item.get("status") or "").upper()
    conclusion = (item.get("conclusion") or "").upper()
    if state in pending_states or (state and not conclusion and state != "COMPLETED"):
        running += 1
    elif conclusion in failed_conclusions:
        failed.append(f"{name}:{conclusion.lower()}")
    elif conclusion in {"SUCCESS", "NEUTRAL", "SKIPPED"} or state == "SUCCESS":
        passed += 1
    elif not state and not conclusion:
        unknown += 1
    else:
        unknown += 1

if failed:
    print("failed|" + ",".join(failed))
elif running:
    print(f"running|{running} running/pending, {passed} passed, {unknown} unknown")
elif unknown:
    print(f"done|0 running/pending, {passed} passed, {unknown} unknown")
else:
    print(f"done|0 running/pending, {passed} passed, 0 unknown")
' <<<"$json")"
    result="${summary%%|*}"
    detail="${summary#*|}"
    if [[ "$result" == "failed" ]]; then
      printf 'checks failed: repo=%s pr=%s %s\n' "$repo" "$pr" "$detail" >&2
      exit 1
    fi
    if [[ "$result" == "done" ]]; then
      printf 'checks complete: repo=%s pr=%s %s\n' "$repo" "$pr" "$detail"
      exit 0
    fi
    status="$detail"
  fi

  if [[ "$status" != "$last_status" ]]; then
    printf 'waiting: repo=%s pr=%s mode=%s %s\n' "$repo" "$pr" "$mode" "$status"
    last_status="$status"
  fi

  remaining=$((deadline - SECONDS))
  if (( remaining <= 0 )); then
    continue
  fi
  if (( interval > remaining )); then
    sleep "$remaining"
  else
    sleep "$interval"
  fi
done
