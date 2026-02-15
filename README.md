# AgentSpec

> An open-source toolkit for creating, managing, and sharing AI agent configurations and skills. Define your agent behaviors as structured YAML configurations, pair them with prompt files, and let your IDE's AI assistant use them to deliver consistent, repeatable results across your team.

Built with Python using [typer](https://typer.tiangolo.com/), [rich](https://rich.readthedocs.io/), and [readchar](https://github.com/magmax/python-readchar) for a polished interactive terminal experience.

---

## Table of Contents

- [Why AgentSpec?](#why-agentspec)
- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Your First Project](#your-first-project)
- [Usage Guide](#usage-guide)
  - [Creating Agents](#creating-agents)
  - [Creating Skills](#creating-skills)
  - [Listing Configurations](#listing-configurations)
  - [Validating Configurations](#validating-configurations)
  - [Using GenAI Chat (Agentic Mode)](#using-genai-chat-agentic-mode)
- [CLI Reference](#cli-reference)
- [Configuration Schema](#configuration-schema)
  - [Agent Schema (agent.yaml)](#agent-schema-agentyaml)
  - [Skill Schema (skill.yaml)](#skill-schema-skillyaml)
  - [Example: Agent Configuration](#example-agent-configuration)
  - [Example: Skill Configuration](#example-skill-configuration)
- [IDE / AI Assistant Integration](#ide--ai-assistant-integration)
- [Project Structure](#project-structure)
- [Taskfile Commands](#taskfile-commands)
- [Testing](#testing)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [License](#license)

---

## Why AgentSpec?

Modern IDEs ship with powerful AI assistants (Copilot, Claude, Cursor, Windsurf, etc.), but there is no standard way to **define, version, and share** the agent behaviors and skills that drive them. AgentSpec solves this by providing:

- **A specification format** for agent behaviors and skills (YAML + Markdown)
- **A CLI tool** that scaffolds projects, generates IDE-specific config files, and validates everything
- **IDE-aware bootstrapping** so each team member gets the right config for their editor from day one
- **GenAI prompt templates** that let you create new agents and skills conversationally inside your IDE

Think of it as `package.json` for AI agent behaviors.

---

## Features

| Feature | Description |
|---|---|
| **Interactive TUI** | Professional terminal UI with ASCII banner, bordered panels, and arrow-key IDE selector |
| **18 IDE/AI Assistants** | copilot, claude, gemini, cursor-agent, qwen, opencode, codex, windsurf, kilocode, auggie, codebuddy, qoder, roo, q, amp, shai, bob, devin |
| **Agent Configurations** | Define agent personas with system prompts, inputs, outputs, tools, and model preferences |
| **Skills** | Create reusable, step-based skill definitions for specific tasks |
| **GenAI Agentic Mode** | Create agents/skills conversationally using prompt templates in your IDE's AI chat |
| **Validation** | Automated YAML validation and structure checks for all configurations |
| **Templates** | Starter templates for quickly scaffolding new agents and skills |
| **Sample Configs** | PRD Generator, ADR Creator agents and JIRA Story Creator skill included out of the box |

---

## Getting Started

### Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| **Python** | 3.11 or higher | Required for the CLI |
| **uv** | Latest | Recommended package manager ([docs.astral.sh/uv](https://docs.astral.sh/uv/)) |
| **Git** | Any | Optional; for version control |

**Check your Python version:**

```bash
python3 --version
```

### Installation

Choose your preferred installation method:

#### Option 1: Persistent Installation (Recommended)

Install once and use everywhere:

```bash
uv tool install agentspec-cli --from git+https://github.com/your-org/agentspec.git
```

Or with `pipx`:

```bash
pipx install git+https://github.com/your-org/agentspec.git
```

Or with `pip`:

```bash
pip install git+https://github.com/your-org/agentspec.git
```

Then use the tool directly:

```bash
# Create new project
agentspec init <PROJECT_NAME>

# Or initialize in an existing project directory
agentspec init . --ide claude --non-interactive
```

To upgrade AgentSpec:

```bash
uv tool install agentspec-cli --force --from git+https://github.com/your-org/agentspec.git
```

#### Option 2: One-time Usage

Run directly without installing:

```bash
uvx --from git+https://github.com/your-org/agentspec.git agentspec init <PROJECT_NAME>
```

Benefits of persistent installation:

- Tool stays installed and available in PATH
- No need to create shell aliases
- Better tool management with `uv tool list`, `uv tool upgrade`, `uv tool uninstall`
- Cleaner shell configuration

**Verify the installation:**

```bash
agentspec --help
```

You should see the AgentSpec banner and a list of available commands.

### Your First Project

**Step 1: Initialize a project**

```bash
agentspec init my-ai-project
```

This launches the interactive setup:

1. Displays the AgentSpec ASCII banner
2. Shows a project setup summary panel (name, path)
3. Presents an arrow-key navigable **"Choose your AI assistant"** selector with all 18 supported IDEs
4. Generates the selected IDE's configuration files
5. Creates the full project scaffold (directories, templates, prompts, `.gitignore`, `.env.example`)
6. Shows a completion panel with next steps

> **CI/CD or scripting?** Use non-interactive mode:
> ```bash
> agentspec init my-ai-project --ide copilot --non-interactive
> ```

**Step 2: Create your first agent**

```bash
cd my-ai-project
agentspec new-agent
```

Follow the prompts to enter a name, description, author, and tags. The CLI creates `agents/{name}/agent.yaml` and `agents/{name}/prompt.md`.

**Step 3: Validate your project**

```bash
agentspec validate
```

This checks all YAML files for required fields (`name`, `description`, `version`) and reports any issues.

---

## Usage Guide

### Creating Agents

An **agent** is a reusable AI persona with a defined system prompt, expected inputs, outputs, and available tools.

**Interactive mode** (prompts for all fields):

```bash
agentspec new-agent
```

**Non-interactive mode** (for scripting/CI):

```bash
agentspec new-agent \
  --name "code-reviewer" \
  --description "Reviews code for quality, security, and best practices" \
  --non-interactive
```

**What gets created:**

```
agents/code-reviewer/
  agent.yaml    # Agent configuration (name, description, system_prompt, inputs, outputs, tools)
  prompt.md     # Human-readable instructions for using the agent
```

### Creating Skills

A **skill** is a step-based task definition. Unlike agents (which are personas), skills are sequences of actions.

**Interactive mode:**

```bash
agentspec new-skill
```

**Non-interactive mode:**

```bash
agentspec new-skill \
  --name "api-test-generator" \
  --description "Generates API integration tests from OpenAPI specs" \
  --non-interactive
```

**What gets created:**

```
skills/api-test-generator/
  skill.yaml    # Skill configuration (includes steps field)
  prompt.md     # Human-readable instructions
```

### Listing Configurations

View all agents and skills in the current project:

```bash
agentspec list
```

Specify a different project directory:

```bash
agentspec list --project-dir /path/to/project
```

### Validating Configurations

Check that all YAML configs have the required fields and are well-formed:

```bash
agentspec validate
```

The validator checks:
- Every `agent.yaml` has `name`, `description`, and `version`
- Every `skill.yaml` has `name`, `description`, and `version`
- All YAML files parse without errors

### Using GenAI Chat (Agentic Mode)

AgentSpec includes **prompt templates** designed for use with your IDE's AI chat. This is the most powerful way to create agents and skills because the AI guides you through the process conversationally.

1. Open one of the prompt files in your IDE:
   - `prompts/create-agent.md` - Create a new agent
   - `prompts/create-skill.md` - Create a new skill
   - `prompts/list-configs.md` - List existing configurations
2. Copy the content into your AI chat (Copilot Chat, Cursor Chat, Claude, etc.)
3. The AI will ask you questions and generate the complete configuration files

This works with any IDE that supports AI chat: VS Code + Copilot, Cursor, Windsurf, Claude Code, etc.

---

## CLI Reference

```
agentspec [OPTIONS] COMMAND [ARGS]
```

### Commands

| Command | Description |
|---|---|
| `init <path>` | Initialize a new agentspec project with interactive IDE selection |
| `new-agent` | Create a new agent configuration (interactive or non-interactive) |
| `new-skill` | Create a new skill configuration (interactive or non-interactive) |
| `list` | List all agents and skills in the project |
| `validate` | Validate all agent and skill YAML configurations |

### Global Options

| Option | Description |
|---|---|
| `--help` | Show help message and exit |

### Command Options

**`init`**

| Option | Type | Default | Description |
|---|---|---|---|
| `--ide` | string | *(interactive)* | IDE/AI assistant to configure (e.g., `copilot`, `claude`, `cursor-agent`) |
| `--non-interactive` | flag | `false` | Skip interactive prompts; requires `--ide` |

**`new-agent` / `new-skill`**

| Option | Type | Default | Description |
|---|---|---|---|
| `--name` | string | *(interactive)* | Name in kebab-case (e.g., `code-reviewer`) |
| `--description` | string | *(interactive)* | What the agent/skill does |
| `--project-dir` | path | current dir | Project root directory |
| `--non-interactive` | flag | `false` | Skip interactive prompts; requires `--name` and `--description` |

**`list` / `validate`**

| Option | Type | Default | Description |
|---|---|---|---|
| `--project-dir` | path | current dir | Project root directory |

---

## Configuration Schema

### Agent Schema (agent.yaml)

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Unique kebab-case identifier (e.g., `prd-generator`) |
| `description` | string | Yes | Clear description of what the agent does |
| `version` | string | Yes | Semantic version (e.g., `1.0.0`) |
| `author` | string | No | Author or team name |
| `model_preferences` | list[string] | No | Preferred AI models in order (e.g., `gpt-4`, `claude-sonnet`) |
| `tags` | list[string] | No | Categorization tags (e.g., `product`, `documentation`) |
| `system_prompt` | string | No | The agent's persona and instructions |
| `inputs` | list[object] | No | Expected inputs (each with `name`, `description`, `required`) |
| `outputs` | list[object] | No | Expected outputs (each with `name`, `description`, `format`) |
| `tools` | list[object] | No | Available tools (each with `name`, `description`) |

### Skill Schema (skill.yaml)

Same as the agent schema, plus:

| Field | Type | Required | Description |
|---|---|---|---|
| `steps` | list[object] | Recommended | Ordered execution steps (each with `name`, `description`) |

### Example: Agent Configuration

```yaml
name: prd-generator
description: >
  Generates comprehensive Product Requirements Documents (PRDs) from
  high-level product ideas and user inputs.
version: 1.0.0
author: agentspec
model_preferences:
  - gpt-4
  - claude-sonnet
  - gemini-pro
tags:
  - product
  - requirements
  - documentation

system_prompt: |
  You are an expert Product Manager and Requirements Engineer. Your role
  is to help create comprehensive PRDs from user inputs.

  Follow this structure:
  1. Product Overview
  2. Goals & Objectives
  3. Target Users
  4. User Stories
  5. Functional Requirements
  6. Non-Functional Requirements
  7. Acceptance Criteria
  8. Dependencies & Assumptions
  9. Timeline & Milestones
  10. Success Metrics

inputs:
  - name: product_idea
    description: High-level description of the product or feature
    required: true
  - name: target_audience
    description: Who the product is for
    required: false

outputs:
  - name: prd_document
    description: Complete PRD in markdown format
    format: markdown

tools:
  - name: file_write
    description: Write the PRD to a file
```

### Example: Skill Configuration

```yaml
name: jira-story-creator
description: >
  Creates well-structured JIRA user stories with acceptance criteria,
  story points estimation, and proper labeling.
version: 1.0.0
author: agentspec
tags:
  - jira
  - agile
  - user-stories

system_prompt: |
  You are an expert Agile coach and JIRA story writer. Create
  well-structured stories from requirements or feature descriptions.

inputs:
  - name: requirement
    description: The feature or requirement to create stories for
    required: true
  - name: project_key
    description: JIRA project key (e.g., PROJ)
    required: false
    default: PROJ

outputs:
  - name: stories
    description: List of JIRA stories in structured format
    format: markdown

steps:
  - name: analyze_requirement
    description: Break down the requirement into implementable chunks
  - name: create_stories
    description: Generate individual user stories
  - name: estimate_points
    description: Estimate story points for each story
  - name: add_acceptance_criteria
    description: Write acceptance criteria in Given/When/Then format
  - name: review_and_refine
    description: Review stories for completeness and consistency
```

---

## IDE / AI Assistant Integration

The `agentspec init` command generates IDE-specific configuration files so your AI assistant understands the project from the start. Every project also gets `.vscode/` settings regardless of the selected IDE.

| IDE Key | Assistant Name | Config Generated |
|---|---|---|
| `copilot` | GitHub Copilot | `.github/copilot-instructions.md` |
| `claude` | Claude Code | `CLAUDE.md` |
| `cursor-agent` | Cursor | `.cursor/rules/agentspec.md` |
| `gemini` | Gemini CLI | `.gemini/settings.json` |
| `windsurf` | Windsurf | `.windsurf/rules/agentspec.md` |
| `codex` | Codex CLI | `.codex/instructions.md` |
| `devin` | Devin | `.devin/instructions.md` |
| `roo` | Roo Code | `.roo` |
| `q` | Amazon Q Developer CLI | `.q` |
| `amp` | Amp | `.amp` |
| `qwen` | Qwen Code | `.qwen` |
| `opencode` | opencode | `.opencode` |
| `kilocode` | Kilo Code | `.kilocode` |
| `auggie` | Auggie CLI | `.auggie` |
| `codebuddy` | CodeBuddy | `.codebuddy` |
| `qoder` | Qoder CLI | `.qoder` |
| `shai` | SHAI | `.shai` |
| `bob` | IBM Bob | `.bob` |

Each generated config file contains project context (structure, conventions, available commands) so the AI assistant can help you work with AgentSpec effectively.

---

## Project Structure

An AgentSpec project created with `agentspec init` has the following layout:

```
my-project/
├── AGENTS.md                      # Project-level agent conventions and overview
├── .gitignore                     # Ignores .env, __pycache__, build artifacts
├── .env.example                   # Environment variable template with docs
├── agents/                        # Agent configurations
│   └── {agent-name}/
│       ├── agent.yaml             # Agent definition (YAML)
│       └── prompt.md              # Detailed instructions (Markdown)
├── skills/                        # Skill configurations
│   └── {skill-name}/
│       ├── skill.yaml             # Skill definition (YAML)
│       └── prompt.md              # Detailed instructions (Markdown)
├── templates/                     # Templates used by the CLI
│   ├── agent/
│   │   └── agent.yaml
│   └── skill/
│       └── skill.yaml
├── prompts/                       # GenAI chat prompt templates
│   ├── create-agent.md            # Paste into AI chat to create an agent
│   ├── create-skill.md            # Paste into AI chat to create a skill
│   └── list-configs.md            # Paste into AI chat to list configs
├── scripts/
│   └── agentspec.sh               # Legacy bash CLI (kept for reference)
├── tests/                         # Test directory
├── .vscode/                       # VS Code settings, tasks, extensions
│   ├── settings.json
│   ├── tasks.json
│   └── extensions.json
└── .{ide}/                        # IDE-specific config (varies by selection)
```

---

## Taskfile Commands

If you have [Task](https://taskfile.dev/) installed and are working from a local clone (see [Contributing](#contributing)), use these shortcuts:

| Command | Description |
|---|---|
| `task install` | Install the CLI in editable mode (for contributors only) |
| `task validate` | Validate all agent and skill configurations |
| `task list` | List all agents and skills |
| `task new-agent` | Create a new agent (interactive) |
| `task new-skill` | Create a new skill (interactive) |
| `task test` | Run all tests (validation + Python + CLI integration) |
| `task test-python` | Run Python unit tests only (`pytest`) |
| `task test-cli` | Run CLI integration tests only |
| `task lint` | Lint YAML files and check markdown |
| `task ci` | Full CI pipeline: lint + validate + test |
| `task package` | Create a distributable zip of the project |
| `task clean` | Remove temporary and generated files |

---

## Testing

AgentSpec has three layers of tests:

| Test Suite | Runner | Count | What It Tests |
|---|---|---|---|
| **Python unit tests** | `pytest` | 46 | Banner, IDE configs, all CLI commands, validation logic |
| **Structure validation** | Bash | 34 | File existence, YAML validity, project structure |
| **CLI integration** | Bash | 33 | End-to-end CLI commands, IDE-specific outputs, TUI display |

**Run all tests:**

```bash
task test
```

**Run individual test suites:**

```bash
# Python unit tests
PYTHONPATH=src python3 -m pytest tests/test_commands.py -v

# Structure validation
bash tests/test_validate.sh

# CLI integration
bash tests/test_cli.sh
```

**Full CI pipeline** (lint + validate + test):

```bash
task ci
```

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide.

> **Note:** Contributing requires cloning the repo. End users should install via `pipx` or `uv tool install` as described in [Installation](#installation).

### Quick Start for Contributors

```bash
# 1. Fork and clone
git clone https://github.com/your-username/agentspec.git
cd agentspec

# 2. Install in development mode with test deps
pip install -e ".[test]"

# 3. Run the full test suite to verify your setup
task ci

# 4. Create a feature branch
git checkout -b feature/my-improvement

# 5. Make changes following TDD:
#    a. Write a failing test
#    b. Implement the feature
#    c. Verify the test passes

# 6. Run tests and linting
task ci

# 7. Commit and push
git add agents/my-agent/agent.yaml agents/my-agent/prompt.md
git commit -m "feat: add my-agent configuration"
git push origin feature/my-improvement

# 8. Open a Pull Request
```

### Ways to Contribute

- **Add new agents** - Share useful agent configurations with the community
- **Add new skills** - Create reusable skill definitions
- **Add IDE support** - Extend the IDE selector with new AI assistants
- **Improve the CLI** - Bug fixes, new features, better UX
- **Improve documentation** - Tutorials, examples, translations
- **Report bugs** - File issues with reproduction steps

---

## Troubleshooting

### `agentspec: command not found`

The CLI is not installed or not on your PATH. Install it:

```bash
uv tool install agentspec-cli --from git+https://github.com/your-org/agentspec.git
```

Or with pip:

```bash
pip install git+https://github.com/your-org/agentspec.git
```

If using `pip` with a virtual environment, make sure it is activated.

### `Python 3.11+ required`

AgentSpec requires Python 3.11 or higher. Check your version:

```bash
python3 --version
```

If you have multiple Python versions, try:

```bash
python3.11 -m pip install git+https://github.com/your-org/agentspec.git
```

### `ModuleNotFoundError: No module named 'agentspec_cli'`

When running tests directly (contributors only), set the Python path:

```bash
PYTHONPATH=src python3 -m pytest tests/test_commands.py -v
```

### YAML validation fails

Check that your YAML files have the required fields:

```yaml
name: my-agent           # Required: kebab-case
description: What it does # Required
version: 1.0.0           # Required: semver
```

### Interactive selector not working

The arrow-key selector requires a real terminal (TTY). If running in a non-interactive context (CI, piped output), use `--non-interactive` with `--ide`:

```bash
agentspec init my-project --ide copilot --non-interactive
```

---

## Roadmap

- [ ] `agentspec publish` - Share agents/skills to a community registry
- [ ] `agentspec import` - Import agents/skills from the registry
- [ ] JSON Schema validation for agent.yaml and skill.yaml
- [ ] GitHub Actions workflow for automated validation
- [ ] Plugin architecture for custom IDE generators
- [ ] Web-based configuration editor
- [ ] Agent composition (agents that use other agents)
- [ ] Skill chaining (sequential skill execution)

---

## License

MIT License - See [LICENSE](LICENSE) for details.

---

**Built with care for the AI-assisted development community.**
