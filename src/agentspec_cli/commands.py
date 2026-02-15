import os
import re
import shutil
import sys
from pathlib import Path
from typing import Optional

import typer
import yaml
from rich.align import Align
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.text import Text
from typer.core import TyperGroup

from agentspec_cli.banner import BANNER, TAGLINE, show_banner
from agentspec_cli.ide import (
    AGENT_CONFIG,
    generate_ide_config,
    generate_vscode_config,
    get_ide_label,
    select_ide,
)

console = Console()


class BannerGroup(TyperGroup):
    def format_help(self, ctx, formatter):
        show_banner()
        super().format_help(ctx, formatter)


app = typer.Typer(
    name="agentspec",
    help="AgentSpec - AI Agent Configuration Toolkit. Quickly create and manage agent configurations and skills.",
    add_completion=False,
    invoke_without_command=True,
    cls=BannerGroup,
)


@app.callback()
def callback(ctx: typer.Context):
    if ctx.invoked_subcommand is None and "--help" not in sys.argv and "-h" not in sys.argv:
        show_banner()
        console.print(Align.center("[dim]Run 'agentspec --help' for usage information[/dim]"))
        console.print()


def to_kebab_case(name: str) -> str:
    s = name.lower().strip()
    s = re.sub(r"[^a-z0-9-]", "-", s)
    s = re.sub(r"-+", "-", s)
    return s.strip("-")


AGENTS_MD = """\
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
agentspec new-agent

# Create a new skill
agentspec new-skill

# List all configurations
agentspec list

# Validate configurations
agentspec validate
```

## IDE Integration

Use the prompt templates in `prompts/` with your IDE's AI chat:
- `/agentspec.create-agent` - Create a new agent via chat
- `/agentspec.create-skill` - Create a new skill via chat
- `/agentspec.list` - List available configurations
"""

GITIGNORE = """\
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
"""

ENV_EXAMPLE = """\
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
"""

CREATE_AGENT_PROMPT = """\
# Create New Agent Configuration

Help me create a new AgentSpec agent configuration.

## What I need:
1. Ask me for the agent name (kebab-case)
2. Ask me for a description
3. Ask me what the agent should do (system prompt)
4. Ask me for input/output specifications
5. Generate the `agent.yaml` and `prompt.md` files

## Output Structure:
- Create directory: `agents/{name}/`
- Create `agents/{name}/agent.yaml` with fields: name, description, version, author, model_preferences, tags, system_prompt, inputs, outputs, tools
- Create `agents/{name}/prompt.md` with detailed instructions

## Validation:
- Name must be kebab-case
- YAML must include: name, description, version
"""

CREATE_SKILL_PROMPT = """\
# Create New Skill Configuration

Help me create a new AgentSpec skill configuration.

## What I need:
1. Ask me for the skill name (kebab-case)
2. Ask me for a description
3. Ask me what steps the skill performs
4. Ask me for input/output specifications
5. Generate the `skill.yaml` and `prompt.md` files

## Output Structure:
- Create directory: `skills/{name}/`
- Create `skills/{name}/skill.yaml` with fields: name, description, version, author, tags, system_prompt, inputs, outputs, steps
- Create `skills/{name}/prompt.md` with detailed instructions

## Validation:
- Name must be kebab-case
- YAML must include: name, description, version, steps
"""

LIST_CONFIGS_PROMPT = """\
# List AgentSpec Configurations

List all available agent configurations and skills in this project.

## Agents
Look in the `agents/` directory. Each subdirectory contains:
- `agent.yaml` - Agent configuration
- `prompt.md` - Detailed instructions

## Skills
Look in the `skills/` directory. Each subdirectory contains:
- `skill.yaml` - Skill configuration
- `prompt.md` - Detailed instructions

Show the name, description, and version of each configuration found.
"""

