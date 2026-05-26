# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Overview

CC CleanLine is a Bash-based status line for Claude Code. It reads the
statusline JSON Claude Code pipes on stdin, formats a 3- to 5-line
status line, and prints it to stdout. The whole thing is plain shell —
no Node, no Python, no daemon.

Two design choices drive the rest:

1. **Consume native JSON fields directly.** Anything Claude Code already
   exposes (`context_window.*`, `cost.total_cost_usd`,
   `rate_limits.five_hour.*`, `worktree.*`, `output_style.name`,
   `vim.mode`, `pr.*`, `effort.level`) is read straight from stdin —
   never recomputed from the `.jsonl` transcript or third-party tools.
2. **Adaptive output.** Lines 1–3 are always rendered. Lines 4
   (worktree) and 5 (style / vim / PR) appear only when the underlying
   fields are populated, so the status line stays quiet when there's
   nothing to say.

## Commands

```bash
./cc-cleanline.sh < tests/fixtures/opus-4-7-basic.json   # smoke test
bats --recursive tests/                                  # full bats suite
bats tests/unit/model-detection.bats                     # one suite
BATS_UPDATE_SNAPSHOTS=1 bats tests/integration/          # refresh snapshots
shellcheck **/*.sh                                       # static analysis
./happy-mode-tools.sh test                               # happy-mode bats wrapper
./happy-mode-tools.sh enable | disable                   # toggle easter eggs
```

For deterministic testing the script honours two env vars:

- `CC_CLEANLINE_MOCK_NOW=<unix-epoch>` — pins `date +%s` for the
  reset-countdown math.
- `CC_CLEANLINE_MOCK_HHMM=<HHMM>` — pins the wall-clock used by
  happy-mode time triggers.

## Architecture

```
cc-cleanline.sh            # orchestration: jq once, dispatch, print
cc-cleanline.config.sh     # defaults (overridable via .local file)

lib/                       # display modules
  git-status.sh            # branch + change counts
  model-detection.sh       # model.id pattern → display/icon/color
  context-display.sh       # token count + window %
  usage-tracking.sh        # cost + 5h rate-limit + reset countdown
  extras-display.sh        # worktree / output style / vim / PR
  display-formatter.sh     # adaptive 3-5 line composer
  happy-mode-integration.sh# bridge: caller-globals → engine ctx

happy-mode/                # easter eggs (opt-in)
  engine.sh                # cooldown, triggers, achievements
  rainbow.sh               # rainbow_text utility (also used by git-status)
  content/                 # *.txt files — editable without code changes

tests/                     # bats + fixtures + snapshots
  fixtures/*.json
  unit/*.bats
  happy-mode/*.bats
  integration/end-to-end.bats
  snapshots/*.txt
  helpers.bash
```

## Module contract

Every `lib/*.sh` formatter follows the same convention:

- Stateless function call with explicit arguments.
- Returns a single string of the form `text|color` on stdout. A blank
  string means "this segment has no data — skip it."
- No direct JSON parsing inside modules. `cc-cleanline.sh` parses once
  (one `jq` call into 19 line-based shell variables) and passes the
  values in.

`output_status_line` in `lib/display-formatter.sh` takes the rendered
segments in a fixed positional order and drops empty ones — that's the
whole adaptive-layout logic.

## Key implementation notes

- **Model-ID matching uses end-anchored case patterns** (`*opus-4-7`,
  not `*opus-4-7*`) after stripping `[1m]` and date suffixes. This
  prevents a future `opus-4-10` ID from falsely matching `opus-4-1`.
  See `lib/model-detection.sh` and its regression guards in
  `tests/unit/model-detection.bats`.
- **`[1m]` is a context-window suffix, not a separate model.** Strip
  it, set `is_1m`, render the `¹ᴹ` badge — but otherwise treat the
  model identically (same colour, same legacy status).
- **`jq` output is line-based, not TSV.** `IFS=$'\t' read -r` collapses
  consecutive tabs and silently shifts fields when one is empty
  (classic Bash gotcha). We use a `while IFS= read -r line; do
  fields+=("$line"); done` loop to preserve empty values.
- **`HAPPY_MODE` and friends use `${VAR:-default}` in
  `cc-cleanline.config.sh`** so env vars take precedence — important
  for tests, CI, and ad-hoc debugging.
- **macOS ships Bash 3.2** for licence reasons; the codebase avoids
  `mapfile`/`readarray` and other Bash-4-only features.

## Happy Mode

Off by default. When `HAPPY_MODE=true` (or `=test` for high-probability
debugging mode), `lib/happy-mode-integration.sh` collects caller globals
(`worktree_name`, `effort_level`, `exceeds_200k`, `rate_limit_5h_pct`,
`output_style_name`) and exports them as `HAPPY_CTX_*` env vars; the
engine matches them against achievement conditions defined declaratively
in `happy-mode/content/achievements.txt`.

State lives under `$XDG_CACHE_HOME/cc-cleanline/`:
- `cooldown` — Unix epoch of the last surprise (15-min default cooldown).
- `achievements` — list of earned achievement IDs (idempotent).

Adding new content does **not** require code changes:

- New quote → append a line to `happy-mode/content/matrix.txt` or
  `fortunes.txt`.
- New time trigger → append `HHMM|Message` to `time-triggers.txt`.
- New achievement → append `id|condition|message` to
  `achievements.txt`. Conditions handled today: `always`, `night_owl`,
  `in_worktree`, `effort_max`, `context_1m`, `long_session`,
  `plan_mode`. New conditions go in `_happy_check_condition` in
  `happy-mode/engine.sh`.

## Test-fixture conventions

Fixtures in `tests/fixtures/` use `MOCK_NOW = 1748269800`
(2026-05-26 14:30:00 UTC) as their "now"; `resets_at` values are
chosen relative to that timestamp so countdown tests are stable.

End-to-end snapshot tests run the script in an empty tmpdir (no git
repo) so the git segment renders the static "no git repository" string
and snapshots stay deterministic.

## Known limitations

- Bedrock/Vertex model IDs (`anthropic.claude-…`, `…@vertex`) are not
  in the pattern table yet. They fall through to the unknown-model
  case and render with `model.display_name`. Add cases as needed.
- Tags / branch-prefixed worktrees from non-Claude tooling aren't
  treated specially — the worktree line only renders when
  `worktree.name` is populated by Claude Code.
- Happy Mode's `git log --since='30 seconds ago'` commit detector
  requires that the cwd is inside a git repo at status-line execution
  time. In bare directories the trigger silently downgrades to the
  generic `status` context.
