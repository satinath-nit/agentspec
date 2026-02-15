#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

BOX_TL='\342\224\214'
BOX_TR='\342\224\220'
BOX_BL='\342\224\224'
BOX_BR='\342\224\230'
BOX_H='\342\224\200'
BOX_V='\342\224\202'
BOX_TITLE_L='\342\224\244'
BOX_TITLE_R='\342\224\234'

usage() {
  cat <<EOF
agentspec v${VERSION} - AI Agent Configuration Toolkit

Usage: agentspec <command> [options]

Commands:
  init <path>          Initialize a new agentspec project
  new-agent            Create a new agent configuration
  new-skill            Create a new skill configuration
  list                 List all agents and skills
  validate             Validate all configurations

Options:
  --help               Show this help message
  --version            Show version
  --project-dir <dir>  Specify project directory (default: current)
  --non-interactive    Skip interactive prompts (requires --name and --description)
  --name <name>        Name for new agent/skill
  --description <desc> Description for new agent/skill

Examples:
  agentspec init my-project
  agentspec init my-project --ide copilot
  agentspec init my-project --ide cursor-agent --non-interactive
  agentspec new-agent
  agentspec new-agent --name my-agent --description "Does something" --non-interactive
  agentspec new-skill --name my-skill --description "Creates something" --non-interactive
  agentspec list
  agentspec validate

Supported IDEs/AI Assistants:
  copilot, claude, gemini, cursor-agent, qwen, opencode, codex,
  windsurf, kilocode, auggie, codebuddy, qoder, roo, q, amp,
  shai, bob, devin
EOF
}

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

to_kebab_case() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//'
}

show_banner() {
  echo -e "${CYAN}"
  echo '    _    ____ _____ _   _ _____ ____  ____  _____ ____'
  echo '   / \  / ___| ____| \ | |_   _/ ___||  _ \| ____/ ___|'
  echo '  / _ \| |  _|  _| |  \| | | | \___ \| |_) |  _|| |'
  echo ' / ___ \ |_| | |___| |\  | | |  ___) |  __/| |__| |___'
  echo '/_/   \_\____|_____|_| \_| |_| |____/|_|   |_____\____|'
  echo -e "${NC}"
  echo -e "  ${DIM}AgentSpec - AI Agent Configuration Toolkit${NC}"
  echo ""
}