AGENT_TEMPLATE = """\
name: {{AGENT_NAME}}
description: {{AGENT_DESCRIPTION}}
version: 1.0.0
author: {{AUTHOR}}
model_preferences:
  - gpt-4
  - claude-sonnet
  - gemini-pro
tags:
  - {{TAG1}}
  - {{TAG2}}

system_prompt: |
  {{SYSTEM_PROMPT}}

inputs:
  - name: {{INPUT_NAME}}
    description: {{INPUT_DESCRIPTION}}
    required: true

outputs:
  - name: {{OUTPUT_NAME}}
    description: {{OUTPUT_DESCRIPTION}}
    format: markdown

tools:
  - name: file_write
    description: Write output to a file
"""

SKILL_TEMPLATE = """\
name: {{SKILL_NAME}}
description: {{SKILL_DESCRIPTION}}
version: 1.0.0
author: {{AUTHOR}}
tags:
  - {{TAG1}}
  - {{TAG2}}

system_prompt: |
  {{SYSTEM_PROMPT}}

inputs:
  - name: {{INPUT_NAME}}
    description: {{INPUT_DESCRIPTION}}
    required: true

outputs:
  - name: {{OUTPUT_NAME}}
    description: {{OUTPUT_DESCRIPTION}}
    format: markdown

steps:
  - name: analyze
    description: Analyze the input requirements
  - name: generate
    description: Generate the output
  - name: review
    description: Review and refine the output
"""


def _get_script_source() -> Optional[Path]:
    src = Path(__file__).parent.parent.parent / "scripts" / "agentspec.sh"
    if src.exists():
        return src
    return None


@app.command()
def init(
    project_path: str = typer.Argument(..., help="Path for the new project"),
    ide: Optional[str] = typer.Option(None, "--ide", help="IDE/AI assistant to configure"),
    non_interactive: bool = typer.Option(False, "--non-interactive", help="Skip interactive prompts"),
):
    """Initialize a new agentspec project with IDE-specific configuration."""
    show_banner()

    p = Path(project_path)

    if p.exists() and any(p.iterdir()):
        item_count = len(list(p.iterdir()))
        console.print(f"[yellow]Warning: Directory is not empty ({item_count} items)[/yellow]")
        console.print("Template files will be merged with existing content and may overwrite existing files")
        if not non_interactive:
            confirm = typer.confirm("Do you want to continue?", default=False)
            if not confirm:
                raise typer.Exit(0)
        console.print()

    project_name = p.name
    abs_path = str(p.resolve())

    setup_table = Table.grid(padding=(0, 2))
    setup_table.add_column(style="bold", width=16)
    setup_table.add_column(style="green")
    setup_table.add_row("Project", project_name)
    setup_table.add_row("Working Path", abs_path)

    console.print(Panel(
        setup_table,
        title="[bold]AgentSpec Project Setup[/bold]",
        border_style="cyan",
        padding=(1, 2),
    ))
    console.print()

    selected_ide = ide
    if not selected_ide:
        if non_interactive:
            selected_ide = "copilot"
        else:
            selected_ide = select_ide()
            if not selected_ide:
                console.print("[red]IDE selection cancelled[/red]")
                raise typer.Exit(1)

    ide_label = get_ide_label(selected_ide)
    console.print(f"  [green]▶[/green] IDE/AI assistant: [bold]{selected_ide}[/bold] ({ide_label})")
    console.print()

    p.mkdir(parents=True, exist_ok=True)
    for d in ["agents", "skills", "templates/agent", "templates/skill", "prompts", "scripts", "tests"]:
        (p / d).mkdir(parents=True, exist_ok=True)
    console.print("  [green]●[/green] Created project directories")

    (p / "AGENTS.md").write_text(AGENTS_MD)
    console.print("  [green]●[/green] Created AGENTS.md")

    (p / ".gitignore").write_text(GITIGNORE)
    console.print("  [green]●[/green] Created .gitignore")

    (p / ".env.example").write_text(ENV_EXAMPLE)
    console.print("  [green]●[/green] Created .env.example")

    (p / "templates" / "agent" / "agent.yaml").write_text(AGENT_TEMPLATE)
    (p / "templates" / "skill" / "skill.yaml").write_text(SKILL_TEMPLATE)
    console.print("  [green]●[/green] Created templates")

    (p / "prompts" / "create-agent.md").write_text(CREATE_AGENT_PROMPT)
    (p / "prompts" / "create-skill.md").write_text(CREATE_SKILL_PROMPT)
    (p / "prompts" / "list-configs.md").write_text(LIST_CONFIGS_PROMPT)
    console.print("  [green]●[/green] Created prompt templates")

    script_src = _get_script_source()
    if script_src:
        dest = p / "scripts" / "agentspec.sh"
        shutil.copy2(script_src, dest)
        dest.chmod(0o755)
        console.print("  [green]●[/green] Copied CLI script")

    generate_ide_config(p, selected_ide)
    console.print(f"  [green]●[/green] Configured for [bold]{selected_ide}[/bold] ({ide_label})")

    generate_vscode_config(p)
    console.print("  [green]●[/green] Added VS Code settings")

    console.print()

    next_steps = Table.grid(padding=(0, 1))
    next_steps.add_column()
    next_steps.add_row("[green]Project initialized successfully![/green]")
    next_steps.add_row("")
    next_steps.add_row("[dim]Next steps:[/dim]")
    next_steps.add_row(f"  cd {project_path}")
    next_steps.add_row("  agentspec new-agent     [dim]# Create your first agent[/dim]")
    next_steps.add_row("  agentspec new-skill     [dim]# Create your first skill[/dim]")
    next_steps.add_row("  agentspec list           [dim]# List all configs[/dim]")
    next_steps.add_row("  agentspec validate       [dim]# Validate configs[/dim]")
    next_steps.add_row("")
    next_steps.add_row("[dim]Or use your IDE's AI chat with the prompts in prompts/[/dim]")

    console.print(Panel(
        next_steps,
        title="[bold]Setup Complete[/bold]",
        border_style="green",
        padding=(1, 2),
    ))


