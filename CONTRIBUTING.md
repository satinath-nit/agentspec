# Contributing to AgentSpec

Thank you for your interest in contributing to AgentSpec! This guide covers everything you need to set up your local development environment, make changes, and submit a pull request.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Development Setup](#development-setup)
  - [Prerequisites](#prerequisites)
  - [Clone and Install](#clone-and-install)
  - [Verify Your Setup](#verify-your-setup)
- [Project Architecture](#project-architecture)
- [Development Workflow](#development-workflow)
  - [Branch Naming](#branch-naming)
  - [Test-Driven Development (TDD)](#test-driven-development-tdd)
  - [Making Changes](#making-changes)
  - [Running Tests](#running-tests)
  - [Linting](#linting)
- [Types of Contributions](#types-of-contributions)
  - [Adding a New Agent](#adding-a-new-agent)
  - [Adding a New Skill](#adding-a-new-skill)
  - [Adding IDE Support](#adding-ide-support)
  - [CLI Improvements](#cli-improvements)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Release Process](#release-process)

---

## Code of Conduct

Be respectful, inclusive, and constructive. We are building tools for the community and expect all contributors to act accordingly.

---

## Development Setup

### Prerequisites

| Tool | Version | Installation |
|---|---|---|
| **Python** | 3.11+ | [python.org](https://www.python.org/downloads/) or your OS package manager |
| **pip** | Latest | Comes with Python (`python3 -m pip install --upgrade pip`) |
| **Git** | Any | [git-scm.com](https://git-scm.com/) |
| **Task** | Any | [taskfile.dev](https://taskfile.dev/installation/) (optional but recommended) |

### Clone and Install

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/agentspec.git
cd agentspec

# Install in editable mode with test dependencies
pip install -e ".[test]"

# Copy the environment template
cp .env.example .env
```

This installs:
- The `agentspec` CLI command (editable, so changes take effect immediately)
- Runtime dependencies: `typer`, `rich`, `readchar`, `pyyaml`
- Test dependencies: `pytest`, `pytest-cov`

### Verify Your Setup

```bash
# Check the CLI works
agentspec --help

# Run the full CI pipeline
task ci
```

Expected result: all lint checks pass, all configurations validate, and all 113 tests pass (46 Python + 34 validation + 33 CLI integration).

---

## Project Architecture

```
agentspec/
├── src/agentspec_cli/          # Python CLI package
│   ├── __init__.py             # Entry point: main() function
│   ├── banner.py               # ASCII art banner and tagline
│   ├── ide.py                  # IDE configs, interactive selector, config generators
│   └── commands.py             # All CLI commands (init, new-agent, new-skill, list, validate)
├── agents/                     # Agent configurations (community-contributed)
├── skills/                     # Skill configurations (community-contributed)
├── templates/                  # YAML templates used by the CLI for scaffolding
├── prompts/                    # GenAI prompt templates for IDE chat integration
├── tests/
│   ├── test_commands.py        # Python unit tests (pytest)
│   ├── test_validate.sh        # Bash structure/YAML validation tests
│   └── test_cli.sh             # Bash CLI integration tests
├── pyproject.toml              # Package config, dependencies, pytest settings
├── Taskfile.yml                # Task runner commands
└── AGENTS.md                   # Project-level agent conventions
```

### Key Modules

| Module | Responsibility |
|---|---|
| `banner.py` | ASCII art `BANNER` constant, `TAGLINE` string, `show_banner()` display function |
| `ide.py` | `AGENT_CONFIG` dict (18 IDEs), `select_ide()` interactive selector with `readchar` + `rich.Live`, `generate_ide_config()` dispatches to per-IDE generators, `generate_vscode_config()` creates `.vscode/` settings |
| `commands.py` | `typer.Typer` app with all commands, template constants (AGENTS_MD, GITIGNORE, etc.), `to_kebab_case()` utility, command implementations for `init`, `new-agent`, `new-skill`, `list`, `validate` |

---

## Development Workflow

### Branch Naming

Use descriptive branch names with a category prefix:

```
feature/add-code-reviewer-agent
feature/add-ide-support-zed
fix/validate-missing-version-field
docs/update-installation-guide
```

### Test-Driven Development (TDD)

We follow TDD. The workflow is:

1. **Write a failing test** that describes the expected behavior
2. **Implement the minimum code** to make the test pass
3. **Refactor** while keeping all tests green

```bash
# Run tests in watch mode during development
PYTHONPATH=src python3 -m pytest tests/test_commands.py -v --tb=short
```

### Making Changes

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/my-change
   ```

2. Make your changes in the appropriate module

3. Add or update tests in `tests/test_commands.py`

4. Run the full test suite:
   ```bash
   task ci
   ```

5. Commit your changes (see [Commit Guidelines](#commit-guidelines))

### Running Tests

| Command | What It Runs |
|---|---|
| `task test` | All three test suites |
| `task test-python` | Python unit tests only (pytest) |
| `task test-cli` | CLI integration tests only (bash) |
| `task test-validate` | Structure validation tests only (bash) |
| `task ci` | Lint + validate + all tests |

**Run a single test:**

```bash
PYTHONPATH=src python3 -m pytest tests/test_commands.py::TestInitCommand::test_init_creates_agents_md -v
```

**Run tests with coverage:**

```bash
PYTHONPATH=src python3 -m pytest tests/test_commands.py --cov=agentspec_cli --cov-report=term-missing
```

### Linting

```bash
task lint
```

This runs:
- **YAML lint** - Validates all `.yaml` files in `agents/`, `skills/`, and `templates/`
- **Markdown check** - Verifies every agent/skill directory has a `prompt.md`

---

## Types of Contributions

### Adding a New Agent

The simplest contribution is sharing a useful agent configuration.

1. Create the agent using the CLI:
   ```bash
   agentspec new-agent
   ```

2. Edit `agents/{name}/agent.yaml` to customize:
   - Write a detailed `system_prompt` with clear instructions
   - Define specific `inputs` and `outputs`
   - Add relevant `tags` for discoverability
   - List `tools` the agent can use

3. Edit `agents/{name}/prompt.md` with:
   - What the agent does
   - How to use it
   - Example inputs and expected outputs

4. Validate:
   ```bash
   agentspec validate
   ```

5. Submit a PR with just the `agents/{name}/` directory.

### Adding a New Skill

Same as adding an agent, but skills also have a `steps` field:

```yaml
steps:
  - name: step_one
    description: What this step does
  - name: step_two
    description: What this step does
```

Use `agentspec new-skill` to scaffold, then customize.

### Adding IDE Support

To add a new IDE/AI assistant:

1. **Add to `AGENT_CONFIG`** in `src/agentspec_cli/ide.py`:
   ```python
   AGENT_CONFIG = {
       ...
       "my-ide": {"name": "My IDE", "folder": ".my-ide/", "requires_cli": False},
   }
   ```

2. **Create a generator function** in `ide.py`:
   ```python
   def _gen_my_ide(p: Path) -> None:
       _write(
           p / ".my-ide" / "config.md",
           f"# My IDE Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}",
       )
   ```

3. **Register it** in `generate_ide_config()`:
   ```python
   configs = {
       ...
       "my-ide": _gen_my_ide,
   }
   ```

4. **Add tests** in `tests/test_commands.py`:
   ```python
   def test_generate_my_ide_config(self, tmp_path):
       generate_ide_config(tmp_path, "my-ide")
       assert (tmp_path / ".my-ide" / "config.md").exists()
   ```

5. **Add a CLI integration test** in `tests/test_cli.sh`:
   ```bash
   TEST_MY_IDE="$TMPDIR/test-my-ide"
   $CLI init "$TEST_MY_IDE" --ide my-ide --non-interactive 2>&1 || true
   if [ -f "$TEST_MY_IDE/.my-ide/config.md" ]; then
     pass "init --ide my-ide creates .my-ide/config.md"
   else
     fail "init --ide my-ide did not create config"
   fi
   ```

### CLI Improvements

For changes to the CLI commands:

1. Write tests first in `tests/test_commands.py`
2. Implement in the appropriate module (`commands.py`, `ide.py`, or `banner.py`)
3. Update `tests/test_cli.sh` if the change affects CLI behavior
4. Update the README if the change affects user-facing behavior

---

## Commit Guidelines

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <short description>

<optional body>
```

**Types:**

| Type | When to Use |
|---|---|
| `feat` | New feature or agent/skill |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `test` | Adding or updating tests |
| `refactor` | Code restructuring (no behavior change) |
| `chore` | Build, CI, dependency updates |

**Examples:**

```
feat: add code-reviewer agent configuration
fix: validate command now checks for empty YAML files
docs: add troubleshooting section to README
test: add integration tests for gemini IDE config
```

---

## Pull Request Process

1. **Ensure all tests pass**: Run `task ci` before pushing
2. **Keep PRs focused**: One feature or fix per PR
3. **Update documentation**: If your change affects user-facing behavior, update the README
4. **Add tests**: Every new feature or bug fix should include tests
5. **Fill out the PR template**: Describe what changed and why

### PR Checklist

- [ ] All tests pass (`task ci`)
- [ ] New tests added for new functionality
- [ ] README updated if user-facing changes
- [ ] Commit messages follow conventional commits
- [ ] No secrets or credentials in the code
- [ ] YAML files validate (`agentspec validate`)

---

## Release Process

1. Update `version` in `pyproject.toml`
2. Update any version references in documentation
3. Run `task ci` to verify everything passes
4. Create a git tag: `git tag v1.x.x`
5. Build the package: `task package`
6. Create a GitHub release with the zip artifact

---

**Questions?** Open an issue on GitHub and we will help you get started.