draw_box() {
  local title="$1"
  local width=70
  local border_color="${CYAN}"

  echo -en "${border_color}"
  printf '\xe2\x94\x8c'
  if [ -n "$title" ]; then
    printf '\xe2\x94\x80\xe2\x94\x80 '
    echo -en "${NC}${BOLD}${title}${NC}${border_color}"
    printf ' \xe2\x94\x80'
    local title_len=$((${#title} + 4))
    local remaining=$((width - title_len - 2))
    for ((i=0; i<remaining; i++)); do printf '\xe2\x94\x80'; done
  else
    for ((i=0; i<$((width - 2)); i++)); do printf '\xe2\x94\x80'; done
  fi
  printf '\xe2\x94\x90'
  echo -e "${NC}"
}

draw_box_line() {
  local content="$1"
  local width=70
  local border_color="${CYAN}"
  local content_width=$((width - 4))

  echo -en "${border_color}"
  printf '\xe2\x94\x82'
  echo -en "${NC}"
  printf " %-${content_width}s " "$content"
  echo -en "${border_color}"
  printf '\xe2\x94\x82'
  echo -e "${NC}"
}

draw_box_line_kv() {
  local key="$1"
  local value="$2"
  local width=70
  local border_color="${CYAN}"
  local content_width=$((width - 4))
  local formatted
  formatted=$(printf "  ${BOLD}%-16s${NC}${GREEN}%s${NC}" "$key" "$value")

  echo -en "${border_color}"
  printf '\xe2\x94\x82'
  echo -en "${NC}"
  echo -en " $formatted"
  local visible_len=$((2 + 16 + ${#value}))
  local padding=$((content_width - visible_len))
  [ $padding -gt 0 ] && printf "%${padding}s" ""
  echo -en " ${border_color}"
  printf '\xe2\x94\x82'
  echo -e "${NC}"
}

draw_box_empty() {
  draw_box_line ""
}

draw_box_bottom() {
  local width=70
  local border_color="${CYAN}"

  echo -en "${border_color}"
  printf '\xe2\x94\x94'
  for ((i=0; i<$((width - 2)); i++)); do printf '\xe2\x94\x80'; done
  printf '\xe2\x94\x98'
  echo -e "${NC}"
}

IDE_KEYS=("copilot" "claude" "gemini" "cursor-agent" "qwen" "opencode" "codex" "windsurf" "kilocode" "auggie" "codebuddy" "qoder" "roo" "q" "amp" "shai" "bob" "devin")
IDE_LABELS=("GitHub Copilot" "Claude Code" "Gemini CLI" "Cursor" "Qwen Code" "opencode" "Codex CLI" "Windsurf" "Kilo Code" "Auggie CLI" "CodeBuddy" "Qoder CLI" "Roo Code" "Amazon Q Developer CLI" "Amp" "SHAI" "IBM Bob" "Devin")

select_ide() {
  local selected=0
  local count=${#IDE_KEYS[@]}
  local visible_start=0
  local max_visible=18

  tput civis 2>/dev/null || true

  trap 'tput cnorm 2>/dev/null || true' EXIT

  while true; do
    tput cup $(($(tput lines) - max_visible - 5)) 0 2>/dev/null || true

    draw_box "Choose your IDE/AI assistant"
    draw_box_empty

    for ((i=visible_start; i<visible_start+max_visible && i<count; i++)); do
      local key="${IDE_KEYS[$i]}"
      local label="${IDE_LABELS[$i]}"
      if [ $i -eq $selected ]; then
        local line
        line=$(printf "  ${GREEN}\xe2\x96\xb6  %-20s${NC} ${DIM}(%s)${NC}" "$key" "$label")
        draw_box_line "$(echo -e "$line")"
      else
        local line
        line=$(printf "     ${WHITE}%-20s${NC} ${DIM}(%s)${NC}" "$key" "$label")
        draw_box_line "$(echo -e "$line")"
      fi
    done

    draw_box_empty
    draw_box_line "$(echo -e "${DIM}Use \xe2\x86\x91/\xe2\x86\x93 to navigate, Enter to select, Esc to cancel${NC}")"
    draw_box_bottom

    IFS= read -rsn1 key
    case "$key" in
      $'\x1b')
        read -rsn2 -t 0.1 seq || true
        case "$seq" in
          '[A')
            ((selected > 0)) && ((selected--))
            if ((selected < visible_start)); then
              visible_start=$selected
            fi
            ;;
          '[B')
            ((selected < count - 1)) && ((selected++))
            if ((selected >= visible_start + max_visible)); then
              ((visible_start++))
            fi
            ;;
        esac
        ;;
      '')
        tput cnorm 2>/dev/null || true
        SELECTED_IDE="${IDE_KEYS[$selected]}"
        SELECTED_IDE_LABEL="${IDE_LABELS[$selected]}"
        return 0
        ;;
      'q')
        tput cnorm 2>/dev/null || true
        return 1
        ;;
    esac
  done
}

generate_ide_config() {
  local project_path="$1"
  local ide_key="$2"

  case "$ide_key" in
    copilot)
      mkdir -p "$project_path/.github"
      cat > "$project_path/.github/copilot-instructions.md" <<'COPILOT_EOF'
# GitHub Copilot Instructions for AgentSpec

This is an AgentSpec project for managing AI agent configurations and skills.

## Project Structure
- `agents/` - Agent configurations with agent.yaml and prompt.md
- `skills/` - Skill configurations with skill.yaml and prompt.md
- `templates/` - Templates for new agents/skills
- `prompts/` - Chat prompt templates

## When creating new agents:
1. Create directory under `agents/{agent-name}/`
2. Create `agent.yaml` with required fields: name, description, version
3. Create `prompt.md` with detailed instructions
4. Names must be kebab-case

## When creating new skills:
1. Create directory under `skills/{skill-name}/`
2. Create `skill.yaml` with required fields: name, description, version, steps
3. Create `prompt.md` with detailed instructions
4. Names must be kebab-case
COPILOT_EOF
      ;;
    claude)
      cat > "$project_path/CLAUDE.md" <<'CLAUDE_EOF'
# Claude Code Instructions for AgentSpec

This is an AgentSpec project for managing AI agent configurations and skills.

## Project Structure
- `agents/` - Agent configurations with agent.yaml and prompt.md
- `skills/` - Skill configurations with skill.yaml and prompt.md
- `templates/` - Templates for new agents/skills
- `prompts/` - Chat prompt templates for interactive creation

## Conventions
- All config names use kebab-case
- Agent configs: `agents/{name}/agent.yaml` + `prompt.md`
- Skill configs: `skills/{name}/skill.yaml` + `prompt.md`
- YAML files must have: name, description, version

## Available Commands
- `./scripts/agentspec.sh new-agent` - Create new agent interactively
- `./scripts/agentspec.sh new-skill` - Create new skill interactively
- `./scripts/agentspec.sh list` - List all configs
- `./scripts/agentspec.sh validate` - Validate all configs
CLAUDE_EOF
      ;;
    gemini)
      mkdir -p "$project_path/.gemini"
      cat > "$project_path/.gemini/settings.json" <<'GEMINI_EOF'
{
  "projectContext": "AgentSpec - AI Agent Configuration Toolkit. Manages agent configs in agents/{name}/agent.yaml and skills in skills/{name}/skill.yaml. All names kebab-case. YAML requires name, description, version fields.",
  "codeStyle": {
    "yamlIndent": 2,
    "namingConvention": "kebab-case"
  }
}
GEMINI_EOF
      ;;
    cursor-agent)
      mkdir -p "$project_path/.cursor/rules"
      cat > "$project_path/.cursor/rules/agentspec.md" <<'CURSOR_EOF'
# AgentSpec Rules for Cursor

You are working in an AgentSpec project. This project manages AI agent configurations and skills.