@app.command("new-agent")
def new_agent(
    name: Optional[str] = typer.Option(None, "--name", help="Agent name (kebab-case)"),
    description: Optional[str] = typer.Option(None, "--description", help="Agent description"),
    project_dir: Optional[str] = typer.Option(None, "--project-dir", help="Project directory"),
    non_interactive: bool = typer.Option(False, "--non-interactive", help="Skip interactive prompts"),
):
    """Create a new agent configuration."""
    p = Path(project_dir) if project_dir else Path.cwd()

    if not non_interactive:
        console.print("[cyan]═══ Create New Agent ═══[/cyan]\n")
        if not name:
            name = typer.prompt("Agent name (kebab-case)")
        if not description:
            description = typer.prompt("Description")
        author = typer.prompt("Author", default="agentspec")
        tags_input = typer.prompt("Tags (comma-separated)", default="general")
        tags = [t.strip() for t in tags_input.split(",")]
    else:
        if not name or not description:
            console.print("[red]Error: --name and --description are required in non-interactive mode[/red]")
            raise typer.Exit(1)
        author = "agentspec"
        tags = ["general"]

    name = to_kebab_case(name)
    agent_dir = p / "agents" / name

    if agent_dir.exists() and not non_interactive:
        if not typer.confirm(f"Agent '{name}' already exists. Overwrite?", default=False):
            raise typer.Exit(0)

    agent_dir.mkdir(parents=True, exist_ok=True)

    tags_yaml = "\n".join(f"  - {t}" for t in tags)
    system_prompt = f"You are an AI assistant for {name}. {description}"

    agent_yaml = f"""\
name: {name}
description: {description}
version: 1.0.0
author: {author}
model_preferences:
  - gpt-4
  - claude-sonnet
  - gemini-pro
tags:
{tags_yaml}
system_prompt: |
  {system_prompt}

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
"""
    (agent_dir / "agent.yaml").write_text(agent_yaml)

    prompt_md = f"""\
# {name} Agent

{description}

## Instructions

Use this agent to {description}.

## Usage

Provide your input and the agent will generate the appropriate output based on its configuration.
"""
    (agent_dir / "prompt.md").write_text(prompt_md)

    console.print(f"[green]●[/green] Agent '{name}' created at: {agent_dir}")
    console.print("  Files created:")
    console.print(f"  - {agent_dir / 'agent.yaml'}")
    console.print(f"  - {agent_dir / 'prompt.md'}")

    if not non_interactive:
        console.print()
        console.print("[cyan]Tip:[/cyan] Use your IDE's AI chat with prompts/create-agent.md for a richer experience")


