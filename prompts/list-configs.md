# /agentspec.list

List all available agent configurations and skills in the current project.

## Instructions for AI Assistant

Scan the project directory and report on available configurations:

### Agents

Look in the `agents/` directory. For each subdirectory containing an `agent.yaml`:
1. Read the agent name and description
2. Show version and tags
3. Indicate if a prompt.md exists

### Skills

Look in the `skills/` directory. For each subdirectory containing a `skill.yaml`:
1. Read the skill name and description
2. Show version and tags
3. List the defined steps
4. Indicate if a prompt.md exists

### Output Format

```
=== AgentSpec Configurations ===

Agents:
  - prd-generator (v1.0.0) - Generates comprehensive PRDs
    Tags: product, requirements, documentation
  - adr-creator (v1.0.0) - Creates Architecture Decision Records
    Tags: architecture, documentation, decisions

Skills:
  - jira-story-creator (v1.0.0) - Creates JIRA user stories
    Tags: jira, agile, user-stories
    Steps: analyze_requirement -> create_stories -> estimate_points -> add_acceptance_criteria -> review_and_refine

Total: 2 agents, 1 skill
```
