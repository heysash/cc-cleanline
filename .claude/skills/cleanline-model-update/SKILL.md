---
name: cleanline-model-update
description: >
  Brings the CC CleanLine status line's model line-up up to date, end to end:
  add new Claude models (the user names a model or ID; with none named, run a
  lifecycle check only), demote predecessors to legacy, flag deprecated models
  and remove retired ones. Includes the live check against Anthropic's docs,
  unit tests, fixtures, snapshots, docs, verification, commit and push of the
  feature branch.
  Triggers: new Claude model, add Opus/Sonnet/Haiku/Fable X.Y, model update,
  update model line-up, check legacy models, model deprecated, model retired.
  Also on: "Anthropic released Opus 6", "Are the old models still available?".
  Do NOT trigger for: merging to main, work on model-detection.sh that does
  not change the line-up (badges, ID parsing), other segments, Happy Mode.
  RULE: lifecycle status comes only from Anthropic's live pages. RULE: never
  work in the main checkout. RULE: no merge without the maintainer's go-ahead.
---

# cleanline-model-update: keep CC CleanLine's model line-up current

> Every model change at Anthropic triggers the same set of changes in
> CC CleanLine:
>
> - case table and colours
> - unit tests and guards
> - fixtures and snapshots
> - README, CLAUDE.md and the config example
>
> This skill turns that into a reproducible run that can go unattended. The
> user supplies only the new models, or nothing at all.

Reference runs:

- `e003355`: Opus 5.5 and Sonnet 5.5, Sonnet 4.5 deprecated
- `097d374`: Opus 5 and Fable 5.1, retirements

`git show --stat <sha>` lists every file each run touched. Test patterns live
in `references/test-patterns.md`.

## Scope

| Situation | This skill? | Instead |
| --- | --- | --- |
| Add new models, demote their predecessors | ✅ | – |
| Apply a deprecation or retirement (no new models) | ✅ | – |
| ID parsing or badges in `model-detection.sh` without a line-up change | ❌ | regular work (example: `63c6b97`) |
| Merge the branch into main | ❌ | the maintainer's merge workflow, only after their go-ahead |

## Autonomy rules

| Situation | Response |
| --- | --- |
| New models of known families, status on the live pages unambiguous | run the whole procedure, report at the end |
| A live page lists a headline model that has no case entry and the user did not name | add it like a named one, highlight it in the report |
| Model deprecated | set the deprecated tier, no question asked |
| Model retired | remove the entry, point its tests at the fallback, no question asked |
| Lifecycle check finds no change | no branch, no commit, report only |
| WebFetch fails or does not return the status table | **STOP**: change nothing, report |
| A named model appears on neither live page | **STOP**: report it, never invent an ID |
| New model family (unknown name, no icon, no colour) | **STOP**: propose an icon and colour, ask once |
| Snapshot failures or diffs differ from the prediction | **STOP**: present the discrepancy |
| No clean place to work, or the baseline is red | halt and explain the situation |

## Tiers

| Anthropic status | Tier | Case entry | Colour | Marker |
| --- | --- | --- | --- | --- |
| Active, headline model of its family (comparison table in the models overview) | current | yes | `COLOR_<FAMILY>` | – |
| Active, listed under "Legacy models (still available)" | legacy | yes | `COLOR_<FAMILY>_LEGACY` | `⚠legacy` |
| Deprecated (retirement date announced) | deprecated | yes | `COLOR_DEPRECATED` | `⚠legacy` |
| Retired | retired | **no**, fallback | `COLOR_DEFAULT_MODEL` | – |

| Family | Icon | Colours |
| --- | --- | --- |
| Fable | `✦` | `COLOR_FABLE`, `COLOR_FABLE_LEGACY` |
| Opus | `★` | `COLOR_OPUS`, `COLOR_OPUS_LEGACY` |
| Sonnet | `☆` | `COLOR_SONNET`, `COLOR_SONNET_LEGACY` |
| Haiku | `✧` | `COLOR_HAIKU`, `COLOR_HAIKU_LEGACY` |
| unknown / retired | `●` | `COLOR_DEFAULT_MODEL` |

Settled special cases:

