#!/usr/bin/env bash
# Clone a statusline fixture for a new model ID. Uses sed, not jq, so the
# numbers and formatting stay byte-identical (jq would print 2.10 as 2.1).
# Replaces model.id, session_id (fresh UUID) and the transcript_path.
# Usage: clone-fixture.sh <template-name> <new-name> <new-model-id>
#   e.g. clone-fixture.sh opus-5-5-basic opus-6-basic claude-opus-6
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fixtures="$(cd "${script_dir}/../../../.." && pwd)/tests/fixtures"

if [[ $# -ne 3 ]]; then
    echo "Usage: $(basename "$0") <template-name> <new-name> <new-model-id>" >&2
    exit 64
fi

template="${fixtures}/$1.json"
target="${fixtures}/$2.json"
new_name="$2"
new_id="$3"

if [[ ! -f "$template" ]]; then
    echo "Template not found: $template" >&2
    exit 1
fi
if [[ -e "$target" ]]; then
    echo "Target already exists: $target" >&2
    exit 1
fi

old_id=$(jq -r '.model.id' "$template")

# Escape a literal for the pattern side / the replacement side of sed.
re_escape() { printf '%s' "$1" | sed -e 's/[]\/$*.^[]/\\&/g'; }
rep_escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }

session_id=""
if command -v uuidgen >/dev/null 2>&1; then
    session_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
fi

sed_args=(
    -e "s/\"id\": \"$(re_escape "$old_id")\"/\"id\": \"$(rep_escape "$new_id")\"/"
    -e "s/\"transcript_path\": \"[^\"]*\"/\"transcript_path\": \"\\/tmp\\/test-$(rep_escape "$new_name").jsonl\"/"
)
if [[ -n "$session_id" ]]; then
    sed_args+=(-e "s/\"session_id\": \"[^\"]*\"/\"session_id\": \"${session_id}\"/")
fi

sed "${sed_args[@]}" "$template" > "$target"

# Refuse a half-baked clone: the new ID must have landed in model.id.
if ! jq -e --arg id "$new_id" '.model.id == $id' "$target" >/dev/null; then
    rm -f "$target"
    echo "model.id replacement failed for $target" >&2
    exit 1
fi

echo "Created tests/fixtures/${new_name}.json (model.id=${new_id}, from $1)"
