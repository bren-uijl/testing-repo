<h1 align="center">Testing Repo</h1>

<p align="center">
  An experimental repository for AI-driven development workflows and applications.
</p>

<p align="center">
  <a href="https://github.com/bren-uijl/testing-repo/actions/workflows/opencodev2.yml">
    <img src="https://github.com/bren-uijl/testing-repo/actions/workflows/opencodev2.yml/badge.svg" alt="OpenCode Auto Run v2">
  </a>
</p>

---

## Overview

This repository contains experimental projects and automation workflows powered by AI coding agents. It serves as a testing ground for autonomous development pipelines using OpenCode.

## Projects

### [Nexus Browser](opencode/browser/README.md)

A next-generation Chromium-based browser built on Electron with full Chrome Web Store extension support.

- Chrome Web Store extension support
- Built-in privacy shield (tracker & ad blocker)
- AES-256-GCM encrypted password manager
- Reading mode, download manager, bookmarks, and tab management

### [Garmin AI Chat](garmin-ai-chat/README.md)

A Connect IQ app that brings conversational AI to your Garmin vívoactive 5, powered by NVIDIA's API.

- Start and continue AI conversations on your watch
- Multiple AI models (NVIDIA, Meta, Mistral, Google, OpenAI)
- Phone companion app for easy API key configuration
- Persistent local storage for conversations

### [GUI Controller](gui-controller/)

A Python-based GUI automation framework for Ubuntu with virtual display support.

- Virtual framebuffer (Xvfb) and Openbox window manager integration
- Screenshot capture and visual verification
- Input simulation via xdotool
- Minesweeper grid detection and interaction

## Workflows

This repository uses GitHub Actions for automation:

| Workflow | Description |
|----------|-------------|
| OpenCode v1 | Autonomous AI coding agent |
| OpenCode v2 | Autonomous AI coding agent (v2) |
| OpenCode v3 | AI coding agent with GUI interaction capabilities |
| Issue Solver | Automated issue handling |
| PR Handler | Pull request automation |
| macOS | Cross-platform macOS builds |
| Linux (noVNC) | Linux environment with virtual display |
| Linux (nonoVNC) | Linux environment without virtual display |
| Test | Automated testing workflow |
| VNC Clean | VNC cleanup and maintenance |

## License

MIT