## Key Conventions

- Agent configs are in `agents/{name}/agent.yaml` with accompanying `prompt.md`
- Skill configs are in `skills/{name}/skill.yaml` with accompanying `prompt.md`
- All names use kebab-case (lowercase with hyphens)
- YAML files must have: name, description, version fields
- Use the templates in `templates/` when creating new configs

## Available Commands

- Use prompts in `prompts/create-agent.md` to create new agents
- Use prompts in `prompts/create-skill.md` to create new skills
- Run `./scripts/agentspec.sh validate` to validate all configs
CURSOR_EOF
      ;;
    qwen)
      cat > "$project_path/.qwen" <<'QWEN_EOF'
# Qwen Code Instructions for AgentSpec

AgentSpec project managing AI agent configurations and skills.

## Structure
- agents/{name}/agent.yaml + prompt.md
- skills/{name}/skill.yaml + prompt.md
- templates/ for new config scaffolding
- prompts/ for GenAI chat interaction

## Rules
- kebab-case names only
- YAML requires: name, description, version
- Use ./scripts/agentspec.sh for CLI operations
QWEN_EOF
      ;;
    opencode)
      cat > "$project_path/.opencode" <<'OPENCODE_EOF'
# opencode Instructions for AgentSpec

AgentSpec project for AI agent configuration management.

## Structure
- agents/{name}/agent.yaml + prompt.md
- skills/{name}/skill.yaml + prompt.md

## Conventions
- kebab-case naming
- Required YAML fields: name, description, version
- CLI: ./scripts/agentspec.sh
OPENCODE_EOF
      ;;
    codex)
      mkdir -p "$project_path/.codex"
      cat > "$project_path/.codex/instructions.md" <<'CODEX_EOF'
# Codex CLI Instructions for AgentSpec

AgentSpec project for managing AI agent configurations.

## Key Files
- agents/{name}/agent.yaml - Agent configuration
- skills/{name}/skill.yaml - Skill configuration
- templates/ - Config templates
- prompts/ - GenAI chat prompts

## Rules
- Use kebab-case for all names
- YAML must include: name, description, version
- Run ./scripts/agentspec.sh validate to check configs
CODEX_EOF
      ;;
    windsurf)
      mkdir -p "$project_path/.windsurf/rules"
      cat > "$project_path/.windsurf/rules/agentspec.md" <<'WINDSURF_EOF'
# AgentSpec Rules for Windsurf

This is an AgentSpec project for AI agent configuration management.

## Key Conventions
- Agent configs: `agents/{name}/agent.yaml` + `prompt.md`
- Skill configs: `skills/{name}/skill.yaml` + `prompt.md`
- Names: kebab-case only
- Required YAML fields: name, description, version

## Available Workflows
- Create agent: `./scripts/agentspec.sh new-agent`
- Create skill: `./scripts/agentspec.sh new-skill`
- Validate: `./scripts/agentspec.sh validate`
- List all: `./scripts/agentspec.sh list`
WINDSURF_EOF
      ;;
    kilocode)
      cat > "$project_path/.kilocode" <<'KILO_EOF'
# Kilo Code Instructions for AgentSpec

AgentSpec project for AI agent configuration management.
Agents: agents/{name}/agent.yaml + prompt.md
Skills: skills/{name}/skill.yaml + prompt.md
Naming: kebab-case. Required fields: name, description, version.
CLI: ./scripts/agentspec.sh [new-agent|new-skill|list|validate]
KILO_EOF
      ;;
    auggie)
      cat > "$project_path/.auggie" <<'AUGGIE_EOF'
# Auggie CLI Instructions for AgentSpec

AgentSpec - AI Agent Configuration Toolkit

## Structure
- agents/{name}/agent.yaml + prompt.md
- skills/{name}/skill.yaml + prompt.md
- templates/ and prompts/ for scaffolding

## Conventions
- kebab-case names, required fields: name, description, version
- CLI: ./scripts/agentspec.sh
AUGGIE_EOF
      ;;
    codebuddy)
      cat > "$project_path/.codebuddy" <<'CODEBUDDY_EOF'
# CodeBuddy Instructions for AgentSpec

AgentSpec project managing AI agent configs and skills.
Agents: agents/{name}/agent.yaml + prompt.md
Skills: skills/{name}/skill.yaml + prompt.md
Naming: kebab-case. YAML requires: name, description, version.
CLI: ./scripts/agentspec.sh
CODEBUDDY_EOF
      ;;
    qoder)
      cat > "$project_path/.qoder" <<'QODER_EOF'
# Qoder CLI Instructions for AgentSpec

AgentSpec - AI Agent Configuration Toolkit
Agents: agents/{name}/agent.yaml + prompt.md
Skills: skills/{name}/skill.yaml + prompt.md
Conventions: kebab-case, required YAML fields: name, description, version
CLI: ./scripts/agentspec.sh [new-agent|new-skill|list|validate]
QODER_EOF
      ;;
    roo)
      cat > "$project_path/.roo" <<'ROO_EOF'
# Roo Code Instructions for AgentSpec