@app.command("new-skill")
def new_skill(
    name: Optional[str] = typer.Option(None, "--name", help="Skill name (kebab-case)"),
    description: Optional[str] = typer.Option(None, "--description", help="Skill description"),
    project_dir: Optional[str] = typer.Option(None, "--project-dir", help="Project directory"),
    non_interactive: bool = typer.Option(False, "--non-interactive", help="Skip interactive prompts"),
):
    """Create a new skill configuration."""
    p = Path(project_dir) if project_dir else Path.cwd()

    if not non_interactive:
        console.print("[cyan]═══ Create New Skill ═══[/cyan]\n")
        if not name:
            name = typer.prompt("Skill name (kebab-case)")
        if not description:
            description = typer.prompt("Description")
        author = typer.prompt("Author", default="agentspec")
        tags_input = typer.prompt("Tags (comma-separated)", default="general")
        tags = [t.strip() for t in tags_input.split(",")]
    else:
        if not name or not description:
            console.print("[red]Error: --name and --description are required in non-interactive mode[/red]")
            raise typer.Exit(1)
        author = "agentspec"
        tags = ["general"]

    name = to_kebab_case(name)
    skill_dir = p / "skills" / name

    if skill_dir.exists() and not non_interactive:
        if not typer.confirm(f"Skill '{name}' already exists. Overwrite?", default=False):
            raise typer.Exit(0)

    skill_dir.mkdir(parents=True, exist_ok=True)

    tags_yaml = "\n".join(f"  - {t}" for t in tags)
    system_prompt = f"You are a skill assistant for {name}. {description}"

    skill_yaml = f"""\
name: {name}
description: {description}
version: 1.0.0
author: {author}
tags:
{tags_yaml}
system_prompt: |
  {system_prompt}

inputs:
  - name: user_input
    description: Primary input from the user
    required: true

outputs:
  - name: result
    description: Generated output
    format: markdown

steps:
  - name: analyze
    description: Analyze the input requirements
  - name: generate
    description: Generate the output
  - name: review
    description: Review and refine the output
"""
    (skill_dir / "skill.yaml").write_text(skill_yaml)

    prompt_md = f"""\
# {name} Skill

{description}

## Instructions

Use this skill to {description}.

## Steps

1. **Analyze** - Analyze the input requirements
2. **Generate** - Generate the output
3. **Review** - Review and refine the output
"""
    (skill_dir / "prompt.md").write_text(prompt_md)

    console.print(f"[green]●[/green] Skill '{name}' created at: {skill_dir}")
    console.print("  Files created:")
    console.print(f"  - {skill_dir / 'skill.yaml'}")
    console.print(f"  - {skill_dir / 'prompt.md'}")


