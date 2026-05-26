#!/bin/bash
# Happy Mode engine for CC CleanLine.
# Loads content from happy-mode/content/*.txt, manages cooldown + achievement
# state under XDG cache, and exposes get_*/trigger_* primitives consumed by
# lib/happy-mode-integration.sh.

HAPPY_MODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HAPPY_MODE_CONTENT_DIR="${HAPPY_MODE_DIR}/content"

# ----- State directory --------------------------------------------------------

_happy_cache_dir() {
    local base="${XDG_CACHE_HOME:-$HOME/.cache}"
    local dir="${base}/cc-cleanline"
    [[ -d "$dir" ]] || mkdir -p "$dir" 2>/dev/null || true
    printf '%s' "$dir"
}

_happy_cooldown_file()    { printf '%s/cooldown'     "$(_happy_cache_dir)"; }
_happy_achievement_file() { printf '%s/achievements' "$(_happy_cache_dir)"; }

# ----- Mode helpers -----------------------------------------------------------

is_happy_mode_enabled() {
    [[ "${HAPPY_MODE:-false}" == "true" || "${HAPPY_MODE:-false}" == "test" ]]
}
is_happy_test_mode() { [[ "${HAPPY_MODE:-false}" == "test" ]]; }

# ----- Content loading --------------------------------------------------------
# Comments (#…) and blank lines are skipped.

_happy_load_lines() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    local line
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        printf '%s\n' "$line"
    done < "$file"
}

_happy_random_line() {
    # Pick one random line from a list passed via stdin.
    local lines=()
    local line
    while IFS= read -r line; do
        lines+=("$line")
    done
    local n=${#lines[@]}
    [[ "$n" -gt 0 ]] || return 1
    printf '%s' "${lines[$((RANDOM % n))]}"
}

get_matrix_quote()   { _happy_load_lines "${HAPPY_MODE_CONTENT_DIR}/matrix.txt"   | _happy_random_line; }
get_fortune_cookie() { _happy_load_lines "${HAPPY_MODE_CONTENT_DIR}/fortunes.txt" | _happy_random_line; }

# ----- Float-safe probability check ------------------------------------------
# hits_chance <percent>  — percent may be a float (0.5, 33, 100, etc.).
# Returns 0 on hit, 1 on miss. Scales to 10000 so sub-percent values work.
hits_chance() {
    local chance="${1:-0}"
    local scaled
    scaled=$(awk -v c="$chance" 'BEGIN {
        x = c * 100
        if (x < 0) x = 0
        if (x > 10000) x = 10000
        printf "%d", x
    }')
    (( RANDOM * 10000 / 32768 < scaled ))
}

# ----- Cooldown --------------------------------------------------------------

_happy_now() {
    if [[ -n "${CC_CLEANLINE_MOCK_NOW:-}" ]]; then
        printf '%s' "$CC_CLEANLINE_MOCK_NOW"
    else
        date +%s
    fi
}

check_cooldown() {
    # In test mode, always allow.
    is_happy_test_mode && return 0

    local file
    file=$(_happy_cooldown_file)
    [[ -f "$file" ]] || return 0

    local last current diff cooldown
    last=$(cat "$file" 2>/dev/null || echo 0)
    current=$(_happy_now)
    cooldown=$(( ${HAPPY_MODE_COOLDOWN_MINUTES:-15} * 60 ))
    diff=$(( current - last ))
    [[ "$diff" -gt "$cooldown" ]]
}

update_cooldown() {
    is_happy_test_mode && return 0
    _happy_now > "$(_happy_cooldown_file)"
}

# ----- Time / hour helpers ----------------------------------------------------

_happy_clock_hhmm() {
    if [[ -n "${CC_CLEANLINE_MOCK_HHMM:-}" ]]; then
        printf '%s' "$CC_CLEANLINE_MOCK_HHMM"
    else
        date +%H%M
    fi
}

_happy_clock_hour() {
    local hhmm
    hhmm=$(_happy_clock_hhmm)
    echo $((10#${hhmm:0:2}))
}

# Look up a time-triggered surprise for the current HHMM.
get_time_surprise() {
    [[ "${HAPPY_MODE_TIME_SURPRISES:-true}" == true ]] || return 0
    local now line trigger msg
    now=$(_happy_clock_hhmm)
    while IFS='|' read -r trigger msg; do
        if [[ "$trigger" == "$now" ]]; then
            printf '⏰ %s' "$msg"
            return 0
        fi
    done < <(_happy_load_lines "${HAPPY_MODE_CONTENT_DIR}/time-triggers.txt")
    # Generic late-night nudge between 02-05.
    local hour
    hour=$(_happy_clock_hour)
    if [[ "$hour" -ge 2 && "$hour" -le 5 ]] && hits_chance 10; then
        printf '🦉 Night owl detected. Code responsibly!'
    fi
}

# ----- Achievements -----------------------------------------------------------

_happy_has_achievement() {
    local id="$1"
    local file
    file=$(_happy_achievement_file)
    [[ -f "$file" ]] || return 1
    grep -Fxq "$id" "$file"
}

_happy_record_achievement() {
    local id="$1"
    local file
    file=$(_happy_achievement_file)
    _happy_has_achievement "$id" && return 1
    printf '%s\n' "$id" >> "$file"
}

# _happy_check_condition <condition>  — returns 0 if satisfied, 1 otherwise.
# Reads context from the env vars set by lib/happy-mode-integration.sh
# (HAPPY_CTX_WORKTREE_NAME, HAPPY_CTX_EFFORT, etc.) so the engine itself
# stays decoupled from the JSON shape.
_happy_check_condition() {
    case "$1" in
        always)     return 0 ;;
        night_owl)
            local h
            h=$(_happy_clock_hour)
            [[ "$h" -ge 2 && "$h" -le 5 ]]
            ;;
        in_worktree)    [[ -n "${HAPPY_CTX_WORKTREE_NAME:-}" ]] ;;
        effort_max)     [[ "${HAPPY_CTX_EFFORT:-}" == "max" ]] ;;
        context_1m)     [[ "${HAPPY_CTX_EXCEEDS_200K:-}" == "true" ]] ;;
        long_session)
            local pct="${HAPPY_CTX_RATE_LIMIT_PCT:-0}"
            awk -v p="$pct" 'BEGIN { exit (p > 80 ? 0 : 1) }'
            ;;
        plan_mode)      [[ "${HAPPY_CTX_OUTPUT_STYLE:-}" == "Plan" ]] ;;
        *)              return 1 ;;
    esac
}