AgentSpec project for AI agent configuration management.

## Structure
- agents/{name}/agent.yaml + prompt.md
- skills/{name}/skill.yaml + prompt.md

## Rules
- kebab-case naming convention
- Required YAML fields: name, description, version
- Use templates/ for scaffolding new configs
- CLI: ./scripts/agentspec.sh
ROO_EOF
      ;;
    q)
      cat > "$project_path/.q" <<'Q_EOF'
# Amazon Q Developer CLI Instructions for AgentSpec

AgentSpec - AI Agent Configuration Toolkit

## Project Layout
- agents/{name}/agent.yaml + prompt.md - Agent configurations
- skills/{name}/skill.yaml + prompt.md - Skill configurations
- templates/ - Config templates
- prompts/ - GenAI chat prompts

## Conventions
- kebab-case for all names
- YAML requires: name, description, version
- CLI: ./scripts/agentspec.sh
Q_EOF
      ;;
    amp)
      cat > "$project_path/.amp" <<'AMP_EOF'
# Amp Instructions for AgentSpec

AgentSpec project for AI agent configuration management.
Agents: agents/{name}/agent.yaml + prompt.md
Skills: skills/{name}/skill.yaml + prompt.md
Naming: kebab-case. Required YAML: name, description, version.
CLI: ./scripts/agentspec.sh [init|new-agent|new-skill|list|validate]
AMP_EOF
      ;;
    shai)
      cat > "$project_path/.shai" <<'SHAI_EOF'
# SHAI Instructions for AgentSpec

AgentSpec - AI Agent Configuration Toolkit
Agents: agents/{name}/agent.yaml + prompt.md
Skills: skills/{name}/skill.yaml + prompt.md
Conventions: kebab-case, YAML fields: name, description, version
CLI: ./scripts/agentspec.sh
SHAI_EOF
      ;;
    bob)
      cat > "$project_path/.bob" <<'BOB_EOF'
# IBM Bob Instructions for AgentSpec

AgentSpec project for managing AI agent configurations and skills.

## Structure
- agents/{name}/agent.yaml + prompt.md
- skills/{name}/skill.yaml + prompt.md
- templates/ for scaffolding

## Rules
- kebab-case naming
- Required YAML: name, description, version
- CLI: ./scripts/agentspec.sh
BOB_EOF
      ;;
    devin)
      mkdir -p "$project_path/.devin"
      cat > "$project_path/.devin/instructions.md" <<'DEVIN_EOF'
# Devin Instructions for AgentSpec

AgentSpec project for managing AI agent configurations and skills.

## Structure
- agents/{name}/agent.yaml + prompt.md - Agent configurations
- skills/{name}/skill.yaml + prompt.md - Skill configurations
- templates/ - Config templates for scaffolding
- prompts/ - GenAI chat interaction prompts

## Conventions
- All names use kebab-case
- YAML files require: name, description, version fields
- Use ./scripts/agentspec.sh CLI for operations

## Commands
- new-agent: Create new agent config
- new-skill: Create new skill config
- list: List all configurations
- validate: Validate all YAML configs
DEVIN_EOF
      ;;
  esac
}

generate_vscode_config() {
  local project_path="$1"
  mkdir -p "$project_path/.vscode"
  cat > "$project_path/.vscode/settings.json" <<'VSCODE_EOF'
{
  "yaml.schemas": {
    "./templates/agent/agent.yaml": "agents/*/agent.yaml",
    "./templates/skill/skill.yaml": "skills/*/skill.yaml"
  },
  "files.associations": {
    "*.yaml": "yaml",
    "*.yml": "yaml"
  },
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "[yaml]": {
    "editor.defaultFormatter": "redhat.vscode-yaml"
  },
  "task.autoDetect": "on"
}
VSCODE_EOF

  cat > "$project_path/.vscode/tasks.json" <<'TASKS_EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "AgentSpec: Validate Configs",
      "type": "shell",
      "command": "./scripts/agentspec.sh validate",
      "group": "test"
    },
    {
      "label": "AgentSpec: List Configs",
      "type": "shell",
      "command": "./scripts/agentspec.sh list"
    },
    {
      "label": "AgentSpec: New Agent",
      "type": "shell",
      "command": "./scripts/agentspec.sh new-agent"
    },
    {
      "label": "AgentSpec: New Skill",
      "type": "shell",
      "command": "./scripts/agentspec.sh new-skill"
    }
  ]
}
TASKS_EOF

  cat > "$project_path/.vscode/extensions.json" <<'EXT_EOF'
{
  "recommendations": [
    "redhat.vscode-yaml",
    "esbenp.prettier-vscode",
    "davidanson.vscode-markdownlint"
  ]
}
EXT_EOF
}

