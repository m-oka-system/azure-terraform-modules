---
allowed-tools: Bash(gh:*), Bash(git:*)
description: Generate PR description and automatically create pull request on GitHub
---

## Context

- Current git status: !`git status`
- Changes in this PR: !`git diff main...HEAD`
- Commits in this PR: !`git log --oneline main..HEAD`
- PR template: @.github/pull_request_template.md

## Options

| Option | Action |
|--------|--------|
| (none) | Create PR |
| `-p` | Push branch, then create PR |
| `-u` | Update existing PR description |
| `-r` | Create PR, then run automatic review (requires pr-review-toolkit plugin) |

Options can be combined: `/pr -p -r` pushes and creates a PR with automatic review.

## Workflow

### Common Steps (all options)

1. Generate PR description following the template format in Japanese
2. Include a Mermaid diagram visualizing the changes
3. After PR creation/update, open the PR in browser: `gh pr view --web`

### Option-Specific Steps

| Option | Command |
|--------|---------|
| (none) | `gh pr create` |
| `-p` | `git push -u origin <branch>` then `gh pr create` |
| `-u` | `gh pr edit --body <description>` |
| `-r` | `gh pr create` (exit code 0), then execute `/pr-review-toolkit:review-pr` |

## Requirements

### PR Description

- Follow template structure exactly
- Write all content in Japanese
- Include specific implementation details and testing steps
- Be comprehensive but concise

### Mermaid Diagram

Include a diagram showing relevant aspects:
- Architecture or data flow changes
- Component relationships
- Process flows affected

Guidelines:
- Use appropriate diagram types (flowchart, sequence, class, etc.)
- Show before/after states when applicable
- Highlight new or modified components
- **No colors or styling**: Avoid `style`, `classDef`, `fill`, `stroke`, or color directives

## Error Handling

- If `gh pr create` fails, abort the workflow and report the error
- For `-r` option: If PR creation succeeds but `/pr-review-toolkit:review-pr` is unavailable, warn the user but consider PR creation successful
- For `-r` option: If review execution fails, report the error but preserve the created PR

**Generate the PR description and execute the appropriate command based on the option.**
