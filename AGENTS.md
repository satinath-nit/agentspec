# AGENTS.md

## About AgentSpec

AgentSpec is an open-source toolkit for quickly creating and managing AI agent configurations and skills. Inspired by [GitHub's spec-kit](https://github.com/github/spec-kit), it provides a structured, spec-driven approach to defining agent behaviors, skills, and IDE integrations for use with GenAI agentic modes in modern IDEs.

## Project Structure

```
agentspec/
  AGENTS.md              # This file - project overview and conventions
  README.md              # Getting started guide
  Taskfile.yml           # Task runner for local testing
  .env.example           # Environment variable template
  agents/                # Agent configurations
    {agent-name}/
      agent.yaml         # Agent metadata and configuration
      prompt.md          # Detailed prompt template for the agent
  skills/                # Skill configurations
    {skill-name}/
      skill.yaml         # Skill metadata and configuration
      prompt.md          # Detailed prompt template for the skill
  templates/             # Templates for creating new agents/skills
    agent/
      agent.yaml         # Agent YAML template
      prompt.md          # Agent prompt template
    skill/
      skill.yaml         # Skill YAML template
      prompt.md          # Skill prompt template
  prompts/               # GenAI chat prompt templates for IDE integration
    create-agent.md      # Interactive agent creation via AI chat
    create-skill.md      # Interactive skill creation via AI chat
    list-configs.md      # List all configurations via AI chat
  scripts/               # CLI tools
    agentspec.sh         # Main CLI script
  tests/                 # Test suite
    test_validate.sh     # Structure and validation tests
    test_cli.sh          # CLI command tests
  .vscode/               # VS Code IDE bootstrapping
  .cursor/               # Cursor IDE bootstrapping
  .github/               # GitHub Copilot integration
```

## Quick Start

```bash
# List all agents and skills
./scripts/agentspec.sh list

# Create a new agent (interactive)
./scripts/agentspec.sh new-agent

# Create a new skill (interactive)
./scripts/agentspec.sh new-skill

# Validate all configurations
./scripts/agentspec.sh validate

# Initialize a new project from this template
./scripts/agentspec.sh init /path/to/new-project
```

## IDE Integration

### VS Code / GitHub Copilot

- Copilot instructions are in `.github/copilot-instructions.md`
- VS Code tasks available via `Ctrl+Shift+P` > `Tasks: Run Task`
- Recommended extensions listed in `.vscode/extensions.json`

### Cursor

- Cursor rules are in `.cursor/rules/agentspec.md`
- Use the prompt templates in `prompts/` with Cursor Chat

### Windsurf

- Windsurf rules are in `.windsurf/rules/agentspec.md`
- Use the prompt templates with Windsurf's AI features

### Generic IDE (Any AI Chat)

Copy the content of prompt files into your IDE's AI chat:
- `prompts/create-agent.md` for creating agents
- `prompts/create-skill.md` for creating skills
- `prompts/list-configs.md` for listing configurations

---

## Adding New Agents

### Step 1: Create Agent Directory

```bash
mkdir -p agents/{agent-name}
```

### Step 2: Create agent.yaml

Required fields:

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Kebab-case agent name |
| `description` | string | Yes | What the agent does |
| `version` | string | Yes | Semantic version (e.g., 1.0.0) |
| `author` | string | No | Author name or team |
| `model_preferences` | list | No | Preferred AI models |
| `tags` | list | No | Categorization tags |
| `system_prompt` | string | No | Agent's system prompt / persona |
| `inputs` | list | No | Expected inputs with name, description, required |
| `outputs` | list | No | Expected outputs with name, description, format |
| `tools` | list | No | Tools the agent can use |

### Step 3: Create prompt.md

The prompt file should include:
- Agent role and expertise description
- Step-by-step instructions
- Output template/format
- Usage guide with sample questions

### Step 4: Validate

```bash
./scripts/agentspec.sh validate
```

---

## Adding New Skills

Skills differ from agents in that they define a sequence of **steps** to accomplish a task.

### Step 1: Create Skill Directory

```bash
mkdir -p skills/{skill-name}
```

### Step 2: Create skill.yaml

Same fields as agent.yaml, plus:

| Field | Type | Required | Description |
|---|---|---|---|
| `steps` | list | Recommended | Sequential steps with name and description |

### Step 3: Create prompt.md

The prompt file should include:
- Skill description and purpose
- Step-by-step execution instructions
- Output template with examples
- Usage guide

### Step 4: Validate

```bash
./scripts/agentspec.sh validate
```

---

## Using GenAI Chat for Creation

Instead of using the CLI, you can use your IDE's AI chat with the prompt templates:

1. Open the relevant prompt file from `prompts/`
2. Copy its content into your AI chat (Copilot Chat, Cursor Chat, etc.)
3. The AI will guide you through creating the configuration interactively
4. It will generate the YAML and prompt files for you

This approach leverages the agentic mode of GenAI tools to create well-structured configurations through conversation.

---

## Conventions

- All names use **kebab-case** (lowercase with hyphens)
- Each agent/skill gets its own directory
- YAML configs are the source of truth for metadata
- Prompt files contain the detailed behavioral instructions
- Version follows semantic versioning (MAJOR.MINOR.PATCH)
- Tags should be lowercase, descriptive, and aid discoverability

## Validation Rules

- `name` must be kebab-case and match the directory name
- `description` must be non-empty
- `version` must follow semantic versioning
- YAML must be parseable
- `prompt.md` should exist alongside every config
