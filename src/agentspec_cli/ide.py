import os
from pathlib import Path
from typing import Optional

import readchar
from rich.console import Console
from rich.live import Live
from rich.panel import Panel
from rich.table import Table

console = Console()

AGENT_CONFIG = {
    "copilot": {"name": "GitHub Copilot", "folder": ".github/", "requires_cli": False},
    "claude": {"name": "Claude Code", "folder": ".claude/", "requires_cli": True},
    "gemini": {"name": "Gemini CLI", "folder": ".gemini/", "requires_cli": True},
    "cursor-agent": {"name": "Cursor", "folder": ".cursor/", "requires_cli": False},
    "qwen": {"name": "Qwen Code", "folder": ".qwen/", "requires_cli": True},
    "opencode": {"name": "opencode", "folder": ".opencode/", "requires_cli": True},
    "codex": {"name": "Codex CLI", "folder": ".codex/", "requires_cli": True},
    "windsurf": {"name": "Windsurf", "folder": ".windsurf/", "requires_cli": False},
    "kilocode": {"name": "Kilo Code", "folder": ".kilocode/", "requires_cli": False},
    "auggie": {"name": "Auggie CLI", "folder": ".augment/", "requires_cli": True},
    "codebuddy": {"name": "CodeBuddy", "folder": ".codebuddy/", "requires_cli": True},
    "qoder": {"name": "Qoder CLI", "folder": ".qoder/", "requires_cli": True},
    "roo": {"name": "Roo Code", "folder": ".roo/", "requires_cli": False},
    "q": {"name": "Amazon Q Developer CLI", "folder": ".amazonq/", "requires_cli": True},
    "amp": {"name": "Amp", "folder": ".agents/", "requires_cli": True},
    "shai": {"name": "SHAI", "folder": ".shai/", "requires_cli": True},
    "bob": {"name": "IBM Bob", "folder": ".bob/", "requires_cli": False},
    "devin": {"name": "Devin", "folder": ".devin/", "requires_cli": False},
}


def get_key() -> str:
    key = readchar.readkey()
    if key in (readchar.key.UP, readchar.key.CTRL_P):
        return "up"
    if key in (readchar.key.DOWN, readchar.key.CTRL_N):
        return "down"
    if key == readchar.key.ENTER:
        return "enter"
    if key == readchar.key.ESC:
        return "escape"
    if key == readchar.key.CTRL_C:
        raise KeyboardInterrupt
    return key


def select_ide(default_key: Optional[str] = None) -> str:
    option_keys = list(AGENT_CONFIG.keys())
    selected_index = 0
    if default_key and default_key in option_keys:
        selected_index = option_keys.index(default_key)

    selected_key = None

    def create_panel():
        table = Table.grid(padding=(0, 2))
        table.add_column(style="cyan", justify="left", width=3)
        table.add_column(style="white", justify="left")

        for i, key in enumerate(option_keys):
            label = AGENT_CONFIG[key]["name"]
            if i == selected_index:
                table.add_row("▶", f"[bold cyan]{key}[/bold cyan] [dim]({label})[/dim]")
            else:
                table.add_row(" ", f"[cyan]{key}[/cyan] [dim]({label})[/dim]")

        table.add_row("", "")
        table.add_row("", "[dim]Use ↑/↓ to navigate, Enter to select, Esc to cancel[/dim]")

        return Panel(
            table,
            title="[bold]Choose your AI assistant:[/bold]",
            border_style="cyan",
            padding=(1, 2),
        )

    console.print()

    with Live(create_panel(), console=console, transient=True, auto_refresh=False) as live:
        while True:
            try:
                key = get_key()
                if key == "up":
                    selected_index = (selected_index - 1) % len(option_keys)
                elif key == "down":
                    selected_index = (selected_index + 1) % len(option_keys)
                elif key == "enter":
                    selected_key = option_keys[selected_index]
                    break
                elif key == "escape":
                    console.print("\n[yellow]Selection cancelled[/yellow]")
                    return ""
                live.update(create_panel(), refresh=True)
            except KeyboardInterrupt:
                console.print("\n[yellow]Selection cancelled[/yellow]")
                return ""

    return selected_key or ""


def get_ide_label(ide_key: str) -> str:
    config = AGENT_CONFIG.get(ide_key)
    if config:
        return config["name"]
    return ide_key


def generate_ide_config(project_path: Path, ide_key: str) -> None:
    p = project_path
    configs = {
        "copilot": _gen_copilot,
        "claude": _gen_claude,
        "gemini": _gen_gemini,
        "cursor-agent": _gen_cursor,
        "qwen": _gen_qwen,
        "opencode": _gen_opencode,
        "codex": _gen_codex,
        "windsurf": _gen_windsurf,
        "kilocode": _gen_kilocode,
        "auggie": _gen_auggie,
        "codebuddy": _gen_codebuddy,
        "qoder": _gen_qoder,
        "roo": _gen_roo,
        "q": _gen_q,
        "amp": _gen_amp,
        "shai": _gen_shai,
        "bob": _gen_bob,
        "devin": _gen_devin,
    }
    gen_fn = configs.get(ide_key)
    if gen_fn:
        gen_fn(p)


