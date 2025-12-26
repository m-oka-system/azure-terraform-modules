---
allowed-tools: Bash(gh:*), Bash(git:*)
description: Create PR and automatically run review using pr-review-toolkit
---

## Context

- Current git status: !`git status`
- Changes in this PR: !`git diff main...HEAD`
- Commits in this PR: !`git log --oneline main..HEAD`
- PR template: @.github/pull_request_template.md
- PR creation workflow: See @.claude/commands/pr.md for detailed PR creation steps

## Your task

This command extends `/pr` command by adding an automated review step. It performs a two-step workflow:

1. **Create PR**: Execute the PR creation workflow (same as `/pr` command)
2. **Run Review**: After PR creation, automatically execute `/pr-review-toolkit:review-pr` to perform code review

### Options:

- **No option or default**: Create PR and run review
- **-p**: Push current branch, create PR, and run review
- **-u**: Update existing PR description and run review

### Workflow Steps

#### Step 1: Create Pull Request (delegates to `/pr`)

- Common: Run the `/pr` command as-is (see @.claude/commands/pr.md)
- default: `gh pr create --draft` (capture PR number)
- -p: `git push -u origin <current-branch>` → `gh pr create --draft` (capture PR number)
- -u: `gh pr edit --body <description>` (`gh pr view --json number -q .number` to capture PR number)

#### Step 2: Run Code Review

After the PR is created or updated:

1. **Verify PR**: Ensure the PR number is available
2. **Run review**: Execute `/pr-review-toolkit:review-pr`
3. **Show results**: Present the review output

### Requirements

**PR Creation** (same as `/pr`, see @.claude/commands/pr.md):

- Content must be in Japanese
- Follow the PR template structure exactly
- Include a Mermaid diagram (no colors/styling)
- Include implementation details and test steps

**Review Execution**:

- Only run review after PR creation/update succeeds
- If PR creation fails, stop and report the error
- Provide clear status for each step
- Show review results in a readable format

### Error Handling

- **PR creation fails**: Stop workflow and surface the error
- **PR number unavailable**: Try `gh pr list --head <current-branch> --json number -q '.[0].number'`
- **Review command fails**: Report the error but keep the workflow (PR was created)

**Execute the complete workflow: create PR and run review automatically.**
