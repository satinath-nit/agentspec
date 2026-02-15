#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="agentspec"
PASS=0
FAIL=0
TOTAL=0
TMPDIR=$(mktemp -d)

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

pass() {
  PASS=$((PASS + 1))
  TOTAL=$((TOTAL + 1))
  echo "  PASS: $1"
}

fail() {
  FAIL=$((FAIL + 1))
  TOTAL=$((TOTAL + 1))
  echo "  FAIL: $1"
}

echo "=== AgentSpec CLI Integration Test Suite ==="
echo ""

echo "--- Help/Usage Tests ---"

output=$($CLI --help 2>&1 || true)
if echo "$output" | grep -qi "agentspec"; then
  pass "CLI --help shows agentspec info"
else
  fail "CLI --help does not show agentspec info"
fi

if echo "$output" | grep -q "new-agent"; then
  pass "CLI --help mentions new-agent command"
else
  fail "CLI --help missing new-agent command"
fi

if echo "$output" | grep -q "new-skill"; then
  pass "CLI --help mentions new-skill command"
else
  fail "CLI --help missing new-skill command"
fi

if echo "$output" | grep -q "init"; then
  pass "CLI --help mentions init command"
else
  fail "CLI --help missing init command"
fi

if echo "$output" | grep -q "validate"; then
  pass "CLI --help mentions validate command"
else
  fail "CLI --help missing validate command"
fi

echo ""
echo "--- Init Command Tests (with --ide copilot) ---"

TEST_PROJECT="$TMPDIR/test-copilot"
$CLI init "$TEST_PROJECT" --ide copilot --non-interactive 2>&1 || true

if [ -d "$TEST_PROJECT" ]; then
  pass "init creates project directory"
else
  fail "init did not create project directory"
fi

if [ -f "$TEST_PROJECT/AGENTS.md" ]; then
  pass "init creates AGENTS.md"
else
  fail "init did not create AGENTS.md"
fi

if [ -d "$TEST_PROJECT/agents" ]; then
  pass "init creates agents/ directory"
else
  fail "init did not create agents/ directory"
fi

if [ -d "$TEST_PROJECT/skills" ]; then
  pass "init creates skills/ directory"
else
  fail "init did not create skills/ directory"
fi

if [ -f "$TEST_PROJECT/.gitignore" ]; then
  pass "init creates .gitignore"
else
  fail "init did not create .gitignore"
fi

if [ -f "$TEST_PROJECT/.env.example" ]; then
  pass "init creates .env.example"
else
  fail "init did not create .env.example"
fi

if [ -f "$TEST_PROJECT/.github/copilot-instructions.md" ]; then
  pass "init --ide copilot creates .github/copilot-instructions.md"
else
  fail "init --ide copilot did not create copilot config"
fi

if [ -f "$TEST_PROJECT/.vscode/settings.json" ]; then
  pass "init creates .vscode/settings.json"
else
  fail "init did not create .vscode/settings.json"
fi

if [ -f "$TEST_PROJECT/.vscode/tasks.json" ]; then
  pass "init creates .vscode/tasks.json"
else
  fail "init did not create .vscode/tasks.json"
fi

echo ""
echo "--- Init IDE-Specific Config Tests ---"

TEST_CLAUDE="$TMPDIR/test-claude"
$CLI init "$TEST_CLAUDE" --ide claude --non-interactive 2>&1 || true
if [ -f "$TEST_CLAUDE/CLAUDE.md" ]; then
  pass "init --ide claude creates CLAUDE.md"
else
  fail "init --ide claude did not create CLAUDE.md"
fi

TEST_CURSOR="$TMPDIR/test-cursor"
$CLI init "$TEST_CURSOR" --ide cursor-agent --non-interactive 2>&1 || true
if [ -f "$TEST_CURSOR/.cursor/rules/agentspec.md" ]; then
  pass "init --ide cursor-agent creates .cursor/rules/agentspec.md"
else
  fail "init --ide cursor-agent did not create cursor config"
fi

TEST_WINDSURF="$TMPDIR/test-windsurf"
$CLI init "$TEST_WINDSURF" --ide windsurf --non-interactive 2>&1 || true
if [ -f "$TEST_WINDSURF/.windsurf/rules/agentspec.md" ]; then
  pass "init --ide windsurf creates .windsurf/rules/agentspec.md"
else
  fail "init --ide windsurf did not create windsurf config"
fi

TEST_GEMINI="$TMPDIR/test-gemini"
$CLI init "$TEST_GEMINI" --ide gemini --non-interactive 2>&1 || true
if [ -f "$TEST_GEMINI/.gemini/settings.json" ]; then
  pass "init --ide gemini creates .gemini/settings.json"
