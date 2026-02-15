import os
import shutil
import tempfile
from pathlib import Path
from unittest.mock import patch

import pytest
from typer.testing import CliRunner


@pytest.fixture
def runner():
    return CliRunner()


@pytest.fixture
def tmp_project(tmp_path):
    return tmp_path / "test-project"


@pytest.fixture
def project_root():
    return Path(__file__).parent.parent


class TestBanner:
    def test_banner_constant_exists(self):
        from agentspec_cli.banner import BANNER
        assert len(BANNER) > 100

    def test_tagline_constant_exists(self):
        from agentspec_cli.banner import TAGLINE
        assert "AgentSpec" in TAGLINE

    def test_show_banner_runs(self, capsys):
        from agentspec_cli.banner import show_banner
        show_banner()


class TestIDEConfig:
    def test_agent_config_has_all_ides(self):
        from agentspec_cli.ide import AGENT_CONFIG
        expected = [
            "copilot", "claude", "gemini", "cursor-agent", "qwen",
            "opencode", "codex", "windsurf", "kilocode", "auggie",
            "codebuddy", "qoder", "roo", "q", "amp", "shai", "bob", "devin",
        ]
        for ide in expected:
            assert ide in AGENT_CONFIG, f"Missing IDE: {ide}"

    def test_agent_config_has_name(self):
        from agentspec_cli.ide import AGENT_CONFIG
        for key, config in AGENT_CONFIG.items():
            assert "name" in config, f"IDE {key} missing 'name'"

    def test_get_ide_label(self):
        from agentspec_cli.ide import get_ide_label
        assert get_ide_label("copilot") == "GitHub Copilot"
        assert get_ide_label("claude") == "Claude Code"
        assert get_ide_label("unknown") == "unknown"

    def test_generate_copilot_config(self, tmp_path):
        from agentspec_cli.ide import generate_ide_config
        generate_ide_config(tmp_path, "copilot")
        assert (tmp_path / ".github" / "copilot-instructions.md").exists()

    def test_generate_claude_config(self, tmp_path):
        from agentspec_cli.ide import generate_ide_config
        generate_ide_config(tmp_path, "claude")
        assert (tmp_path / "CLAUDE.md").exists()

    def test_generate_gemini_config(self, tmp_path):
        from agentspec_cli.ide import generate_ide_config
        generate_ide_config(tmp_path, "gemini")
        f = tmp_path / ".gemini" / "settings.json"
        assert f.exists()
        import json
        data = json.loads(f.read_text())
        assert "projectContext" in data

    def test_generate_cursor_config(self, tmp_path):
        from agentspec_cli.ide import generate_ide_config
        generate_ide_config(tmp_path, "cursor-agent")
        assert (tmp_path / ".cursor" / "rules" / "agentspec.md").exists()

    def test_generate_windsurf_config(self, tmp_path):
        from agentspec_cli.ide import generate_ide_config
        generate_ide_config(tmp_path, "windsurf")
        assert (tmp_path / ".windsurf" / "rules" / "agentspec.md").exists()

    def test_generate_codex_config(self, tmp_path):
        from agentspec_cli.ide import generate_ide_config
        generate_ide_config(tmp_path, "codex")
        assert (tmp_path / ".codex" / "instructions.md").exists()

    def test_generate_devin_config(self, tmp_path):
        from agentspec_cli.ide import generate_ide_config
        generate_ide_config(tmp_path, "devin")
        assert (tmp_path / ".devin" / "instructions.md").exists()

    def test_generate_roo_config(self, tmp_path):
        from agentspec_cli.ide import generate_ide_config
        generate_ide_config(tmp_path, "roo")
        assert (tmp_path / ".roo").exists()

    def test_generate_q_config(self, tmp_path):
        from agentspec_cli.ide import generate_ide_config
        generate_ide_config(tmp_path, "q")
        assert (tmp_path / ".q").exists()

    def test_generate_all_ide_configs(self, tmp_path):
        from agentspec_cli.ide import AGENT_CONFIG, generate_ide_config
        for ide_key in AGENT_CONFIG:
            d = tmp_path / ide_key
            d.mkdir()
            generate_ide_config(d, ide_key)
            assert any(d.rglob("*")), f"IDE {ide_key} generated no files"

    def test_generate_vscode_config(self, tmp_path):
        from agentspec_cli.ide import generate_vscode_config
        generate_vscode_config(tmp_path)
        assert (tmp_path / ".vscode" / "settings.json").exists()
        assert (tmp_path / ".vscode" / "tasks.json").exists()
        assert (tmp_path / ".vscode" / "extensions.json").exists()


