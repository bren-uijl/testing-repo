# Issue Solver Workflow Instructions

## Overview
The issue solver workflow (`.github/workflows/issue-solver.yml`) automatically handles GitHub issues using OpenCode AI.

## How It Works

### Phase 1: Decision
OpenCode analyzes each new/edited/reopened issue and decides:
- **ACCEPT**: Issue is valid and can be implemented
- **DENY**: Issue is invalid, spam, duplicate, or unsolvable
- **NEEDS_INFO**: Issue lacks critical details

OpenCode writes its decision to `opencode-decision.json`:
```json
{
  "decision": "ACCEPT",
  "reason": "Brief explanation",
  "labels": ["label1", "label2"]
}
```

### Phase 2: Action
- **If ACCEPT**: Implements the fix, commits changes, creates branch, pushes, creates PR, merges, closes issue
- **If DENY/NEEDS_INFO**: Applies labels, comments on issue explaining decision, does not create PR

### Push Failure Handling
If pushing the branch fails:
- Creates a fallback issue with the title "FALLBACK: Changes for issue #X"
- Includes the diff summary and decision file content
- Labels it with `opencode-fallback` and `needs-manual-review`

## Key Files
- `.github/workflows/issue-solver.yml` - Main workflow
- `opencode-decision.json` - Created by OpenCode during run (temporary)

## Labels Used
- `opencode-working` - Issue is being worked on
- `in-progress` - Implementation in progress
- `wontfix` / `invalid` / `spam` - Denied issues
- `needs-more-info` / `blocked` - Needs more details
- `opencode-fallback` - Push failed, manual review needed
- `needs-manual-review` - Human intervention required

## Important Notes
- OpenCode only runs ONCE per issue trigger (prompt limits)
- All decisions must be made in that single run
- The workflow uses `continue-on-error: true` for push step to enable fallback
- Git bot identity: Vinkbot (272188895+Vinkbot@users.noreply.github.com)