- **"Retirement not sooner than <date>"** is a minimum guarantee, not a
  deprecation. The model keeps its tier.
- **Mythos** (`claude-mythos-*`, Project Glasswing only) stays unmapped on
  purpose. A guard test enforces this.
- **`COLOR_DEPRECATED` and `COLOR_<FAMILY>_LEGACY` stay defined** even while no
  model uses them. They are part of the palette and can be overridden in
  `.local`. `COLOR_HAIKU_LEGACY` is the precedent.

## Phase 0: Research (live, read-only)

1. **Date** for docs and the commit:
   `TZ='Europe/Berlin' date "+%Y-%m-%d %H:%M:%S %Z"`.
2. Fetch both pages with WebFetch and have the tables extracted verbatim:
   - Status and dates:
     `https://platform.claude.com/docs/en/about-claude/model-deprecations.md`
     (the "Model status" table and the "Deprecation history" section)
   - Line-up: `https://platform.claude.com/docs/en/about-claude/models/overview.md`
     (the comparison table with API, Bedrock and Vertex AI IDs, plus the
     "Legacy models" list)

   If a fetch fails or the status table is missing: **STOP**.
3. **IDs** come from these pages only, Bedrock and Vertex AI IDs included.
   Resolve a name ("Opus 6") there. Never construct an ID.
4. **Read the base branch's case table**, e.g. with
   `git show origin/main:lib/model-detection.sh`.
5. **Build the reconciliation table.** One row per case entry and per new
   model: Anthropic status, current tier, new tier, date.

   **No change:** report and stop. No branch and no commit, not even for the
   "last checked" date.

## Phase 1: Workspace and preflight

**Never work in the main checkout** (the clone the status line runs from).
Two reasons:

- `statusLine` in `~/.claude/settings.json` usually points into it. Any
  half-finished edit or branch switch takes effect immediately in every
  running Claude Code session.
- A `cc-cleanline.config.local` there may set `HAPPY_MODE="true"`. It is
  sourced after the environment variables, so snapshots and smoke tests show
  random easter eggs.

Choose the workspace like this:

1. If the session already runs in its own worktree (path contains
   `/.claude/worktrees/`, feature branch, clean working tree), work there.
2. Otherwise create a worktree. The base is `origin/main` unless the task says
   otherwise:

   ```bash
   REPO=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
   D=$(TZ='Europe/Berlin' date +%Y%m%d)
   git -C "$REPO" fetch origin
   git -C "$REPO" worktree add -b "claude/model-update-$D" \
     "$REPO/.claude/worktrees/model-update-$D" origin/main
   ```

3. Preflight in the workspace:
   - `git status` is clean.
   - `cc-cleanline.config.local` does **not** exist.
   - `bats`, `shellcheck` and `jq` are installed.
   - `bats --recursive tests/` passes. Note the test count from
     `bats --count --recursive tests/`.
4. **Baseline probe:** `.claude/skills/cleanline-model-update/scripts/probe.sh <id> …`.
   New IDs typically render as `● DISPLAY_NAME`.

## Phase 2: Case table and colours (`lib/model-detection.sh`)

- **Patterns are end-anchored** (`*opus-6`, never `*opus-6*`). A major-only ID
  (`claude-opus-6`) gets `*opus-6`, a minor release gets `*opus-6-5`.
- **Current** goes first in its family. The predecessor switches to
  `$COLOR_<FAMILY>_LEGACY` and gets `is_legacy=true`.
- **Deprecated:** `color="$COLOR_DEPRECATED"; is_legacy=true`.
- **Retired:** delete the line and add the model with its date to the
  "Retired models (…)" list in the comment above the `case`.
- **Keep the comment block above the `case` current:**
  - the sentence on deprecated models with their retirement date (drop it
    once none is left)
  - the Haiku guarantee
  - the retired list
- Align the columns with the existing entries. Run `probe.sh` again
  afterwards.
