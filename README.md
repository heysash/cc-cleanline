<p align="center">
  <img src="assets/cover.png" alt="CC CleanLine — a modern status line for Claude Code" width="100%">
</p>

```
   ____ ____    ____ _                 _     _
  / ___/ ___|  / ___| | ___  __ _ _ __ | |   (_)_ __   ___
 | |  | |     | |   | |/ _ \/ _` | '_ \| |   | | '_ \ / _ \
 | |__| |___  | |___| |  __/ (_| | | | | |___| | | | |  __/
  \____\____|  \____|_|\___|\__,_|_| |_|_____|_|_| |_|\___|
```

# CC CleanLine — a modern status line for Claude Code

A modular, opinionated status line for Claude Code that surfaces the
information you actually need — model, context, rate-limit, cost, plus
adaptive Worktree / Output-Style / Vim / PR rows — without visual noise.

Rewritten in 2026 to consume Claude Code's native statusline JSON fields
directly (`context_window.*`, `cost.*`, `rate_limits.*`, `worktree.*`,
`output_style.*`, `vim.*`, `pr.*`, `effort.level`) and to recognise the
current model line-up: **Opus 4.7** (incl. `[1m]` context), **Sonnet 4.6**,
**Haiku 4.5**, plus legacy markers for everything older.

## What the status line looks like

The core is always three lines; lines 4 and 5 appear only when the
underlying data is present.

```
● git branch main (+15/-3) ▶ ./cc-cleanline
★ Opus 4.7 ¹ᴹ ★★★★ 142.3k · 14.2% (1M) ⏱ Reset 2h 43m
  ● 5h Limit: Medium · $1.23 session
🌿 worktree: curious-feature ▸ branch: claude/curious-feature
⚙ style: Explanatory · vim: INSERT · PR #42 ⚠ changes_requested
```

- **Line 1** — git status + cwd
- **Line 2** — model (icon, name, `¹ᴹ` if 1M context, 4-star effort meter) + token usage + reset countdown
- **Line 3** — 5h rate-limit bucket + session cost
- **Line 4** *(optional)* — worktree name + branch when inside a Claude Code worktree
- **Line 5** *(optional)* — output style + Vim mode + PR number/state, in any combination

## Install

Requires `bash`, `jq`, and (optionally) `git`. macOS + Linux supported.

```bash
git clone https://github.com/<your-fork>/cc-cleanline.git ~/.cc-cleanline
chmod +x ~/.cc-cleanline/cc-cleanline.sh
```

Then point Claude Code at it in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.cc-cleanline/cc-cleanline.sh",
    "padding": 1,
    "refreshInterval": 5
  }
}
```

Restart Claude Code (or `/exit`) and the status line will appear.

## Model support

| Pattern (`model.id`)           | Display       | Marker  | Notes                                  |
| ------------------------------ | ------------- | ------- | -------------------------------------- |
| `claude-opus-4-7`              | `★ Opus 4.7`  |         | current                                |
| `claude-opus-4-7[1m]`          | `★ Opus 4.7 ¹ᴹ` | `¹ᴹ`  | 1M context window                      |
| `claude-opus-4-6`              | `★ Opus 4.6`  | legacy  | dimmed colour                          |
| `claude-opus-4-5`              | `★ Opus 4.5`  | legacy  |                                        |
| `claude-opus-4-1-…`            | `★ Opus 4.1`  | legacy  | date-suffixed IDs auto-normalised      |
| `claude-opus-4-…`              | `★ Opus 4`    | deprecated | retiring in 2026                    |
| `claude-sonnet-4-6`            | `☆ Sonnet 4.6`|         | current                                |
| `claude-sonnet-4-5-…`          | `☆ Sonnet 4.5`| legacy  |                                        |
| `claude-sonnet-4-…`            | `☆ Sonnet 4`  | deprecated |                                     |
| `claude-haiku-4-5-…`           | `✧ Haiku 4.5` |         | current; sky-blue                      |
| `claude-haiku-3-5-…`           | `✧ Haiku 3.5` | legacy  |                                        |
| anything else                  | `● <name>`    |         | falls back to `model.display_name`     |

The effort badge appended to the model name is a 4-star meter
(constant width, filled stars = level — scannable without counting):

| `effort.level` | Badge      |
| -------------- | ---------- |
| `low`          | `☆☆☆☆`     |
| `medium`       | `★☆☆☆`     |
| `high`         | `★★☆☆`     |
| `xhigh`        | `★★★☆`     |
| `max`          | `★★★★`     |

## Configuration

Two files:
- `cc-cleanline.config.sh` — defaults, tracked in git.
- `cc-cleanline.config.local` — your personal overrides, git-ignored.
  Copy `cc-cleanline.config.example` to get started.

Toggles most users care about:

| Variable                       | Default | Effect                                              |
| ------------------------------ | ------- | --------------------------------------------------- |
| `SHOW_FULL_PATH`               | `false` | `false` → `./dirname`, `true` → full absolute path  |
| `SHOW_TOKEN_ABSOLUTE`          | `true`  | `50.0k` in the context segment                      |
| `SHOW_TOKEN_PERCENT_TOTAL`     | `true`  | `25.0%` in the context segment                      |
| `SHOW_EFFORT_BADGE`            | `true`  | Append `··· / ▸max` next to the model name          |
| `SHOW_1M_BADGE`                | `true`  | Append `¹ᴹ` for `[1m]` variants                     |
| `SHOW_LEGACY_MARKER`           | `true`  | Append `⚠legacy` for deprecated models              |
| `SHOW_WORKTREE_LINE`           | `true`  | Render line 4 when in a Claude Code worktree        |
| `SHOW_EXTRAS_LINE`             | `true`  | Render line 5 (style / vim / PR)                    |
| `SHOW_VERSION`                 | `false` | Append `v2.1.150` to line 5                         |
| `HAPPY_MODE`                   | `false` | `true`/`test` — see Happy Mode below                |

## Happy Mode

Optional easter eggs (Matrix references, fortune cookies, time-based
surprises, achievements). Off by default. To enable interactively:

```bash
./happy-mode-tools.sh enable
./happy-mode-tools.sh test       # run the bats suite
./happy-mode-tools.sh disable
```

Triggers, cooldown, and content live under `happy-mode/`:

- `happy-mode/engine.sh` — float-safe `hits_chance`, cooldown (under
  `$XDG_CACHE_HOME/cc-cleanline/cooldown`), trigger registry.
- `happy-mode/rainbow.sh` — isolated `rainbow_text` utility.
- `happy-mode/content/*.txt` — quotes, time triggers, achievements.
  Drop your own lines into any of these files; lines starting with `#`
  and blank lines are ignored.

Cooldown defaults to 15 minutes between surprises so they stay subtle.

## Testing & development

```bash
brew install bats-core shellcheck jq      # macOS
sudo apt install bats shellcheck jq       # Debian/Ubuntu

bats --recursive tests/                   # full suite
shellcheck **/*.sh                        # static analysis
```

Snapshot updates after intentional formatting changes:

```bash
BATS_UPDATE_SNAPSHOTS=1 bats tests/integration/
```

The CI workflow (`.github/workflows/ci.yml`) runs shellcheck and bats on
both Ubuntu and macOS for every push and PR.

## Architecture

```
cc-cleanline.sh                  # orchestration: parse JSON once, render
cc-cleanline.config.sh           # defaults
cc-cleanline.config.local        # your overrides (gitignored)
lib/
  git-status.sh                  # git branch + change counts
  model-detection.sh             # model.id pattern matching
  context-display.sh             # token count + window %
  usage-tracking.sh              # cost + 5h rate-limit + reset countdown
  extras-display.sh              # worktree / style / vim / PR
  display-formatter.sh           # adaptive 3-5 line composer
  happy-mode-integration.sh      # bridge to happy-mode engine
happy-mode/
  engine.sh                      # core: cooldown, triggers, achievements
  rainbow.sh                     # ANSI rainbow utility
  content/                       # *.txt content files
tests/
  fixtures/*.json                # realistic Claude Code stdin samples
  unit/*.bats                    # per-module unit tests
  happy-mode/*.bats              # engine/integration/achievements
  integration/end-to-end.bats    # full-pipeline snapshots
  snapshots/*.txt                # rendered output baselines
  helpers.bash                   # shared assertions + snapshot infra
```

Each `lib/*.sh` module returns `text|color` on stdout; the formatter
stitches them together. No external commands beyond `jq`, `git`, `awk`,
`sed`, `date` — and only what's already on every developer machine.

## Migration from the pre-2026 version

If you used a previous version of cc-cleanline:

- `lib/context-metrics.sh` and `lib/cost-tracking.sh` are **gone**.
  The data they computed via JSONL parsing and `ccusage` is now read
  straight from the statusline JSON.
- Your `cc-cleanline.config.local` may reference variables that no
  longer exist (`SHOW_TOKEN_PERCENT_USABLE`, `SHOW_API_COSTS`,
  `SHOW_API_COSTS_WHEN_INCLUDED`, `CONTEXT_METRICS_CACHE_TTL`,
  `SHOW_MODEL_NAME`). They're harmless — just unused.
- Model names display correctly now (the old version showed every
  Opus as "Opus 4.1" and every Sonnet as "Sonnet 4").
- `ccusage` is no longer required.
- Happy Mode state moved from `/tmp/.cc-happy-*` to
  `$XDG_CACHE_HOME/cc-cleanline/`.

## License

MIT — see `LICENSE`.
