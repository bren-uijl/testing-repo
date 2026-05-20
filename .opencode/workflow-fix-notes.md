# Workflow Fix Notes

## Issue: Shell interpreting Python code in workflow variables

### Problem
In `.github/workflows/opencodeV3.yml`, the `GUI_CAPABILITIES` variable contained a Python code example wrapped in markdown backtick fences (```python ... ```). When assigned inside a bash `run: |` block using double-quoted string assignment, the backticks were interpreted as command substitution, causing:
- `from: command not found`
- `syntax error near unexpected token '('`

### Fix
Escape the backticks in the markdown code fence: `\`\`\`python` and `\`\`\``

### Files Modified
- `.github/workflows/opencodeV3.yml`
- `workflows/opencodev3-fixed.txt`

### Lesson
When embedding markdown-formatted code examples inside shell variable assignments in GitHub Actions workflows, always escape backticks to prevent command substitution. Alternative approaches:
1. Escape backticks: `\`\`\``
2. Use heredoc with quoted delimiter: `cat << 'EOF'`
3. Store code examples in separate files and reference them
