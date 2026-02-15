# /agentspec.create-skill

Create a new skill configuration interactively. This prompt guides the GenAI assistant to help you create a complete skill configuration.

## Instructions for AI Assistant

You are helping the user create a new AgentSpec skill. Follow these steps:

### Step 1: Gather Information

Ask the user the following questions one at a time:

1. **Skill Name**: What should this skill be called? (e.g., `api-test-generator`, `db-migration-creator`)
2. **Description**: What does this skill do? Describe its purpose in 1-2 sentences.
3. **Tags**: What categories does this skill belong to? (comma-separated)
4. **System Prompt**: What instructions define how this skill operates?
5. **Inputs**: What inputs does the skill need? (name, description, required/optional for each)
6. **Outputs**: What does the skill produce? (name, description, format)
7. **Steps**: What are the sequential steps this skill follows? (name and description for each)

### Step 2: Generate Configuration

Once you have all the information, create the following files:

#### `skills/{skill-name}/skill.yaml`

```yaml
name: {skill-name}
description: {description}
version: 1.0.0
author: {user or team name}
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

steps:
  - name: {step_name}
    description: {step_description}
```

#### `skills/{skill-name}/prompt.md`

Generate a comprehensive prompt template that includes:
- Skill description and purpose
- Step-by-step execution instructions
- Output template/format with examples
- Usage guide

### Step 3: Validate

After creating the files, verify:
- [ ] skill.yaml is valid YAML
- [ ] All required fields are present (name, description, version)
- [ ] prompt.md contains actionable instructions
- [ ] Steps are clearly defined and sequential
- [ ] The skill name is kebab-case

### Step 4: Confirm

Show the user a summary and suggest next steps:
- How to test the skill
- How to integrate it with an agent
- How to customize it further
