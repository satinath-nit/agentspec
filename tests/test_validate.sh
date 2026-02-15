#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS=0
FAIL=0
TOTAL=0

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

echo "=== AgentSpec Test Suite ==="
echo ""

echo "--- Structure Tests ---"

if [ -f "$PROJECT_ROOT/AGENTS.md" ]; then
  pass "AGENTS.md exists at project root"
else
  fail "AGENTS.md missing at project root"
fi

if [ -f "$PROJECT_ROOT/README.md" ]; then
  pass "README.md exists at project root"
else
  fail "README.md missing at project root"
fi

if [ -f "$PROJECT_ROOT/Taskfile.yml" ]; then
  pass "Taskfile.yml exists at project root"
else
  fail "Taskfile.yml missing at project root"
fi

if [ -d "$PROJECT_ROOT/agents" ]; then
  pass "agents/ directory exists"
else
  fail "agents/ directory missing"
fi

if [ -d "$PROJECT_ROOT/skills" ]; then
  pass "skills/ directory exists"
else
  fail "skills/ directory missing"
fi

if [ -d "$PROJECT_ROOT/templates" ]; then
  pass "templates/ directory exists"
else
  fail "templates/ directory missing"
fi

if [ -d "$PROJECT_ROOT/prompts" ]; then
  pass "prompts/ directory exists"
else
  fail "prompts/ directory missing"
fi

echo ""
echo "--- Agent Config Tests ---"

for agent_dir in "$PROJECT_ROOT/agents"/*/; do
  agent_name=$(basename "$agent_dir")
  if [ -f "$agent_dir/agent.yaml" ]; then
    pass "Agent '$agent_name' has agent.yaml"
  else
    fail "Agent '$agent_name' missing agent.yaml"
  fi

  if [ -f "$agent_dir/prompt.md" ]; then
    pass "Agent '$agent_name' has prompt.md"
  else
    fail "Agent '$agent_name' missing prompt.md"
  fi

  yaml_file="$agent_dir/agent.yaml"
  for field in name description version; do
    if grep -q "^$field:" "$yaml_file" 2>/dev/null; then
      pass "Agent '$agent_name' agent.yaml has '$field' field"
    else
      fail "Agent '$agent_name' agent.yaml missing '$field' field"
    fi
  done
done

echo ""
echo "--- Skill Config Tests ---"

for skill_dir in "$PROJECT_ROOT/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  if [ -f "$skill_dir/skill.yaml" ]; then
    pass "Skill '$skill_name' has skill.yaml"
  else
    fail "Skill '$skill_name' missing skill.yaml"
  fi

  if [ -f "$skill_dir/prompt.md" ]; then
    pass "Skill '$skill_name' has prompt.md"
  else
    fail "Skill '$skill_name' missing prompt.md"
  fi

  yaml_file="$skill_dir/skill.yaml"
  for field in name description version; do
    if grep -q "^$field:" "$yaml_file" 2>/dev/null; then
      pass "Skill '$skill_name' skill.yaml has '$field' field"
    else
      fail "Skill '$skill_name' skill.yaml missing '$field' field"
    fi
  done
done

echo ""
echo "--- Template Tests ---"

if [ -f "$PROJECT_ROOT/templates/agent/agent.yaml" ]; then
  pass "Agent template exists"
else
  fail "Agent template missing"
fi

if [ -f "$PROJECT_ROOT/templates/skill/skill.yaml" ]; then
  pass "Skill template exists"
else
  fail "Skill template missing"
fi

echo ""
echo "--- IDE Bootstrap Tests ---"

if [ -f "$PROJECT_ROOT/.vscode/settings.json" ]; then
  pass ".vscode/settings.json exists"
else
  fail ".vscode/settings.json missing"
fi

if [ -f "$PROJECT_ROOT/.cursor/rules/agentspec.md" ]; then
  pass ".cursor/rules/agentspec.md exists"
else
  fail ".cursor/rules/agentspec.md missing"
fi

if [ -f "$PROJECT_ROOT/.github/copilot-instructions.md" ]; then
  pass ".github/copilot-instructions.md exists"
else
  fail ".github/copilot-instructions.md missing"
fi

echo ""
echo "--- Prompt Template Tests ---"

if [ -f "$PROJECT_ROOT/prompts/create-agent.md" ]; then
  pass "create-agent prompt template exists"
else
  fail "create-agent prompt template missing"
fi

if [ -f "$PROJECT_ROOT/prompts/create-skill.md" ]; then
  pass "create-skill prompt template exists"
else
  fail "create-skill prompt template missing"
fi

echo ""
echo "--- CLI Script Tests ---"

if [ -f "$PROJECT_ROOT/scripts/agentspec.sh" ]; then
  pass "agentspec.sh CLI script exists"
  if [ -x "$PROJECT_ROOT/scripts/agentspec.sh" ]; then
    pass "agentspec.sh is executable"
  else
    fail "agentspec.sh is not executable"
  fi
else
  fail "agentspec.sh CLI script missing"
fi

echo ""
echo "--- YAML Validation Tests ---"

validate_yaml() {
  local file="$1"
  local name="$2"
  if python3 -c "
import yaml, sys
try:
    with open('$file') as f:
        yaml.safe_load(f)
    sys.exit(0)
except Exception as e:
    print(f'  Invalid YAML: {e}')
    sys.exit(1)
" 2>/dev/null; then
    pass "$name is valid YAML"
  else
    fail "$name is invalid YAML"
  fi
}

for yaml_file in "$PROJECT_ROOT"/agents/*/agent.yaml; do
  if [ -f "$yaml_file" ]; then
    agent_name=$(basename "$(dirname "$yaml_file")")
    validate_yaml "$yaml_file" "Agent '$agent_name' agent.yaml"
  fi
done

for yaml_file in "$PROJECT_ROOT"/skills/*/skill.yaml; do
  if [ -f "$yaml_file" ]; then
    skill_name=$(basename "$(dirname "$yaml_file")")
    validate_yaml "$yaml_file" "Skill '$skill_name' skill.yaml"
  fi
done

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
