# Permission Rules Configuration

## Overview

Permission rules have been added to the GUI framework workflow templates to control file access during OpenCode runs.

## Rules Applied

- **DENY**: `*.j**ml` - Blocks editing of files matching this pattern (e.g., `*.jaml`, `*.jxml`, etc.)
- **ALLOW**: `**` - Allows editing of all other files

## Configuration Location

The permission rules are configured in `opencode.json` via the workflow templates:

- `workflows/opencodev3-fixed.txt` - Added to the "Configure GUI MCP server" step
- `workflows/opencode-auto-run-v2.txt` - Added as a new "Configure permissions" step

## Why TXT Files Instead of YML

The `.txt` files in `workflows/` are the source templates for GitHub Actions workflows. Edit these files instead of the `.yml` files in `.github/workflows/` to ensure changes persist across workflow regenerations.

## opencode.json Permission Format

```json
{
  "permission": {
    "edit": {
      "*.j**ml": "deny",
      "**": "allow"
    }
  }
}
```

Rules are evaluated by pattern match, with the **last matching rule winning**. The catch-all `**` allow rule is placed after the specific deny rule.

## GUI Framework Components

The GUI controller provides:
- Virtual X11 display (Xvfb) via `display.py`
- Mouse/keyboard control via `input.py` (xdotool)
- Screenshot capture via `screenshot.py` (mss)
- Main orchestrator in `app.py`
- MCP server in `mcp_server.py`

## Workflow Execution

When `enable_gui` is set to `true` in the workflow:
1. Xvfb virtual display starts on `:99`
2. GUI dependencies install (xdotool, scrot, Python libraries)
3. MCP server configures in `opencode.json`
4. Permission rules apply to all file operations
