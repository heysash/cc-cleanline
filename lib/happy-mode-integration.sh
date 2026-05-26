#!/bin/bash
# Happy-mode integration layer.
# Bridges the main statusline script and happy-mode/engine.sh: pulls context
# from the globals set in cc-cleanline.sh, exports them as HAPPY_CTX_* env
# vars (decoupling the engine from the JSON shape), classifies the context
# from observable signals (e.g. "did a commit just happen?"), and invokes
# trigger_happy_mode().

# trigger_happy_mode_context — called once at the end of cc-cleanline.sh.
# Relies on these globals being set by the caller (defensively defaulted):
#   worktree_name, effort_level, exceeds_200k, rate_limit_5h_pct,
#   output_style_name
trigger_happy_mode_context() {
    # Short-circuit when happy mode is off or the engine isn't sourced.
    if ! command -v trigger_happy_mode >/dev/null 2>&1; then
        return 0
    fi
    if [[ "${HAPPY_MODE:-false}" != "true" && "${HAPPY_MODE:-false}" != "test" ]]; then
        return 0
    fi

    # Publish context to the engine via env vars.
    export HAPPY_CTX_WORKTREE_NAME="${worktree_name:-}"
    export HAPPY_CTX_EFFORT="${effort_level:-}"
    export HAPPY_CTX_EXCEEDS_200K="${exceeds_200k:-false}"
    export HAPPY_CTX_RATE_LIMIT_PCT="${rate_limit_5h_pct:-0}"
    export HAPPY_CTX_OUTPUT_STYLE="${output_style_name:-}"

    # Classify the trigger context from observable signals.
    # Reliable commit detection: git log --since (a recent HEAD hash means
    # a commit was created in the last 30 seconds). The old `history 1`
    # check never worked in the non-interactive statusline shell.
    local context="status"
    if git rev-parse --git-dir >/dev/null 2>&1; then
        if [[ -n "$(git log -1 --since='30 seconds ago' --pretty=format:%H 2>/dev/null)" ]]; then
            context="commit"
        else
            context="git"
        fi
    fi

    trigger_happy_mode "$context"
}

export -f trigger_happy_mode_context 2>/dev/null || true