class TestInitCommand:
    def test_init_creates_project_directory(self, runner, tmp_project):
        from agentspec_cli.commands import app
        result = runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        assert tmp_project.exists()

    def test_init_creates_agents_dir(self, runner, tmp_project):
        from agentspec_cli.commands import app
        runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        assert (tmp_project / "agents").is_dir()

    def test_init_creates_skills_dir(self, runner, tmp_project):
        from agentspec_cli.commands import app
        runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        assert (tmp_project / "skills").is_dir()

    def test_init_creates_templates(self, runner, tmp_project):
        from agentspec_cli.commands import app
        runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        assert (tmp_project / "templates" / "agent").is_dir()
        assert (tmp_project / "templates" / "skill").is_dir()

    def test_init_creates_agents_md(self, runner, tmp_project):
        from agentspec_cli.commands import app
        runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        f = tmp_project / "AGENTS.md"
        assert f.exists()
        assert "AgentSpec" in f.read_text()

    def test_init_creates_gitignore(self, runner, tmp_project):
        from agentspec_cli.commands import app
        runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        assert (tmp_project / ".gitignore").exists()

    def test_init_creates_env_example(self, runner, tmp_project):
        from agentspec_cli.commands import app
        runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        assert (tmp_project / ".env.example").exists()

    def test_init_creates_copilot_config(self, runner, tmp_project):
        from agentspec_cli.commands import app
        runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        assert (tmp_project / ".github" / "copilot-instructions.md").exists()

    def test_init_creates_vscode_config(self, runner, tmp_project):
        from agentspec_cli.commands import app
        runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        assert (tmp_project / ".vscode" / "settings.json").exists()

    def test_init_creates_claude_config(self, runner, tmp_project):
        from agentspec_cli.commands import app
        runner.invoke(app, ["init", str(tmp_project), "--ide", "claude", "--non-interactive"])
        assert (tmp_project / "CLAUDE.md").exists()

    def test_init_creates_cursor_config(self, runner, tmp_project):
        from agentspec_cli.commands import app
        runner.invoke(app, ["init", str(tmp_project), "--ide", "cursor-agent", "--non-interactive"])
        assert (tmp_project / ".cursor" / "rules" / "agentspec.md").exists()

    def test_init_creates_prompts(self, runner, tmp_project):
        from agentspec_cli.commands import app
        runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        assert (tmp_project / "prompts").is_dir()

    def test_init_shows_banner(self, runner, tmp_project):
        from agentspec_cli.commands import app
        result = runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        assert "AGENTSPEC" in result.output or "AgentSpec" in result.output

    def test_init_shows_project_setup(self, runner, tmp_project):
        from agentspec_cli.commands import app
        result = runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        assert "Project" in result.output

    def test_init_shows_completion(self, runner, tmp_project):
        from agentspec_cli.commands import app
        result = runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        output_lower = result.output.lower()
        assert "complete" in output_lower or "initialized" in output_lower or "success" in output_lower

    def test_init_default_ide_copilot(self, runner, tmp_project):
        from agentspec_cli.commands import app
        result = runner.invoke(app, ["init", str(tmp_project), "--non-interactive"])
        assert (tmp_project / ".github" / "copilot-instructions.md").exists()

    def test_init_copies_script(self, runner, tmp_project):
        from agentspec_cli.commands import app
        runner.invoke(app, ["init", str(tmp_project), "--ide", "copilot", "--non-interactive"])
        assert (tmp_project / "scripts").is_dir()


