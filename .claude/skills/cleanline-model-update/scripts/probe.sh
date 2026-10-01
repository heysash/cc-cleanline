#!/usr/bin/env bash
# Render get_model_info for one or more model IDs with the colour code
# visible, so tier changes (current / legacy / deprecated / fallback) can
# be checked before and after editing the case table.
# Usage: probe.sh <model-id> [<model-id> ...]
# Works from any cwd; the repo root is resolved from this script's path.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../../../.." && pwd)"

if [[ $# -eq 0 ]]; then
    echo "Usage: $(basename "$0") <model-id> [<model-id> ...]" >&2
    exit 64
fi

# shellcheck source=/dev/null
source "${repo_root}/cc-cleanline.config.sh"
# shellcheck source=/dev/null
source "${repo_root}/lib/model-detection.sh"
# Never let the rainbow easter egg rewrite the probe output.
HAPPY_MODE=false

# 'DISPLAY_NAME' makes a fallback hit obvious: "● DISPLAY_NAME|…".
for id in "$@"; do
    printf '%-45s -> %s\n' "$id" "$(get_model_info "$id" 'DISPLAY_NAME')"
done