@app.command("list")
def list_configs(
    project_dir: Optional[str] = typer.Option(None, "--project-dir", help="Project directory"),
):
    """List all agents and skills."""
    p = Path(project_dir) if project_dir else Path.cwd()

    agents_dir = p / "agents"
    skills_dir = p / "skills"

    console.print("[bold cyan]Agents:[/bold cyan]")
    if agents_dir.exists():
        agents = sorted([d for d in agents_dir.iterdir() if d.is_dir()])
        if agents:
            for agent in agents:
                yaml_f = agent / "agent.yaml"
                if yaml_f.exists():
                    try:
                        data = yaml.safe_load(yaml_f.read_text())
                        n = data.get("name", agent.name)
                        desc = data.get("description", "")
                        ver = data.get("version", "")
                        console.print(f"  [green]●[/green] {n} [dim](v{ver})[/dim] - {desc}")
                    except Exception:
                        console.print(f"  [yellow]●[/yellow] {agent.name} [dim](invalid yaml)[/dim]")
                else:
                    console.print(f"  [yellow]●[/yellow] {agent.name} [dim](no agent.yaml)[/dim]")
        else:
            console.print("  [dim]No agents found[/dim]")
    else:
        console.print("  [dim]No agents/ directory[/dim]")

    console.print()
    console.print("[bold cyan]Skills:[/bold cyan]")
    if skills_dir.exists():
        skills = sorted([d for d in skills_dir.iterdir() if d.is_dir()])
        if skills:
            for skill in skills:
                yaml_f = skill / "skill.yaml"
                if yaml_f.exists():
                    try:
                        data = yaml.safe_load(yaml_f.read_text())
                        n = data.get("name", skill.name)
                        desc = data.get("description", "")
                        ver = data.get("version", "")
                        console.print(f"  [green]●[/green] {n} [dim](v{ver})[/dim] - {desc}")
                    except Exception:
                        console.print(f"  [yellow]●[/yellow] {skill.name} [dim](invalid yaml)[/dim]")
                else:
                    console.print(f"  [yellow]●[/yellow] {skill.name} [dim](no skill.yaml)[/dim]")
        else:
            console.print("  [dim]No skills found[/dim]")
    else:
        console.print("  [dim]No skills/ directory[/dim]")


@app.command("validate")
def validate(
    project_dir: Optional[str] = typer.Option(None, "--project-dir", help="Project directory"),
):
    """Validate all configurations."""
    p = Path(project_dir) if project_dir else Path.cwd()
    errors = 0
    checked = 0

    console.print("[bold cyan]Validating AgentSpec configurations...[/bold cyan]\n")

    agents_dir = p / "agents"
    if agents_dir.exists():
        for agent in sorted(agents_dir.iterdir()):
            if not agent.is_dir():
                continue
            yaml_f = agent / "agent.yaml"
            if not yaml_f.exists():
                console.print(f"  [red]✗[/red] {agent.name}: missing agent.yaml")
                errors += 1
                continue
            checked += 1
            try:
                data = yaml.safe_load(yaml_f.read_text())
                missing = [f for f in ["name", "description", "version"] if f not in data]
                if missing:
                    console.print(f"  [red]✗[/red] {agent.name}: missing fields: {', '.join(missing)}")
                    errors += 1
                else:
                    console.print(f"  [green]✓[/green] {agent.name}: valid")
            except Exception as e:
                console.print(f"  [red]✗[/red] {agent.name}: YAML parse error: {e}")
                errors += 1

    skills_dir = p / "skills"
    if skills_dir.exists():
        for skill in sorted(skills_dir.iterdir()):
            if not skill.is_dir():
                continue
            yaml_f = skill / "skill.yaml"
            if not yaml_f.exists():
                console.print(f"  [red]✗[/red] {skill.name}: missing skill.yaml")
                errors += 1
                continue
            checked += 1
            try:
                data = yaml.safe_load(yaml_f.read_text())
                missing = [f for f in ["name", "description", "version"] if f not in data]
                if missing:
                    console.print(f"  [red]✗[/red] {skill.name}: missing fields: {', '.join(missing)}")
                    errors += 1
                else:
                    console.print(f"  [green]✓[/green] {skill.name}: valid")
            except Exception as e:
                console.print(f"  [red]✗[/red] {skill.name}: YAML parse error: {e}")
                errors += 1

    console.print()
    if errors > 0:
        console.print(f"[red]Validation failed: {errors} error(s) in {checked} configs[/red]")
        raise typer.Exit(1)
    else:
        console.print(f"[green]All {checked} configurations are valid[/green]")
