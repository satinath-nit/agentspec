# AgentSpec Rules for Cursor

You are working in an AgentSpec project. This project manages AI agent configurations and skills.

## Key Conventions

- Agent configs are in `agents/{name}/agent.yaml` with accompanying `prompt.md`
- Skill configs are in `skills/{name}/skill.yaml` with accompanying `prompt.md`
- All names use kebab-case (lowercase with hyphens)
- YAML files must have: name, description, version fields
- Use the templates in `templates/` when creating new configs

## Available Commands

Use the prompt templates in `prompts/` directory with Cursor Chat:

- **Create Agent**: Open `prompts/create-agent.md` and follow the interactive flow
- **Create Skill**: Open `prompts/create-skill.md` and follow the interactive flow
- **List Configs**: Open `prompts/list-configs.md` to list all available configurations

Or use the CLI:

```bash
./scripts/agentspec.sh new-agent
./scripts/agentspec.sh new-skill
./scripts/agentspec.sh list
./scripts/agentspec.sh validate
```

## YAML Schema

### Agent (agents/{name}/agent.yaml)

Required fields: `name`, `description`, `version`
Optional fields: `author`, `model_preferences`, `tags`, `system_prompt`, `inputs`, `outputs`, `tools`

### Skill (skills/{name}/skill.yaml)

Required fields: `name`, `description`, `version`
Optional fields: `author`, `tags`, `system_prompt`, `inputs`, `outputs`, `steps`

## When Generating Code

- Always validate YAML after creation
- Ensure prompt.md files contain actionable, detailed instructions
- Follow the template structure in `templates/`
- Run `./scripts/agentspec.sh validate` after changes