cmd_init() {
  local project_path="${1:-}"
  local ide_flag=""
  local non_interactive=false

  shift 2>/dev/null || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ide) ide_flag="$2"; shift 2 ;;
      --non-interactive) non_interactive=true; shift ;;
      *) shift ;;
    esac
  done

  if [ -z "$project_path" ]; then
    log_error "Project path is required. Usage: agentspec init <path> [--ide <ide>]"
    exit 1
  fi

  show_banner

  if [ -d "$project_path" ]; then
    local item_count
    item_count=$(ls -A "$project_path" 2>/dev/null | wc -l)
    if [ "$item_count" -gt 0 ]; then
      echo -e "${YELLOW}Warning: Directory is not empty ($item_count items)${NC}"
      echo -e "Template files will be merged with existing content and may overwrite existing files"
      if [ "$non_interactive" = false ]; then
        read -rp "Do you want to continue? [y/N]: " confirm
        [[ "$confirm" != "y" && "$confirm" != "Y" ]] && exit 0
      fi
      echo ""
    fi
  fi

  local project_name
  project_name=$(basename "$project_path")
  local abs_path
  abs_path=$(cd "$(dirname "$project_path")" 2>/dev/null && echo "$(pwd)/$(basename "$project_path")" || echo "$project_path")

  draw_box "AgentSpec Project Setup"
  draw_box_empty
  draw_box_line_kv "Project" "$project_name"
  draw_box_line_kv "Working Path" "$abs_path"
  draw_box_empty
  draw_box_bottom
  echo ""

  local selected_ide=""
  local selected_ide_label=""

  if [ -n "$ide_flag" ]; then
    selected_ide="$ide_flag"
    for i in "${!IDE_KEYS[@]}"; do
      if [ "${IDE_KEYS[$i]}" = "$ide_flag" ]; then
        selected_ide_label="${IDE_LABELS[$i]}"
        break
      fi
    done
    if [ -z "$selected_ide_label" ]; then
      selected_ide_label="$ide_flag"
    fi
    echo -e "${GREEN}\xe2\x96\xb6${NC} IDE/AI assistant: ${BOLD}${selected_ide}${NC} (${selected_ide_label})"
    echo ""
  elif [ "$non_interactive" = true ]; then
    selected_ide="copilot"
    selected_ide_label="GitHub Copilot"
  else
    SELECTED_IDE=""
    SELECTED_IDE_LABEL=""
    if select_ide; then
      selected_ide="$SELECTED_IDE"
      selected_ide_label="$SELECTED_IDE_LABEL"
    else
      log_error "IDE selection cancelled"
      exit 1
    fi
    echo ""
    echo -e "  ${GREEN}\xe2\x9c\x94${NC} Selected: ${BOLD}${selected_ide}${NC} (${selected_ide_label})"
    echo ""
  fi

  log_info "Initializing agentspec project..."
  echo ""

  mkdir -p "$project_path/agents"
  mkdir -p "$project_path/skills"
  mkdir -p "$project_path/templates/agent"
  mkdir -p "$project_path/templates/skill"
  mkdir -p "$project_path/prompts"
  mkdir -p "$project_path/scripts"
  mkdir -p "$project_path/tests"

  if [ -d "$DEFAULT_PROJECT_DIR/templates" ]; then
    cp -r "$DEFAULT_PROJECT_DIR/templates/agent/"* "$project_path/templates/agent/" 2>/dev/null || true
    cp -r "$DEFAULT_PROJECT_DIR/templates/skill/"* "$project_path/templates/skill/" 2>/dev/null || true
  fi

  if [ -d "$DEFAULT_PROJECT_DIR/prompts" ]; then
    cp "$DEFAULT_PROJECT_DIR/prompts/"*.md "$project_path/prompts/" 2>/dev/null || true
  fi

  cp "$SCRIPT_DIR/agentspec.sh" "$project_path/scripts/agentspec.sh" 2>/dev/null || true
  chmod +x "$project_path/scripts/agentspec.sh" 2>/dev/null || true

  echo -e "  ${GREEN}\xe2\x9c\x94${NC} Created project directories"

  cat > "$project_path/AGENTS.md" <<'AGENTS_EOF'
# AGENTS.md

## About AgentSpec

AgentSpec is an open-source toolkit for creating and managing AI agent configurations.
It provides a structured approach to defining agent behaviors, skills, and IDE integrations.

## Project Structure

- `agents/` - Agent configurations (each agent has its own directory)
- `skills/` - Skill configurations (each skill has its own directory)
- `templates/` - Templates for creating new agents and skills
- `prompts/` - GenAI prompt templates for IDE agentic mode
- `scripts/` - CLI tools and utilities

## Quick Start

```bash
# Create a new agent
./scripts/agentspec.sh new-agent

# Create a new skill
./scripts/agentspec.sh new-skill

# List all configurations
./scripts/agentspec.sh list

# Validate configurations
./scripts/agentspec.sh validate
```

## IDE Integration

Use the prompt templates in `prompts/` with your IDE's AI chat:
- `/agentspec.create-agent` - Create a new agent via chat
- `/agentspec.create-skill` - Create a new skill via chat
- `/agentspec.list` - List available configurations
AGENTS_EOF
  echo -e "  ${GREEN}\xe2\x9c\x94${NC} Created AGENTS.md"

  cat > "$project_path/.gitignore" <<'GITIGNORE_EOF'