# Scan achievements.txt and emit the first newly-earned achievement.
get_pending_achievement() {
    local file="${HAPPY_MODE_CONTENT_DIR}/achievements.txt"
    [[ -f "$file" ]] || return 0
    local id cond msg
    while IFS='|' read -r id cond msg; do
        _happy_has_achievement "$id" && continue
        _happy_check_condition "$cond" || continue
        _happy_record_achievement "$id"
        printf '%s' "$msg"
        return 0
    done < <(_happy_load_lines "$file")
}

# ----- Master trigger --------------------------------------------------------
# trigger_happy_mode <context>
#   context: "status" | "commit" | "git"
# Emits at most one easter egg per call. Honours cooldown unless in test mode.
trigger_happy_mode() {
    local context="${1:-status}"

    is_happy_mode_enabled || return 0
    check_cooldown || return 0

    local matrix_chance="${HAPPY_MODE_MATRIX_CHANCE:-33}"
    local fortune_chance="${HAPPY_MODE_FORTUNE_CHANCE:-33}"
    local rainbow_chance="${HAPPY_MODE_RAINBOW_CHANCE:-10}"
    local achievement_chance=100  # Always announce when earned.

    if is_happy_test_mode; then
        matrix_chance=75
        fortune_chance=75
        rainbow_chance=50
        echo "🧪 Happy Mode Test Active"
    fi

    local triggered=false

    # 1. Pending achievement always wins (one-shot, deterministic).
    if hits_chance "$achievement_chance"; then
        local ach
        ach=$(get_pending_achievement)
        if [[ -n "$ach" ]]; then
            echo "$ach"
            triggered=true
        fi
    fi

    # 2. Context-specific trigger.
    case "$context" in
        commit)
            if [[ "$triggered" != true ]] && hits_chance "$fortune_chance"; then
                local f
                f=$(get_fortune_cookie)
                [[ -n "$f" ]] && { echo "🥠 $f"; triggered=true; }
            fi
            ;;
        status|git)
            local ts
            ts=$(get_time_surprise)
            if [[ -n "$ts" ]]; then
                echo "$ts"
                triggered=true
            fi
            ;;
    esac

    # 3. Matrix quote — most common fallback.
    if [[ "$triggered" != true ]] && hits_chance "$matrix_chance"; then
        local m
        m=$(get_matrix_quote)
        [[ -n "$m" ]] && { echo "🐰 $m"; triggered=true; }
    fi

    # 4. Rainbow effect — rare, on top of everything.
    # Emojis are kept outside the rainbow_text() call because bash strings
    # are byte-indexed and a 4-byte emoji would be sliced per byte.
    if hits_chance "$rainbow_chance" && command -v rainbow_text >/dev/null 2>&1; then
        printf '🌈 '
        rainbow_text 'You found the rainbow mode!'
        printf ' 🌈\n'
        triggered=true
    fi

    if [[ "$triggered" == true ]] && ! is_happy_test_mode; then
        update_cooldown
    fi
}

# Convenience: rainbow-tint a branch name when happy mode is on.
generate_rainbow_branch() {
    local branch="$1"
    local chance="${HAPPY_MODE_RAINBOW_CHANCE:-10}"
    is_happy_test_mode && chance=30
    if is_happy_mode_enabled && hits_chance "$chance" && command -v rainbow_text >/dev/null 2>&1; then
        rainbow_text "$branch"
    else
        printf '%s' "$branch"
    fi
}

export -f is_happy_mode_enabled is_happy_test_mode 2>/dev/null || true
export -f hits_chance check_cooldown update_cooldown 2>/dev/null || true
export -f get_matrix_quote get_fortune_cookie get_time_surprise 2>/dev/null || true
export -f get_pending_achievement 2>/dev/null || true
export -f trigger_happy_mode generate_rainbow_branch 2>/dev/null || true
