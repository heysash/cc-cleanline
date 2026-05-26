#!/usr/bin/env bats
# Unit tests for lib/extras-display.sh — worktree line + adaptive extras line.

load '../helpers.bash'

setup() {
    source_module "lib/extras-display.sh"
}

# --- format_worktree_line -----------------------------------------------------

@test "worktree line: name + branch → full rendering" {
    result=$(format_worktree_line 'curious-feature' 'claude/curious-feature')
    assert_contains "$result" '🌿 worktree: curious-feature'
    assert_contains "$result" '▸ branch: claude/curious-feature'
}

@test "worktree line: name only (no branch) → no branch part" {
    result=$(format_worktree_line 'curious-feature' '')
    assert_contains "$result" '🌿 worktree: curious-feature'
    assert_not_contains "$result" '▸ branch'
}

@test "worktree line: empty name → empty output" {
    [ -z "$(format_worktree_line '' '')" ]
}

@test "worktree line: null name → empty output" {
    [ -z "$(format_worktree_line 'null' 'main')" ]
}

@test "worktree line: SHOW_WORKTREE_LINE=false → empty output" {
    SHOW_WORKTREE_LINE=false
    [ -z "$(format_worktree_line 'curious-feature' 'main')" ]
}

# --- format_extras_line -------------------------------------------------------

@test "extras: output_style only → 'style: Explanatory'" {
    result=$(format_extras_line 'Explanatory' '' '' '')
    assert_contains "$result" '⚙ style: Explanatory'
    assert_not_contains "$result" 'vim'
    assert_not_contains "$result" 'PR'
}

@test "extras: vim mode only → 'vim: INSERT'" {
    result=$(format_extras_line '' 'INSERT' '' '')
    assert_contains "$result" 'vim: INSERT'
    assert_not_contains "$result" 'style'
}

@test "extras: PR only with approved → '✓ approved'" {
    result=$(format_extras_line '' '' '42' 'approved')
    assert_contains "$result" 'PR #42'
    assert_contains "$result" '✓ approved'
}

@test "extras: PR only with changes_requested → '⚠ changes_requested'" {
    result=$(format_extras_line '' '' '42' 'changes_requested')
    assert_contains "$result" 'PR #42'
    assert_contains "$result" '⚠ changes_requested'
}

@test "extras: PR number without state → bare PR text" {
    result=$(format_extras_line '' '' '42' '')
    assert_contains "$result" 'PR #42'
    assert_not_contains "$result" '⚠'
}

@test "extras: 'default' output_style counts as empty" {
    [ -z "$(format_extras_line 'default' '' '' '')" ]
}

@test "extras: 'null' values count as empty" {
    [ -z "$(format_extras_line 'null' 'null' 'null' 'null')" ]
}

@test "extras: SHOW_EXTRAS_LINE=false → always empty" {
    SHOW_EXTRAS_LINE=false
    [ -z "$(format_extras_line 'Explanatory' 'INSERT' '42' 'approved')" ]
}

@test "extras: multiple fields joined with ' · '" {
    result=$(format_extras_line 'Explanatory' 'INSERT' '42' 'approved')
    assert_contains "$result" 'style: Explanatory · vim: INSERT · PR #42'
}

@test "extras: SHOW_VERSION=true appends version" {
    SHOW_VERSION=true
    result=$(format_extras_line 'Explanatory' '' '' '' '2.1.150')
    assert_contains "$result" '· v2.1.150'
}

@test "extras: SHOW_VERSION default false → no version even when given" {
    result=$(format_extras_line 'Explanatory' '' '' '' '2.1.150')
    assert_not_contains "$result" 'v2.1.150'
}

# --- integration via fixtures -------------------------------------------------

@test "fixture with-worktree: produces a worktree line" {
    require_jq
    name=$(jq -r '.worktree.name // ""' tests/fixtures/with-worktree.json)
    branch=$(jq -r '.worktree.branch // ""' tests/fixtures/with-worktree.json)
    result=$(format_worktree_line "$name" "$branch")
    assert_contains "$result" 'curious-feature-abc123'
    assert_contains "$result" 'claude/curious-feature-abc123'
}

@test "fixture opus-4-7-basic: no worktree → empty worktree line" {
    require_jq
    name=$(jq -r '.worktree.name // ""' tests/fixtures/opus-4-7-basic.json)
    branch=$(jq -r '.worktree.branch // ""' tests/fixtures/opus-4-7-basic.json)
    [ -z "$(format_worktree_line "$name" "$branch")" ]
}

@test "fixture with-pr-context: extras line includes PR #42 changes_requested" {
    require_jq
    style=$(jq -r '.output_style.name // ""' tests/fixtures/with-pr-context.json)
    vim=$(jq -r '.vim.mode // ""' tests/fixtures/with-pr-context.json)
    pr_num=$(jq -r '.pr.number // ""' tests/fixtures/with-pr-context.json)
    pr_state=$(jq -r '.pr.review_state // ""' tests/fixtures/with-pr-context.json)
    result=$(format_extras_line "$style" "$vim" "$pr_num" "$pr_state")
    assert_contains "$result" 'PR #42'
    assert_contains "$result" 'changes_requested'
}

@test "fixture opus-4-7-basic: no extras → empty extras line" {
    require_jq
    style=$(jq -r '.output_style.name // ""' tests/fixtures/opus-4-7-basic.json)
    vim=$(jq -r '.vim.mode // ""' tests/fixtures/opus-4-7-basic.json)
    pr_num=$(jq -r '.pr.number // ""' tests/fixtures/opus-4-7-basic.json)
    pr_state=$(jq -r '.pr.review_state // ""' tests/fixtures/opus-4-7-basic.json)
    [ -z "$(format_extras_line "$style" "$vim" "$pr_num" "$pr_state")" ]
}