AGENTSPEC_CONTEXT = """\
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
- `agentspec new-agent` - Create new agent interactively
- `agentspec new-skill` - Create new skill interactively
- `agentspec list` - List all configs
- `agentspec validate` - Validate all configs
"""


def _write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def _gen_copilot(p: Path) -> None:
    _write(
        p / ".github" / "copilot-instructions.md",
        f"# GitHub Copilot Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}",
    )


def _gen_claude(p: Path) -> None:
    _write(p / "CLAUDE.md", f"# Claude Code Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}")


def _gen_gemini(p: Path) -> None:
    import json

    settings = {
        "projectContext": (
            "AgentSpec - AI Agent Configuration Toolkit. "
            "Manages agent configs in agents/{name}/agent.yaml "
            "and skills in skills/{name}/skill.yaml. "
            "All names kebab-case. YAML requires name, description, version fields."
        ),
        "codeStyle": {"yamlIndent": 2, "namingConvention": "kebab-case"},
    }
    _write(p / ".gemini" / "settings.json", json.dumps(settings, indent=2) + "\n")


def _gen_cursor(p: Path) -> None:
    _write(
        p / ".cursor" / "rules" / "agentspec.md",
        f"# AgentSpec Rules for Cursor\n\nYou are working in an AgentSpec project.\n\n{AGENTSPEC_CONTEXT}",
    )


def _gen_qwen(p: Path) -> None:
    _write(p / ".qwen", f"# Qwen Code Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}")


def _gen_opencode(p: Path) -> None:
    _write(p / ".opencode", f"# opencode Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}")


def _gen_codex(p: Path) -> None:
    _write(
        p / ".codex" / "instructions.md",
        f"# Codex CLI Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}",
    )


def _gen_windsurf(p: Path) -> None:
    _write(
        p / ".windsurf" / "rules" / "agentspec.md",
        f"# AgentSpec Rules for Windsurf\n\n{AGENTSPEC_CONTEXT}",
    )


def _gen_kilocode(p: Path) -> None:
    _write(p / ".kilocode", f"# Kilo Code Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}")


def _gen_auggie(p: Path) -> None:
    _write(p / ".auggie", f"# Auggie CLI Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}")


def _gen_codebuddy(p: Path) -> None:
    _write(p / ".codebuddy", f"# CodeBuddy Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}")


def _gen_qoder(p: Path) -> None:
    _write(p / ".qoder", f"# Qoder CLI Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}")


def _gen_roo(p: Path) -> None:
    _write(p / ".roo", f"# Roo Code Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}")


def _gen_q(p: Path) -> None:
    _write(p / ".q", f"# Amazon Q Developer CLI Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}")


def _gen_amp(p: Path) -> None:
    _write(p / ".amp", f"# Amp Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}")


def _gen_shai(p: Path) -> None:
    _write(p / ".shai", f"# SHAI Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}")


def _gen_bob(p: Path) -> None:
    _write(p / ".bob", f"# IBM Bob Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}")


def _gen_devin(p: Path) -> None:
    _write(
        p / ".devin" / "instructions.md",
        f"# Devin Instructions for AgentSpec\n\n{AGENTSPEC_CONTEXT}",
    )


def generate_vscode_config(project_path: Path) -> None:
    import json

    vscode = project_path / ".vscode"
    vscode.mkdir(parents=True, exist_ok=True)

    settings = {
        "yaml.schemas": {
            "./templates/agent/agent.yaml": "agents/*/agent.yaml",
            "./templates/skill/skill.yaml": "skills/*/skill.yaml",
        },
        "files.associations": {"*.yaml": "yaml", "*.yml": "yaml"},
        "editor.formatOnSave": True,
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "[yaml]": {"editor.defaultFormatter": "redhat.vscode-yaml"},
        "task.autoDetect": "on",
    }
    (vscode / "settings.json").write_text(json.dumps(settings, indent=2) + "\n")

    tasks = {
        "version": "2.0.0",
        "tasks": [
            {
                "label": "AgentSpec: Validate Configs",
                "type": "shell",
                "command": "agentspec validate",
                "group": "test",
            },
            {"label": "AgentSpec: List Configs", "type": "shell", "command": "agentspec list"},
            {"label": "AgentSpec: New Agent", "type": "shell", "command": "agentspec new-agent"},
            {"label": "AgentSpec: New Skill", "type": "shell", "command": "agentspec new-skill"},
        ],
    }
    (vscode / "tasks.json").write_text(json.dumps(tasks, indent=2) + "\n")

    extensions = {
        "recommendations": [
            "redhat.vscode-yaml",
            "esbenp.prettier-vscode",
            "davidanson.vscode-markdownlint",
        ]
    }
    (vscode / "extensions.json").write_text(json.dumps(extensions, indent=2) + "\n")