else
  fail "init --ide gemini did not create gemini config"
fi

TEST_CODEX="$TMPDIR/test-codex"
$CLI init "$TEST_CODEX" --ide codex --non-interactive 2>&1 || true
if [ -f "$TEST_CODEX/.codex/instructions.md" ]; then
  pass "init --ide codex creates .codex/instructions.md"
else
  fail "init --ide codex did not create codex config"
fi

TEST_DEVIN="$TMPDIR/test-devin"
$CLI init "$TEST_DEVIN" --ide devin --non-interactive 2>&1 || true
if [ -f "$TEST_DEVIN/.devin/instructions.md" ]; then
  pass "init --ide devin creates .devin/instructions.md"
else
  fail "init --ide devin did not create devin config"
fi

TEST_ROO="$TMPDIR/test-roo"
$CLI init "$TEST_ROO" --ide roo --non-interactive 2>&1 || true
if [ -f "$TEST_ROO/.roo" ]; then
  pass "init --ide roo creates .roo"
else
  fail "init --ide roo did not create roo config"
fi

TEST_Q="$TMPDIR/test-q"
$CLI init "$TEST_Q" --ide q --non-interactive 2>&1 || true
if [ -f "$TEST_Q/.q" ]; then
  pass "init --ide q creates .q"
else
  fail "init --ide q did not create q config"
fi

echo ""
echo "--- Init Banner/TUI Tests ---"

output=$($CLI init "$TMPDIR/test-banner" --ide copilot --non-interactive 2>&1 || true)
if echo "$output" | grep -qi "agentspec\|Agent.*Toolkit"; then
  pass "init shows banner/title"
else
  fail "init does not show banner"
fi

if echo "$output" | grep -qi "project.*setup\|project"; then
  pass "init shows project setup summary"
else
  fail "init does not show project setup summary"
fi

if echo "$output" | grep -qi "copilot"; then
  pass "init shows selected IDE"
else
  fail "init does not show selected IDE"
fi

if echo "$output" | grep -qi "setup complete\|initialized"; then
  pass "init shows completion message"
else
  fail "init does not show completion message"
fi

if echo "$output" | grep -q "new-agent\|new-skill"; then
  pass "init shows next steps"
else
  fail "init does not show next steps"
fi

echo ""
echo "--- List Command Tests ---"

output=$($CLI list --project-dir "$PROJECT_ROOT" 2>&1 || true)
if echo "$output" | grep -qi "agent"; then
  pass "list command shows agents"
else
  fail "list command does not show agents"
fi

echo ""
echo "--- Validate Command Tests ---"

output=$($CLI validate --project-dir "$PROJECT_ROOT" 2>&1 || true)
if echo "$output" | grep -qi "valid\|pass"; then
  pass "validate command runs on valid project"
else
  fail "validate command did not report valid project"
fi

echo ""
echo "--- New Agent (Non-Interactive) Tests ---"

$CLI new-agent --name "test-agent" --description "A test agent" --project-dir "$PROJECT_ROOT" --non-interactive 2>&1 || true
if [ -f "$PROJECT_ROOT/agents/test-agent/agent.yaml" ]; then
  pass "new-agent creates agent.yaml"
  if grep -q "name: test-agent" "$PROJECT_ROOT/agents/test-agent/agent.yaml"; then
    pass "new-agent sets correct name"
  else
    fail "new-agent did not set correct name"
  fi
  rm -rf "$PROJECT_ROOT/agents/test-agent"
else
  fail "new-agent did not create agent directory"
fi

echo ""
echo "--- New Skill (Non-Interactive) Tests ---"

$CLI new-skill --name "test-skill" --description "A test skill" --project-dir "$PROJECT_ROOT" --non-interactive 2>&1 || true
if [ -f "$PROJECT_ROOT/skills/test-skill/skill.yaml" ]; then
  pass "new-skill creates skill.yaml"
  if grep -q "name: test-skill" "$PROJECT_ROOT/skills/test-skill/skill.yaml"; then
    pass "new-skill sets correct name"
  else
    fail "new-skill did not set correct name"
  fi
  rm -rf "$PROJECT_ROOT/skills/test-skill"
else
  fail "new-skill did not create skill directory"
fi

echo ""
echo "=== Results ==="
echo "Total: $TOTAL | Passed: $PASS | Failed: $FAIL"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "SOME TESTS FAILED"
  exit 1
else
  echo "ALL TESTS PASSED"
  exit 0
fi
