# GitHub Copilot Instructions for AgentSpec

This is an AgentSpec project for managing AI agent configurations and skills.

## Project Structure

```
agentspec/
  agents/           # Agent configurations
    {name}/
      agent.yaml    # Agent config (name, description, version, system_prompt, inputs, outputs, tools)
      prompt.md     # Detailed prompt template
  skills/           # Skill configurations
    {name}/
      skill.yaml    # Skill config (name, description, version, system_prompt, inputs, outputs, steps)
      prompt.md     # Detailed prompt template
  templates/        # Templates for new agents/skills
  prompts/          # GenAI chat prompt templates
  scripts/          # CLI tools
  tests/            # Test suite
```

## Conventions

- All config names use **kebab-case** (lowercase with hyphens)
- YAML files require: `name`, `description`, `version`
- Each agent/skill has its own directory
- Prompt files use Markdown format

## Creating New Agents

1. Create directory: `agents/{agent-name}/`
2. Create `agent.yaml` with all required fields
3. Create `prompt.md` with detailed instructions, output templates, and usage guide
4. Validate: `./scripts/agentspec.sh validate`

## Creating New Skills

1. Create directory: `skills/{skill-name}/`
2. Create `skill.yaml` with required fields plus `steps` array
3. Create `prompt.md` with step-by-step instructions and examples
4. Validate: `./scripts/agentspec.sh validate`

## Chat Commands

Use these prompt templates in Copilot Chat for interactive creation:

- `/agentspec.create-agent` - Reference `prompts/create-agent.md`
- `/agentspec.create-skill` - Reference `prompts/create-skill.md`
- `/agentspec.list` - Reference `prompts/list-configs.md`

## Quality Guidelines

- System prompts should clearly define the agent/skill persona and expertise
- Inputs and outputs should be well-documented with descriptions
- Acceptance criteria and validation steps should be included in prompts
- Tags should categorize the config for discoverability
