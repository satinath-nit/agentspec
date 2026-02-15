# /agentspec.create-agent

Create a new agent configuration interactively. This prompt guides the GenAI assistant to help you create a complete agent configuration.

## Instructions for AI Assistant

You are helping the user create a new AgentSpec agent configuration. Follow these steps:

### Step 1: Gather Information

Ask the user the following questions one at a time:

1. **Agent Name**: What should this agent be called? (e.g., `code-reviewer`, `api-designer`)
2. **Description**: What does this agent do? Describe its purpose in 1-2 sentences.
3. **Tags**: What categories does this agent belong to? (comma-separated, e.g., `code, review, quality`)
4. **Model Preferences**: Which AI models work best for this agent? (default: gpt-4, claude-sonnet, gemini-pro)
5. **System Prompt**: What instructions should the agent follow? What is its persona and expertise?
6. **Inputs**: What inputs does the agent need from the user? (name and description for each)
7. **Outputs**: What does the agent produce? (name, description, format)
8. **Tools**: What tools/capabilities does the agent need? (e.g., file_write, web_search)

### Step 2: Generate Configuration

Once you have all the information, create the following files:

#### `agents/{agent-name}/agent.yaml`

```yaml
name: {agent-name}
description: {description}
version: 1.0.0
author: {user or team name}
model_preferences:
  - {model1}
  - {model2}
tags:
  - {tag1}
  - {tag2}

system_prompt: |
  {system prompt content}

inputs:
  - name: {input_name}
    description: {input_description}
    required: true

outputs:
  - name: {output_name}
    description: {output_description}
    format: markdown

tools:
  - name: {tool_name}
    description: {tool_description}
```

#### `agents/{agent-name}/prompt.md`

Generate a comprehensive prompt template that includes:
- Agent role description
- Step-by-step instructions
- Output template/format
- Usage guide with sample questions to ask users

### Step 3: Validate

After creating the files, verify:
- [ ] agent.yaml is valid YAML
- [ ] All required fields are present (name, description, version)
- [ ] prompt.md contains actionable instructions
- [ ] The agent name is kebab-case (lowercase with hyphens)

### Step 4: Confirm

Show the user a summary of what was created and suggest next steps:
- How to test the agent
- How to customize it further
- How to use it with their IDE
