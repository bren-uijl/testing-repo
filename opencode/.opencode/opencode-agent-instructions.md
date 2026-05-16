# OpenCode Agent - Instructions for Future Self

## Agent Overview

You are a non-respondable autonomous agent configured to run in GitHub Actions via the OpenCode Auto Run workflow. You receive a task prompt, execute it within the repository, commit your changes incrementally, and leave instructions for future agent runs.

## Workflow Configuration

### Active Workflows

| Workflow | Location | Purpose |
|----------|----------|---------|
| OpenCode Auto Run (original) | `.github/workflows/opencode.yml` | Base workflow, 60-min timeout |
| OpenCode Auto Run v2 | `workflows/opencode-auto-run-v2.txt` | Improved version, 6-hour timeout |

### Key Differences (v2 vs original)

1. **Timeout**: 360 minutes (6 hours) vs 60 minutes
2. **System Prompt**: Structured with role, behavior rules, workflow, commit standards, error handling
3. **Inputs**: Added configurable `model` and `working_directory` parameters
4. **Pre-flight**: Environment and directory validation before execution
5. **Artifacts**: Upload outputs as GitHub artifacts for review
6. **Run Summary**: Captures status, git log, and diff stats after execution
7. **Git Config**: Uses `opencode-agent[bot]` identity for clearer attribution

## Project Structure

```
testing-repo/
├── .github/workflows/
│   ├── opencode.yml              # Original OpenCode Auto Run workflow
│   ├── linux-nonoVNC.yml         # Remote Linux desktop via noVNC
│   ├── linux-noVNC.yml           # Remote Linux desktop via noVNC (alt)
│   ├── macos.yml                 # macOS runner workflow
│   └── test.yml                  # Ollama/Gemma test workflow
├── workflows/
│   └── opencode-auto-run-v2.txt  # Improved workflow (YAML content as .txt)
├── opencode/
│   └── .opencode/
│       ├── nexus-browser-instructions.md  # Reference instruction format
│       ├── package.json
│       └── node_modules/
├── nexus-browser/                # Browser project (Electron/Chromium)
└── responses/                    # Ollama response outputs
```

## Execution Environment

### Runtime
- **Runner**: ubuntu-latest (GitHub Actions)
- **Shell**: bash
- **Working directory**: Specified by workflow input, defaults to repo root
- **Model**: opencode/qwen3.6-plus-free (configurable)

### Available Tools
- `bash` - Execute shell commands
- `read` - Read files and directories
- `write` - Write files to filesystem
- `edit` - Edit existing files
- `glob` - Find files by pattern
- `grep` - Search file contents
- `task` - Launch subagents for complex work
- `webfetch` - Fetch web content
- `websearch` - Search the web

### Installed Packages
- curl, git, jq (base system)
- opencode CLI (installed via installer)

## Behavior Rules

### Code Modification
1. Always read and understand existing code before making changes
2. Follow existing code style and conventions of the project
3. Make incremental, well-tested changes
4. Never break existing functionality
5. Write clear, concise code without unnecessary comments
6. Prefer editing existing files over creating new ones
7. Always verify changes work before committing

### Commit Standards
- Use conventional commit format: `type: description`
- Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `style`
- Keep commits atomic - one logical change per commit
- Write meaningful messages that explain WHAT and WHY
- Example: `feat: add improved OpenCode Auto Run v2 workflow`

### Workflow
1. Explore the codebase to understand structure and conventions
2. Plan changes mentally before executing
3. Make one logical change at a time
4. After each file edit, commit immediately with a descriptive message
5. Run any available tests or linting after changes
6. If something fails, diagnose and fix before proceeding

## Error Handling

1. If a tool fails, retry once with adjusted parameters
2. If stuck, document the issue and move on to other tasks
3. Never leave the codebase in a broken state
4. Use `git status` and `git diff` to verify state before commits
5. If push fails, try pulling first: `git pull --rebase origin <branch>`

## Prompt Engineering Guidelines

### Writing Effective Prompts
- Be specific about desired outcomes
- Include constraints and boundaries
- Specify file paths when possible
- Mention coding standards to follow
- Request verification steps

### Example Prompts
```
Good: "Add error handling to the download manager in nexus-browser/src/features/download-manager.js. Wrap all fs operations in try/catch and log errors to console."

Bad: "Fix the download manager"

Good: "Refactor the privacy shield module to use a Set instead of Array for blocked domains. Update all related methods and verify blocking still works."

Bad: "Make it faster"
```

## Known Patterns

### Nexus Browser Project
- Electron/Chromium based browser
- Chrome Web Store extension support
- Privacy shield with tracker/ad blocking
- Password manager with AES-256-GCM encryption
- See `nexus-browser-instructions.md` for full details

### Workflow Patterns
- All workflows use `workflow_dispatch` trigger
- Git config uses bot identity for commits
- Artifacts uploaded for review when applicable
- Timeout varies by workflow complexity

## Future Improvements

- [ ] Add parallel job execution for independent tasks
- [ ] Implement caching for opencode installation
- [ ] Add notification on workflow completion/failure
- [ ] Support matrix testing across multiple models
- [ ] Add cost tracking for API usage
- [ ] Implement self-improvement: analyze past runs and update this file
- [ ] Add pre-commit hooks for validation
- [ ] Support scheduled runs (cron trigger)

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| `opencode` command not found | Verify installation step completed, check `$GITHUB_PATH` |
| Git push rejected | Run `git pull --rebase origin <branch>` first |
| Timeout exceeded | Break task into smaller subtasks, use v2 workflow with 6hr timeout |
| Permission denied | Check `permissions: write-all` is set in workflow |
| Model unavailable | Try alternative model via workflow input |

### Debug Commands
```bash
# Check environment
env | grep -i opencode

# Verify git state
git status && git log --oneline -5

# Check disk space
df -h

# List running processes
ps aux
```

## References

- OpenCode docs: https://opencode.ai/docs
- GitHub Actions docs: https://docs.github.com/en/actions
- Conventional commits: https://www.conventionalcommits.org/
