# AgentSpec Rules for Windsurf

You are working in an AgentSpec project for managing AI agent configurations and skills.

## Key Conventions

- Agent configs: `agents/{name}/agent.yaml` + `prompt.md`
- Skill configs: `skills/{name}/skill.yaml` + `prompt.md`
- Names: kebab-case (lowercase with hyphens)
- Required YAML fields: name, description, version

## Available Workflows

### Create Agent

Use the interactive prompt from `prompts/create-agent.md` or CLI:

```bash
./scripts/agentspec.sh new-agent
```

### Create Skill

Use the interactive prompt from `prompts/create-skill.md` or CLI:

```bash
./scripts/agentspec.sh new-skill
```

### Validate

```bash
./scripts/agentspec.sh validate
```

## Templates

Use templates in `templates/` directory as starting points for new configurations.
