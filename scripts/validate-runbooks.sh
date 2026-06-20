#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

python3 - "$ROOT_DIR" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
errors = []

required_sections = [
    "何时使用",
    "不适用",
    "输入证据",
    "执行流程",
    "必须调用的 skill",
    "验证命令",
    "常见失败",
    "停止条件",
    "可复用 Prompt",
]

allowed_risk = {"low", "medium", "high"}


def error(message):
    errors.append(message)


def parse_scalar(value):
    value = value.strip()
    if not value:
        return ""
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        return value[1:-1]
    return value


def parse_frontmatter(text, path):
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        error(f"{path}: missing frontmatter")
        return None
    end = None
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            end = index
            break
    if end is None:
        error(f"{path}: unterminated frontmatter")
        return None

    data = {}
    current_key = None
    for raw in lines[1:end]:
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("-"):
            if current_key is None:
                error(f"{path}: list item without key in frontmatter")
                continue
            item = stripped[1:].strip()
            data.setdefault(current_key, []).append(parse_scalar(item))
            continue
        if ":" not in raw:
            error(f"{path}: invalid frontmatter line: {raw}")
            continue
        key, value = raw.split(":", 1)
        key = key.strip()
        value = value.strip()
        if not key:
            error(f"{path}: empty frontmatter key")
            continue
        if value == "":
            data[key] = []
            current_key = key
        else:
            data[key] = parse_scalar(value)
            current_key = None
    return data


def check_trailing_whitespace(path):
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return
    for number, line in enumerate(text.splitlines(), start=1):
        if line.rstrip(" \t") != line:
            error(f"{path.relative_to(root)}:{number}: trailing whitespace")


def check_links(path, text):
    pattern = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
    for match in pattern.finditer(text):
        target = match.group(1).strip()
        if not target or target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        target = target.split("#", 1)[0]
        if not target:
            continue
        if re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", target):
            continue
        resolved = (path.parent / target).resolve()
        try:
            resolved.relative_to(root.resolve())
        except ValueError:
            error(f"{path.relative_to(root)}: link escapes repository: {target}")
            continue
        if not resolved.exists():
            error(f"{path.relative_to(root)}: missing relative link target: {target}")


for file_path in root.rglob("*"):
    if file_path.is_file() and ".git" not in file_path.parts:
        check_trailing_whitespace(file_path)

index_path = root / "runbooks" / "index.json"
try:
    entries = json.loads(index_path.read_text(encoding="utf-8"))
except Exception as exc:
    error(f"runbooks/index.json: cannot parse JSON: {exc}")
    entries = []

if not isinstance(entries, list):
    error("runbooks/index.json: root must be an array")
    entries = []

ids = set()
for position, entry in enumerate(entries):
    if not isinstance(entry, dict):
        error(f"runbooks/index.json[{position}]: entry must be an object")
        continue
    for key in ["id", "title", "path", "triggers", "owner_skills", "risk_level"]:
        if key not in entry:
            error(f"runbooks/index.json[{position}]: missing {key}")
    entry_id = entry.get("id")
    if entry_id in ids:
        error(f"runbooks/index.json: duplicate id {entry_id}")
    if isinstance(entry_id, str):
        ids.add(entry_id)
    if not isinstance(entry.get("triggers"), list) or not entry.get("triggers"):
        error(f"runbooks/index.json[{position}]: triggers must be a non-empty array")
    if not isinstance(entry.get("owner_skills"), list) or not entry.get("owner_skills"):
        error(f"runbooks/index.json[{position}]: owner_skills must be a non-empty array")
    if entry.get("risk_level") not in allowed_risk:
        error(f"runbooks/index.json[{position}]: risk_level must be low, medium, or high")

    rel_path = entry.get("path")
    if not isinstance(rel_path, str):
        continue
    md_path = root / rel_path
    if not md_path.exists():
        error(f"runbooks/index.json[{position}]: path does not exist: {rel_path}")
        continue
    text = md_path.read_text(encoding="utf-8")
    frontmatter = parse_frontmatter(text, md_path.relative_to(root))
    if frontmatter is None:
        continue
    for key in ["id", "title", "triggers", "owner_skills", "risk_level"]:
        if key not in frontmatter:
            error(f"{rel_path}: missing frontmatter field {key}")
    if frontmatter.get("id") != entry_id:
        error(f"{rel_path}: frontmatter id does not match index id {entry_id}")
    for key in ["triggers", "owner_skills"]:
        value = frontmatter.get(key)
        if not isinstance(value, list) or not value or any(not isinstance(item, str) or not item for item in value):
            error(f"{rel_path}: frontmatter {key} must be a non-empty array")
    if frontmatter.get("risk_level") not in allowed_risk:
        error(f"{rel_path}: frontmatter risk_level must be low, medium, or high")
    headings = set(re.findall(r"^##\s+(.+?)\s*$", text, flags=re.MULTILINE))
    for section in required_sections:
        if section not in headings:
            error(f"{rel_path}: missing section {section}")
    check_links(md_path, text)

for md_path in list((root / "docs").glob("*.md")) + list((root / "templates").glob("*.md")) + [root / "README.md"]:
    if md_path.exists():
        check_links(md_path, md_path.read_text(encoding="utf-8"))

if errors:
    for item in errors:
        print(f"ERROR: {item}")
    sys.exit(1)

print("OK")
PY
