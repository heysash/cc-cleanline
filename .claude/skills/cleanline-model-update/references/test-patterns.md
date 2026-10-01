# Test patterns for model updates

## Placeholders

| Placeholder | Meaning | Example |
| --- | --- | --- |
| `<id>` | API ID from the overview page | `claude-opus-6` |
| `<dated-id>` | dated ID as listed on the deprecations page | `claude-sonnet-4-5-20250929` |
| `<bedrock-id>` | Bedrock ID from the overview table | `anthropic.claude-opus-6` |
| `<Name>` | display name in the case entry | `Opus 6` |
| `<Family>` | family, also used as the `display_name` argument | `Opus` |
| `<family>` | family as it appears in IDs | `opus` |
| `<FAMILY>` | colour variable suffix | `OPUS` |
| `<icon>` | family icon | `★` |
| `<Successor>` | display name of the successor | `Opus 6.5` |
| `<maj>`, `<min>` | version parts of the ID | `6`, `5` |

The unit tests live in `tests/unit/model-detection.bats`, in this block
order:

1. current
2. legacy
3. deprecated
4. retired/fallback
5. effort
6. guards

The tier blocks check the status; the guards check only the display name and
thus the matching mechanics.

## Current

Every new headline model gets a test. The new Opus additionally gets the
`[1m]` variant and the Bedrock ID.

```bash
@test "get_model_info: <Name> → '<icon> <Name>|<color>' (current <Family>)" {
    result=$(get_model_info '<id>')
    assert_contains "$result" '<icon> <Name>'
    assert_not_contains "$result" 'legacy'
}

@test "get_model_info: <Name> with [1m] → adds ¹ᴹ badge" {
    result=$(get_model_info '<id>[1m]')
    assert_contains "$result" '<icon> <Name> ¹ᴹ'
    assert_not_contains "$result" 'legacy'
}

@test "get_model_info: <Name> Bedrock ID → provider prefix ignored by end-anchoring" {
    result=$(get_model_info '<bedrock-id>')
    assert_contains "$result" '<icon> <Name>'
    assert_not_contains "$result" 'legacy'
}
```

The Bedrock test moves along with the current Opus: adapt the existing test
instead of adding a second one. Never construct the Bedrock ID yourself.

## Legacy (demoted by a successor)

Move the previous current test into the legacy block and invert the
expectation. A `[1m]` variant keeps its badge next to the marker.

```bash
@test "get_model_info: <Name> → legacy marker (demoted by <Successor>)" {
    result=$(get_model_info '<id>')
    assert_contains "$result" '<icon> <Name>'
    assert_contains "$result" 'legacy'
}
```

## Deprecated

Colour is the only thing that sets deprecated apart from legacy: the marker
is the same and snapshots strip ANSI codes. The test therefore checks the
colour, guarded against an empty variable — otherwise `"|${COLOR_DEPRECATED}"`
collapses to `"|"`, which matches every result.

```bash
# --- get_model_info: deprecated models ----------------------------------------

@test "get_model_info: <Name> → deprecated colour + legacy marker" {
    # Deprecated <YYYY-MM-DD>, retires <YYYY-MM-DD>: still served, so the
    # entry stays, but it renders in COLOR_DEPRECATED.
    [ -n "$COLOR_DEPRECATED" ]
    result=$(get_model_info '<dated-id>')
    assert_contains "$result" '<icon> <Name>'
    assert_contains "$result" 'legacy'
    assert_contains "$result" "|${COLOR_DEPRECATED}"
    assert_not_contains "$result" "|${COLOR_<FAMILY>_LEGACY}"
}
```

Once no deprecated model is left, drop the whole block including its header.
Header lines are always exactly 80 characters wide.

## Retired (fallback)

The case entry is gone; the ID renders via the `display_name` fallback.
Delete the model's legacy and deprecated tests.

```bash
@test "get_model_info: retired <Name> → fallback (case entry removed)" {
    # Anthropic retired <Name> on <YYYY-MM-DD>; the dedicated case entry
    # is gone, so the ID renders via the display_name fallback instead.
    result=$(get_model_info '<dated-id>' '<Family>')
    assert_contains "$result" '●'
    assert_not_contains "$result" '<icon>'
}
```

## Guards

Guards are **status-independent**. They check only icon and display name. A
guard with `assert_not_contains 'legacy'` or a colour breaks at the next
demotion.

### Own entry instead of major-only (substring trap)

`'Opus 5.5'` contains `'Opus 5'`. A guard of the form
`assert_not_contains "$result" 'Opus 5'` for a *hypothetical* `opus-5-5`
breaks as soon as that model ships. At that point it becomes an own-entry
guard:

```bash
@test "guard: <family>-<maj>-<min> is matched by its own entry, never the major-only *<family>-<maj>" {
    result=$(get_model_info 'claude-<family>-<maj>-<min>')
    assert_contains "$result" '<icon> <Name>'
}
```

### Hypothetical -N0 IDs

Every new pattern gets a guard against the ID extended by a zero. These
guards stay valid permanently.

```bash
@test "guard: <family>-<maj>-<min> case does NOT swallow a hypothetical <family>-<maj>-<min>0" {
    result=$(get_model_info 'claude-<family>-<maj>-<min>0')
    assert_not_contains "$result" '<Name>'
}
```

### Digit swap

When two mapped IDs differ in a single digit (`sonnet-4-5` and `sonnet-5-5`),
a guard checks that the older one never renders as the newer one. Once the
older one retires, the expectation `'Sonnet 4.5'` is wrong, because the ID
then lands in the fallback. Reduce the guard to
`assert_not_contains "$result" 'Sonnet 5'` at that point.

### New major-only pattern (`*<family>-<maj>`)

For the future minor release, assert the fallback rather than the absence of
the name. Otherwise the substring trap snaps shut as soon as the minor
release ships.

```bash
@test "guard: <family>-<maj> case does NOT swallow a hypothetical <family>-<maj>-5" {
    result=$(get_model_info 'claude-<family>-<maj>-5')
    assert_contains "$result" '●'
}
```

When the minor release ships, this guard becomes an own-entry guard.

## Effort tests

The three effort tests always use the **current** Opus ID. The expectation
then reads `'<Name> ★★☆☆'`.

## E2E snapshot test (`tests/integration/end-to-end.bats`)

Place new current fixtures at the top of the current-snapshot block, directly
after `run_snapshot()`:

```bash
@test "snapshot: <fixture-name>" {
    require_jq
    run_snapshot <fixture-name>
}
```

## Snapshot prediction

Before the run with the update flag, count which snapshots must fail. The
run without the flag must report exactly that number.

| Change | Effect on snapshots |
| --- | --- |
| new model with a new fixture | snapshot missing → 1 failure each |
| current → legacy | model line gains ` ⚠legacy` → 1 failure per fixture of the model |
| current → deprecated | model line gains ` ⚠legacy` → 1 failure per fixture of the model |
| legacy → deprecated | **no** visible change (ANSI stripped, same marker) |
| context fixture moved to a new ID | model name changes → 1 failure each |
| → retired | fixture, snapshot and `@test` are deleted or moved with `git mv` (see SKILL.md, Phase 4) |

After `BATS_UPDATE_SNAPSHOTS=1 bats tests/integration/`,
`git diff -U0 -- tests/snapshots` shows exactly one changed line per modified
file: the model line (line 2). New snapshots are untracked, so read
`git status --short -- tests/snapshots` as well.