.env
.env.local
.env.*.local
.DS_Store
Thumbs.db
.idea/
*.swp
*.swo
*~
dist/
build/
*.zip
node_modules/
vendor/
__pycache__/
*.pyc
*.log
tmp/
temp/
GITIGNORE_EOF
  echo -e "  ${GREEN}\xe2\x9c\x94${NC} Created .gitignore"

  cat > "$project_path/.env.example" <<'ENV_EOF'
# AgentSpec Environment Configuration
# Copy this file to .env and fill in your values

# Default AI model preference (optional)
# AGENTSPEC_DEFAULT_MODEL=gpt-4

# Default author for new configs (optional)
# AGENTSPEC_AUTHOR=your-name

# JIRA integration (for jira-story-creator skill)
# JIRA_BASE_URL=https://your-org.atlassian.net
# JIRA_API_TOKEN=your-api-token
# JIRA_EMAIL=your-email@example.com
# JIRA_PROJECT_KEY=PROJ
ENV_EOF
  echo -e "  ${GREEN}\xe2\x9c\x94${NC} Created .env.example"

  generate_ide_config "$project_path" "$selected_ide"
  echo -e "  ${GREEN}\xe2\x9c\x94${NC} Configured for ${BOLD}${selected_ide}${NC} (${selected_ide_label})"

  generate_vscode_config "$project_path"
  echo -e "  ${GREEN}\xe2\x9c\x94${NC} Added VS Code settings (tasks, extensions, YAML schemas)"

  echo ""
  draw_box "Setup Complete"
  draw_box_empty
  draw_box_line "$(echo -e "  ${GREEN}Project initialized successfully!${NC}")"
  draw_box_empty
  draw_box_line "$(echo -e "  ${DIM}Next steps:${NC}")"
  draw_box_line "$(echo -e "    cd $project_path")"
  draw_box_line "$(echo -e "    ./scripts/agentspec.sh new-agent    ${DIM}# Create your first agent${NC}")"
  draw_box_line "$(echo -e "    ./scripts/agentspec.sh new-skill    ${DIM}# Create your first skill${NC}")"
  draw_box_line "$(echo -e "    ./scripts/agentspec.sh list          ${DIM}# List all configs${NC}")"
  draw_box_line "$(echo -e "    ./scripts/agentspec.sh validate      ${DIM}# Validate configs${NC}")"
  draw_box_empty
  draw_box_line "$(echo -e "  ${DIM}Or use your IDE's AI chat with the prompts in prompts/${NC}")"
  draw_box_empty
  draw_box_bottom
}

cmd_new_agent() {
  local project_dir="$PROJECT_DIR"
  local name=""
  local description=""
  local non_interactive=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name) name="$2"; shift 2 ;;
      --description) description="$2"; shift 2 ;;
      --non-interactive) non_interactive=true; shift ;;
      --project-dir) project_dir="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ "$non_interactive" = false ]; then
    echo -e "${CYAN}=== Create New Agent ===${NC}"
    echo ""

    read -rp "Agent name (kebab-case): " name
    name=$(to_kebab_case "$name")

    read -rp "Description: " description

    read -rp "Tags (comma-separated): " tags_input
    IFS=',' read -ra tags <<< "$tags_input"

    read -rp "Author (default: agentspec): " author
    author="${author:-agentspec}"

    echo ""
    echo "System prompt (enter empty line to finish):"
    system_prompt=""
    while IFS= read -r line; do
      [ -z "$line" ] && break
      system_prompt="${system_prompt}${line}\n"
    done
  else
    if [ -z "$name" ] || [ -z "$description" ]; then
      log_error "In non-interactive mode, --name and --description are required"
      exit 1
    fi
    name=$(to_kebab_case "$name")
    tags=("general")
    author="agentspec"
    system_prompt="You are an AI assistant for ${name}. ${description}"
  fi

  local agent_dir="$project_dir/agents/$name"

  if [ -d "$agent_dir" ]; then
    log_warn "Agent '$name' already exists at $agent_dir"
    if [ "$non_interactive" = false ]; then
      read -rp "Overwrite? (y/N): " confirm
      [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && exit 0
    fi
  fi

  mkdir -p "$agent_dir"

  local tags_yaml=""
  if [ "$non_interactive" = false ]; then
    for tag in "${tags[@]}"; do
      tag=$(echo "$tag" | xargs)
      tags_yaml="${tags_yaml}  - ${tag}\n"
    done
  else
    tags_yaml="  - general\n"
  fi

  cat > "$agent_dir/agent.yaml" <<EOF
name: ${name}
description: ${description}
version: 1.0.0
author: ${author}
model_preferences:
  - gpt-4
  - claude-sonnet
  - gemini-pro
tags:
$(echo -e "$tags_yaml")
system_prompt: |
  ${system_prompt:-You are an AI assistant for ${name}. ${description}}

inputs:
  - name: user_input
    description: Primary input from the user
    required: true

outputs:
  - name: result
    description: Generated output
    format: markdown

tools:
  - name: file_write
    description: Write output to a file
EOF

  cat > "$agent_dir/prompt.md" <<EOF
# ${name} Agent

${description}

## Instructions

Use this agent to ${description}.

## Usage

Provide your input and the agent will generate the appropriate output based on its configuration.
EOF

  log_success "Agent '$name' created at: $agent_dir"
  log_info "Files created:"
  echo "  - $agent_dir/agent.yaml"
  echo "  - $agent_dir/prompt.md"

  if [ "$non_interactive" = false ]; then
    echo ""
    log_info "Next: Open prompt.md to customize the agent's detailed instructions."
    echo ""
    echo -e "${CYAN}Tip: Use your IDE's AI chat with the create-agent prompt for a more interactive experience:${NC}"
    echo "  Open prompts/create-agent.md and paste it into your AI chat"
  fi
}