class TestNewAgentCommand:
    def test_new_agent_creates_yaml(self, runner, project_root):
        from agentspec_cli.commands import app
        result = runner.invoke(app, [
            "new-agent",
            "--name", "test-agent-py",
            "--description", "A pytest test agent",
            "--project-dir", str(project_root),
            "--non-interactive",
        ])
        agent_dir = project_root / "agents" / "test-agent-py"
        try:
            assert agent_dir.exists()
            yaml_f = agent_dir / "agent.yaml"
            assert yaml_f.exists()
            content = yaml_f.read_text()
            assert "name: test-agent-py" in content
            assert "description:" in content
            assert "version:" in content
        finally:
            if agent_dir.exists():
                shutil.rmtree(agent_dir)

    def test_new_agent_creates_prompt_md(self, runner, project_root):
        from agentspec_cli.commands import app
        runner.invoke(app, [
            "new-agent",
            "--name", "test-agent-md",
            "--description", "A test agent for prompt",
            "--project-dir", str(project_root),
            "--non-interactive",
        ])
        agent_dir = project_root / "agents" / "test-agent-md"
        try:
            assert (agent_dir / "prompt.md").exists()
        finally:
            if agent_dir.exists():
                shutil.rmtree(agent_dir)

    def test_new_agent_kebab_case(self, runner, project_root):
        from agentspec_cli.commands import app
        runner.invoke(app, [
            "new-agent",
            "--name", "My Test Agent",
            "--description", "Test",
            "--project-dir", str(project_root),
            "--non-interactive",
        ])
        agent_dir = project_root / "agents" / "my-test-agent"
        try:
            assert agent_dir.exists()
        finally:
            if agent_dir.exists():
                shutil.rmtree(agent_dir)

    def test_new_agent_requires_name(self, runner, project_root):
        from agentspec_cli.commands import app
        result = runner.invoke(app, [
            "new-agent",
            "--description", "No name",
            "--project-dir", str(project_root),
            "--non-interactive",
        ])
        assert result.exit_code != 0 or "required" in result.output.lower() or "error" in result.output.lower()


class TestNewSkillCommand:
    def test_new_skill_creates_yaml(self, runner, project_root):
        from agentspec_cli.commands import app
        result = runner.invoke(app, [
            "new-skill",
            "--name", "test-skill-py",
            "--description", "A pytest test skill",
            "--project-dir", str(project_root),
            "--non-interactive",
        ])
        skill_dir = project_root / "skills" / "test-skill-py"
        try:
            assert skill_dir.exists()
            yaml_f = skill_dir / "skill.yaml"
            assert yaml_f.exists()
            content = yaml_f.read_text()
            assert "name: test-skill-py" in content
            assert "steps:" in content
        finally:
            if skill_dir.exists():
                shutil.rmtree(skill_dir)

    def test_new_skill_creates_prompt_md(self, runner, project_root):
        from agentspec_cli.commands import app
        runner.invoke(app, [
            "new-skill",
            "--name", "test-skill-md",
            "--description", "A test skill for prompt",
            "--project-dir", str(project_root),
            "--non-interactive",
        ])
        skill_dir = project_root / "skills" / "test-skill-md"
        try:
            assert (skill_dir / "prompt.md").exists()
        finally:
            if skill_dir.exists():
                shutil.rmtree(skill_dir)


class TestListCommand:
    def test_list_shows_agents(self, runner, project_root):
        from agentspec_cli.commands import app
        result = runner.invoke(app, ["list", "--project-dir", str(project_root)])
        output_lower = result.output.lower()
        assert "agent" in output_lower

    def test_list_shows_skills(self, runner, project_root):
        from agentspec_cli.commands import app
        result = runner.invoke(app, ["list", "--project-dir", str(project_root)])
        output_lower = result.output.lower()
        assert "skill" in output_lower


class TestValidateCommand:
    def test_validate_passes_on_valid_project(self, runner, project_root):
        from agentspec_cli.commands import app
        result = runner.invoke(app, ["validate", "--project-dir", str(project_root)])
        output_lower = result.output.lower()
        assert "valid" in output_lower or "pass" in output_lower

    def test_validate_checks_yaml(self, runner, project_root):
        from agentspec_cli.commands import app
        result = runner.invoke(app, ["validate", "--project-dir", str(project_root)])
        assert result.exit_code == 0


class TestHelpCommand:
    def test_help_shows_info(self, runner):
        from agentspec_cli.commands import app
        result = runner.invoke(app, ["--help"])
        assert "agentspec" in result.output.lower() or "agent" in result.output.lower()

    def test_help_lists_commands(self, runner):
        from agentspec_cli.commands import app
        result = runner.invoke(app, ["--help"])
        assert "init" in result.output
        assert "new-agent" in result.output or "new_agent" in result.output
