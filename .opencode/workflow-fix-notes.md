# Workflow Fix Notes

## Issue: Python IndentationError in GUI MCP server configuration (2026-05-20)

### Problem
In `workflows/opencodev3-fixed.txt`, the `Configure GUI MCP server` step used `python3 -c "..."` with multi-line Python code. The YAML `run: |` block preserved leading whitespace, causing Python to receive indented code at module level:
```
File "<string>", line 2
    import json
IndentationError: unexpected indent
```

### Fix
Flattened the multi-line Python code into a single-line `python3 -c` command to eliminate indentation issues. The single-line approach avoids YAML/shell/Python indentation conflicts entirely.

### Files Modified
- `workflows/opencodev3-fixed.txt`

### Lesson
When embedding Python code in GitHub Actions `run: |` blocks:
1. Single-line `python3 -c "..."` is safest - no indentation conflicts
2. If multi-line is needed, write to a temp file first, then `sed` to strip leading whitespace before executing
3. Never rely on `python3 -c` with multi-line code inside YAML block scalars - the indentation will be preserved and cause errors
4. Alternative: use `python3 << 'EOF'` but ensure heredoc content has no leading whitespace (difficult in YAML)

---

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