cmd_new_skill() {
  local project_dir="$PROJECT_DIR"
  local name=""
  local description=""
  local non_interactive=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name) name="$2"; shift 2 ;;
      --description) description="$2"; shift 2 ;;
      --non-interactive) non_interactive=true; shift ;;
      --project-dir) project_dir="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ "$non_interactive" = false ]; then
    echo -e "${CYAN}=== Create New Skill ===${NC}"
    echo ""

    read -rp "Skill name (kebab-case): " name
    name=$(to_kebab_case "$name")

    read -rp "Description: " description

    read -rp "Tags (comma-separated): " tags_input
    IFS=',' read -ra tags <<< "$tags_input"

    read -rp "Author (default: agentspec): " author
    author="${author:-agentspec}"

    echo ""
    echo "Define steps (enter empty name to finish):"
    steps=()
    while true; do
      read -rp "  Step name: " step_name
      [ -z "$step_name" ] && break
      read -rp "  Step description: " step_desc
      steps+=("${step_name}:${step_desc}")
    done
  else
    if [ -z "$name" ] || [ -z "$description" ]; then
      log_error "In non-interactive mode, --name and --description are required"
      exit 1
    fi
    name=$(to_kebab_case "$name")
    tags=("general")
    author="agentspec"
    steps=("analyze:Analyze the input" "generate:Generate the output" "review:Review and refine")
  fi

  local skill_dir="$project_dir/skills/$name"

  if [ -d "$skill_dir" ]; then
    log_warn "Skill '$name' already exists at $skill_dir"
    if [ "$non_interactive" = false ]; then
      read -rp "Overwrite? (y/N): " confirm
      [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && exit 0
    fi
  fi

  mkdir -p "$skill_dir"

  local tags_yaml=""
  if [ "$non_interactive" = false ]; then
    for tag in "${tags[@]}"; do
      tag=$(echo "$tag" | xargs)
      tags_yaml="${tags_yaml}  - ${tag}\n"
    done
  else
    tags_yaml="  - general\n"
  fi

  local steps_yaml=""
  for step in "${steps[@]}"; do
    local sname="${step%%:*}"
    local sdesc="${step#*:}"
    steps_yaml="${steps_yaml}  - name: ${sname}\n    description: ${sdesc}\n"
  done

  cat > "$skill_dir/skill.yaml" <<EOF
name: ${name}
description: ${description}
version: 1.0.0
author: ${author}
tags:
$(echo -e "$tags_yaml")
system_prompt: |
  You are a specialist for ${name}. ${description}

inputs:
  - name: requirement
    description: The requirement or input to process
    required: true

outputs:
  - name: result
    description: Generated output
    format: markdown

steps:
$(echo -e "$steps_yaml")
EOF

  cat > "$skill_dir/prompt.md" <<EOF
# ${name} Skill

${description}

## Instructions

Use this skill to ${description}.

## Steps

This skill follows these steps:
$(for step in "${steps[@]}"; do
    local sname="${step%%:*}"
    local sdesc="${step#*:}"
    echo "1. **${sname}**: ${sdesc}"
  done)

## Usage

Provide your requirements and the skill will process them through the defined steps.
EOF

  log_success "Skill '$name' created at: $skill_dir"
  log_info "Files created:"
  echo "  - $skill_dir/skill.yaml"
  echo "  - $skill_dir/prompt.md"

  if [ "$non_interactive" = false ]; then
    echo ""
    log_info "Next: Open prompt.md to customize the skill's detailed instructions."
    echo ""
    echo -e "${CYAN}Tip: Use your IDE's AI chat with the create-skill prompt for a more interactive experience:${NC}"
    echo "  Open prompts/create-skill.md and paste it into your AI chat"
  fi
}

