#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/smoke-remote-runbooks.sh [--expect-local runbooks/index.json] <base-url>

Checks a deployed static agent-runbook site:
  - GET /runbooks/index.json
  - validate required index fields and allowed risk levels
  - HEAD each entry.path, falling back to GET if HEAD is not supported
  - optionally compare remote id/path set with a local runbooks/index.json

Examples:
  bash scripts/smoke-remote-runbooks.sh https://agent-runbook.example.vercel.app
  bash scripts/smoke-remote-runbooks.sh --expect-local runbooks/index.json https://agent-runbook.example.vercel.app
USAGE
}

EXPECT_LOCAL=""
BASE_URL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --expect-local)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --expect-local requires a path" >&2
        usage >&2
        exit 2
      fi
      EXPECT_LOCAL="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$BASE_URL" ]]; then
        echo "ERROR: unexpected extra argument: $1" >&2
        usage >&2
        exit 2
      fi
      BASE_URL="$1"
      shift
      ;;
  esac
done

if [[ -z "$BASE_URL" ]]; then
  echo "ERROR: base URL is required" >&2
  usage >&2
  exit 2
fi

BASE_URL="${BASE_URL%/}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

INDEX_FILE="$TMP_DIR/index.json"
PATHS_FILE="$TMP_DIR/paths.txt"

fetch() {
  local url="$1"
  local output="$2"
  curl --fail --silent --show-error --location --output "$output" "$url"
}

check_path() {
  local rel_path="$1"
  local url="$BASE_URL/$rel_path"
  if curl --fail --silent --show-error --location --head --output /dev/null "$url"; then
    return 0
  fi
  curl --fail --silent --show-error --location --output /dev/null "$url"
}

echo "Checking $BASE_URL/runbooks/index.json"
fetch "$BASE_URL/runbooks/index.json" "$INDEX_FILE"

python3 - "$INDEX_FILE" "$EXPECT_LOCAL" "$PATHS_FILE" <<'PY'
import json
import sys
from pathlib import Path

index_path = Path(sys.argv[1])
expect_local = sys.argv[2]
paths_path = Path(sys.argv[3])
allowed_risk = {"low", "medium", "high"}
required = ["id", "title", "path", "triggers", "owner_skills", "risk_level"]
errors = []


def load_json(path, label):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"{label}: cannot parse JSON: {exc}")
        return []


entries = load_json(index_path, "remote index")
if not isinstance(entries, list):
    errors.append("remote index: root must be an array")
    entries = []

seen_ids = set()
remote_pairs = set()
paths = []

for position, entry in enumerate(entries):
    if not isinstance(entry, dict):
        errors.append(f"remote index[{position}]: entry must be an object")
        continue
    for key in required:
        if key not in entry:
            errors.append(f"remote index[{position}]: missing {key}")
    entry_id = entry.get("id")
    title = entry.get("title")
    rel_path = entry.get("path")
    triggers = entry.get("triggers")
    owner_skills = entry.get("owner_skills")
    risk_level = entry.get("risk_level")

    if not isinstance(entry_id, str) or not entry_id:
        errors.append(f"remote index[{position}]: id must be a non-empty string")
    elif entry_id in seen_ids:
        errors.append(f"remote index: duplicate id {entry_id}")
    else:
        seen_ids.add(entry_id)

    if not isinstance(title, str) or not title:
        errors.append(f"remote index[{position}]: title must be a non-empty string")
    if not isinstance(rel_path, str) or not rel_path:
        errors.append(f"remote index[{position}]: path must be a non-empty string")
    elif rel_path.startswith(("/", "http://", "https://")) or ".." in Path(rel_path).parts:
        errors.append(f"remote index[{position}]: path must be a safe relative path: {rel_path}")
    else:
        paths.append(rel_path)
    if not isinstance(triggers, list) or not triggers or any(not isinstance(item, str) or not item for item in triggers):
        errors.append(f"remote index[{position}]: triggers must be a non-empty string array")
    if not isinstance(owner_skills, list) or not owner_skills or any(not isinstance(item, str) or not item for item in owner_skills):
        errors.append(f"remote index[{position}]: owner_skills must be a non-empty string array")
    if risk_level not in allowed_risk:
        errors.append(f"remote index[{position}]: risk_level must be low, medium, or high")
    if isinstance(entry_id, str) and isinstance(rel_path, str):
        remote_pairs.add((entry_id, rel_path))

if expect_local:
    local_entries = load_json(expect_local, "local index")
    if isinstance(local_entries, list):
        local_pairs = {
            (entry.get("id"), entry.get("path"))
            for entry in local_entries
            if isinstance(entry, dict)
        }
        if remote_pairs != local_pairs:
            missing = sorted(local_pairs - remote_pairs)
            extra = sorted(remote_pairs - local_pairs)
            if missing:
                errors.append(f"remote index missing local id/path pairs: {missing}")
            if extra:
                errors.append(f"remote index has unexpected id/path pairs: {extra}")
    else:
        errors.append("local index: root must be an array")

if errors:
    for item in errors:
        print(f"ERROR: {item}", file=sys.stderr)
    sys.exit(1)

paths_path.write_text("\n".join(paths) + ("\n" if paths else ""), encoding="utf-8")
print(f"OK: remote index contains {len(paths)} runbook path(s)")
PY

while IFS= read -r rel_path; do
  [[ -z "$rel_path" ]] && continue
  echo "Checking $BASE_URL/$rel_path"
  check_path "$rel_path"
done < "$PATHS_FILE"

echo "OK: remote runbooks are reachable"