- **New family** (after the STOP and the user's answer): add `COLOR_<FAMILY>`
  and `COLOR_<FAMILY>_LEGACY` to `cc-cleanline.config.sh`, plus matching lines
  in `cc-cleanline.config.example` and the README.

## Phase 3: Unit tests (`tests/unit/model-detection.bats`)

Checklist; patterns in `references/test-patterns.md`:

- **current block:** one test per new headline model. The new Opus also gets
  `[1m]` and the Bedrock ID from the overview page.
- **Demoted models:** move the test into the legacy block and add
  "(demoted by …)".
- **Deprecated:** a block that checks the colour, guarded against an empty
  variable.
- **Retired:** add a fallback test, delete the model's old tests.
- **Guards are status-independent:** they check only the display name and
  icon. The tier blocks check the status. It follows that:
  - a hypothetical guard whose model becomes real turns into an own-entry
    guard (substring trap);
  - every new pattern gets a `-N0` guard;
  - digit-swap guards are added or adjusted. Once the older ID retires,
    reduce its expectation to `assert_not_contains '<new name>'`.
- **Effort tests** move to the current Opus ID.
- Get `bats tests/unit/model-detection.bats` green. Every `# --- …` header
  line is exactly 80 characters wide.

## Phase 4: Fixtures and snapshots

1. **New fixtures** come from the helper
   `.claude/skills/cleanline-model-update/scripts/clone-fixture.sh <template> <new> <id>`.
   It edits with sed, so numbers and formatting stay byte-identical.
   - New Opus: `<name>-basic` from the previous `*-basic`, and
     `<name>-1m-context` from the previous `*-1m-context` (ID with `[1m]`).
   - Otherwise one fixture per model, cloned from its family predecessor.
2. **Move the context fixtures** to the current IDs so the extras snapshots
   stay free of legacy noise:
   - `high-rate-limit`, `max-effort`, `with-output-style`, `with-pr-context`
     and `with-worktree` get the current Opus
   - `with-vim-mode` gets the current Sonnet

   Use `perl -pi -e 's/"<old>"/"<new>"/' tests/fixtures/<file>.json`.
3. **Retired: search for references first, then delete.**
   `grep -rn -e '<fixture-name>' -e '<model-id>' --exclude-dir=.git .`
   Fixtures are also read by unit tests (`usage-tracking.bats`,
   `extras-display.bats`), by `happy-mode-tools.sh` and by the docs.
   - Repoint references to an **equivalent** fixture. Equivalent means this
     comparison shows no difference:

     ```bash
     diff <(jq -S 'del(.model, .session_id, .transcript_path)' tests/fixtures/<a>.json) \
          <(jq -S 'del(.model, .session_id, .transcript_path)' tests/fixtures/<b>.json)
     ```

     Then delete the model's fixture, snapshot and `@test`.
   - Without an equivalent fixture, move it with `git mv` to a model that is
     still served (new ID, new name), as with
     `legacy-opus-4-1` → `legacy-opus-4-5` in `097d374`.
4. **`tests/integration/end-to-end.bats`:** put the `@test` blocks for new
   fixtures at the top of the current-snapshot block, directly after
   `run_snapshot()`.
5. **Predict** how many snapshots must fail (table in
   `references/test-patterns.md`). Then run
   `bats tests/integration/end-to-end.bats` without the flag. The number of
   `not ok` lines must match exactly.
6. **Regenerate:** `BATS_UPDATE_SNAPSHOTS=1 bats tests/integration/`.
7. **Review** with `git status --short -- tests/snapshots` and
   `git diff -U0 -- tests/snapshots`. Each file changes only its model line,
   exactly as predicted. Finish with another run without the flag.

## Phase 5: Docs

**`README.md`:**

- The intro sentence with the current line-up ("current model line-up: …").
- The example line under "What the status line looks like" with the current
  Opus.
- The "Model support" table: family by family, current first.
  - Notes: `current`, for legacy `dimmed colour`
  - Deprecated: `deprecated: dark grey; retires <YYYY-MM-DD>`
  - Minimum guarantees: `no retirement before <YYYY-MM-DD>`
- The paragraphs below it: which model is deprecated and when it retires,
  the retired list with dates, and the line "Lifecycle states follow
  Anthropic's model deprecations page (last checked <YYYY-MM-DD>)" with
  today's date.
- Replace example IDs of retired models, e.g. in the paragraph on provider
  IDs.

**`CLAUDE.md`:**

- The smoke-test line under "Commands" points at the current Opus `*-basic`
  fixture.
- Replace example IDs of retired models, e.g. under "Known limitations".
- Touch the end-anchoring note only if its example IDs changed status.

**`cc-cleanline.config.example`:** only for new colour variables.

## Phase 6: Verification

1. `bats --recursive tests/` reports baseline plus added minus deleted
   tests, with no failures.
2. Both shellcheck runs are clean:
   - `shellcheck $(git ls-files '*.sh' '*.bash')`
   - `shellcheck -S warning cc-cleanline.config.example`
3. Smoke test with visible colour codes, leaving no temp directory behind:

   ```bash
   root=$(git rev-parse --show-toplevel); d=$(mktemp -d)
   (cd "$d" && CC_CLEANLINE_MOCK_NOW=1748269800 HAPPY_MODE=false \
     "$root/cc-cleanline.sh" < "$root/tests/fixtures/<current>-basic.json") | cat -v
   rm -rf "$d"
   ```

4. Run `probe.sh` over every entry of the reconciliation table. Each line
   must show the new tier.
5. Skim `git diff --stat` for anything outside the plan.

## Phase 7: Commit, push, report

- **Commit message:** write it to a file in the scratchpad with a quoted
  heredoc and pass it with `git commit -F`, never inline with `-m`.
  - Subject (~72 characters), e.g.
    `✨ feat: add Opus 6 and Sonnet 6, flag Sonnet 5.5 as deprecated`
  - Body in the style of `e003355`:
    - NEW, Demote, Deprecated, Retired
    - Fixtures/Snapshots, Docs
    - `Tests <old> → <new>, shellcheck clean`
- **Incidental fixes** get their own commits (`📝 docs`, `🐛 fix`).
- **Push:** `git push -u origin <branch>`. No merge, and no PR unless asked.
  Merging into `main` happens only after the maintainer's go-ahead. Keep the
  worktree until then.
- **Report** in the user's language:
  - reconciliation table (old → new)
  - test count before and after
  - commits
  - upcoming dates: retirement dates of deprecated models and
    "not sooner than" guarantees within the next 60 days

  For these dates, offer a scheduled follow-up check
  (`mcp__scheduled-tasks__create_scheduled_task`, one-off via `fireAt`).
  Create it only with the user's consent.

## Pitfalls from earlier runs

- **Stale skill cache:** the `claude-api` skill's `models.md` still listed
  Opus 4.1 as deprecated after it had retired, and did not know about the
  Sonnet 4.5 deprecation. Only the live pages count.
- **Main checkout:** it feeds the live status line, and its `.local` may force
  Happy Mode. Always work in a worktree.
- **Substring trap:** "Opus 5.5" contains "Opus 5". Hypothetical guards break
  as soon as the model becomes real.
- **Status-dependent guards:** a guard that asserts `not legacy` or a colour
  breaks at the next demotion. Guards check only name and icon.
- **Empty colour variable:** `"|${VAR}"` becomes `"|"`, which always matches.
  Hence the preceding `[ -n "$VAR" ]`.
- **Invisible deprecation:** snapshots strip ANSI codes and the marker stays
  `⚠legacy`. Only the unit test sees the colour.
- **Context segment:** the token display inherits the model colour, so a new
  model colour changes both segments.
- **Shared fixtures:** unit tests read values from fixtures. Delete only after
  the reference search and the equivalence check.
- **Order within the `case`:** irrelevant for correctness; end-anchoring keeps
  `*opus-5` apart from `opus-5-5`.
- **Provider IDs:**
  - `strip_model_suffixes` removes `-YYYYMMDD` and Vertex AI `@YYYYMMDD`.
  - Dateless Bedrock IDs (`anthropic.…`, `us.`/`global.`) match directly.
  - Bedrock IDs with `-v1:0` fall through (documented in `CLAUDE.md`).
- **jq rewrites numbers** (`2.10` → `2.1`). Only touch fixtures through
  `clone-fixture.sh` or sed/perl.
- **shellcheck glob:** without globstar, bash's `**/*.sh` misses the
  top-level scripts. Always use `git ls-files`.