cmd_list() {
  local project_dir="$PROJECT_DIR"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-dir) project_dir="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  echo -e "${CYAN}=== AgentSpec Configurations ===${NC}"
  echo ""

  local agent_count=0
  echo -e "${GREEN}Agents:${NC}"
  if [ -d "$project_dir/agents" ]; then
    for agent_dir in "$project_dir/agents"/*/; do
      [ ! -d "$agent_dir" ] && continue
      local yaml_file="$agent_dir/agent.yaml"
      if [ -f "$yaml_file" ]; then
        local aname=$(grep "^name:" "$yaml_file" | head -1 | sed 's/name: *//')
        local adesc=$(grep "^description:" "$yaml_file" | head -1 | sed 's/description: *//')
        local aversion=$(grep "^version:" "$yaml_file" | head -1 | sed 's/version: *//')
        echo -e "  - ${BLUE}${aname}${NC} (v${aversion}) - ${adesc}"
        agent_count=$((agent_count + 1))
      fi
    done
  fi
  [ "$agent_count" -eq 0 ] && echo "  (none)"

  echo ""

  local skill_count=0
  echo -e "${GREEN}Skills:${NC}"
  if [ -d "$project_dir/skills" ]; then
    for skill_dir in "$project_dir/skills"/*/; do
      [ ! -d "$skill_dir" ] && continue
      local yaml_file="$skill_dir/skill.yaml"
      if [ -f "$yaml_file" ]; then
        local sname=$(grep "^name:" "$yaml_file" | head -1 | sed 's/name: *//')
        local sdesc=$(grep "^description:" "$yaml_file" | head -1 | sed 's/description: *//')
        local sversion=$(grep "^version:" "$yaml_file" | head -1 | sed 's/version: *//')
        echo -e "  - ${BLUE}${sname}${NC} (v${sversion}) - ${sdesc}"
        skill_count=$((skill_count + 1))
      fi
    done
  fi
  [ "$skill_count" -eq 0 ] && echo "  (none)"

  echo ""
  echo "Total: $agent_count agent(s), $skill_count skill(s)"
}

cmd_validate() {
  local project_dir="$PROJECT_DIR"
  local errors=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-dir) project_dir="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  echo -e "${CYAN}=== Validating AgentSpec Configurations ===${NC}"
  echo ""

  for agent_dir in "$project_dir/agents"/*/; do
    [ ! -d "$agent_dir" ] && continue
    local agent_name=$(basename "$agent_dir")
    local yaml_file="$agent_dir/agent.yaml"

    if [ ! -f "$yaml_file" ]; then
      log_error "Agent '$agent_name': missing agent.yaml"
      errors=$((errors + 1))
      continue
    fi

    for field in name description version; do
      if ! grep -q "^$field:" "$yaml_file"; then
        log_error "Agent '$agent_name': missing required field '$field'"
        errors=$((errors + 1))
      fi
    done

    if python3 -c "
import yaml, sys
try:
    with open('$yaml_file') as f:
        yaml.safe_load(f)
except Exception as e:
    print(f'YAML error: {e}')
    sys.exit(1)
" 2>/dev/null; then
      log_success "Agent '$agent_name': valid YAML"
    else
      log_error "Agent '$agent_name': invalid YAML"
      errors=$((errors + 1))
    fi

    if [ ! -f "$agent_dir/prompt.md" ]; then
      log_warn "Agent '$agent_name': missing prompt.md (recommended)"
    fi
  done

  for skill_dir in "$project_dir/skills"/*/; do
    [ ! -d "$skill_dir" ] && continue
    local skill_name=$(basename "$skill_dir")
    local yaml_file="$skill_dir/skill.yaml"

    if [ ! -f "$yaml_file" ]; then
      log_error "Skill '$skill_name': missing skill.yaml"
      errors=$((errors + 1))
      continue
    fi

    for field in name description version; do
      if ! grep -q "^$field:" "$yaml_file"; then
        log_error "Skill '$skill_name': missing required field '$field'"
        errors=$((errors + 1))
      fi
    done

    if python3 -c "
import yaml, sys
try:
    with open('$yaml_file') as f:
        yaml.safe_load(f)
except Exception as e:
    print(f'YAML error: {e}')
    sys.exit(1)
" 2>/dev/null; then
      log_success "Skill '$skill_name': valid YAML"
    else
      log_error "Skill '$skill_name': invalid YAML"
      errors=$((errors + 1))
    fi

    if [ ! -f "$skill_dir/prompt.md" ]; then
      log_warn "Skill '$skill_name': missing prompt.md (recommended)"
    fi
  done

  echo ""
  if [ "$errors" -gt 0 ]; then
    log_error "Validation failed with $errors error(s)"
    exit 1
  else
    log_success "All configurations are valid"
  fi
}

PROJECT_DIR="$DEFAULT_PROJECT_DIR"
COMMAND="${1:-}"

case "$COMMAND" in
  --help|-h|"")
    usage
    exit 0
    ;;
  --version|-v)
    echo "agentspec v${VERSION}"
    exit 0
    ;;
esac

shift

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir)
      PROJECT_DIR="$2"
      ARGS+=("--project-dir" "$2")
      shift 2
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

case "$COMMAND" in
  init)
    cmd_init "${ARGS[@]}"
    ;;
  new-agent)
    cmd_new_agent "${ARGS[@]}"
    ;;
  new-skill)
    cmd_new_skill "${ARGS[@]}"
    ;;
  list)
    cmd_list "${ARGS[@]}"
    ;;
  validate)
    cmd_validate "${ARGS[@]}"
    ;;
  *)
    log_error "Unknown command: $COMMAND"
    usage
    exit 1
    ;;
esac
