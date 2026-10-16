# AGENTS.md — Guidance for AI Coding Agents

This file provides architectural context, development guidelines, and testing discipline for AI coding assistants (Claude Code, OpenAI Codex, OpenCode, OMP) contributing to `svc`.

---

## 1. Project Philosophy

- **Zero Runtime Dependencies**: `svc` must stay a self-contained Bash script. Do NOT introduce Node.js, Python, Ruby, or Homebrew package dependencies.
- **Mac-Native**: Build on native macOS tools (`launchctl`, `plutil`, `awk`, `tail`).
- **Simplicity First**: Implement the minimum code required. Reject speculative features or complex class-like abstractions inside the shell script.
- **Agent-First Observability**: Every new query command must provide a structured, machine-parsable `--json` mode alongside its human-readable terminal output.

---

## 2. Codebase Organization

```text
bin/svc              The executable shell script. Entry point for all commands.
docs/architecture.md Detailed technical architecture and launchd state transitions.
tests/test_svc.sh    End-to-end and regression test suite.
install.sh           One-line install script.
AGENTS.md            Instructions and constraints for AI agents (this file).
README.md            Human-facing user documentation and showcase.
```

---

## 3. Engineering Boundaries & Invariants

1. **GUI Domain Exclusivity**:
   - Always target `gui/<uid>` (e.g. `gui/$(id -u)`), NEVER `user/<uid>` or bare service labels.
   - User LaunchAgents in `~/Library/LaunchAgents` require the GUI session to access WindowServer, keychain, and desktop notifications.

2. **The KeepAlive Invariant**:
   - If a service has `KeepAlive=true`, `launchctl kill SIGTERM` will cause `launchd` to immediately respawn it (often in <0.5s).
   - Stopping a `KeepAlive=true` service MUST use `launchctl bootout <domain>/<label>`.
   - Stopping an on-demand service (`KeepAlive=false`) should use `launchctl kill SIGTERM <domain>/<label>` so it remains loaded and ready for subsequent triggers.

3. **Fuzzy Match Safety**:
   - Ambiguous queries matching more than one plist must abort cleanly with an error list, unless one candidate is an exact string match.

---

## 4. Development Workflow & Testing Discipline

Before submitting or committing any change:

1. **Syntax & Linting**:
   - Check Bash syntax: `bash -n bin/svc`
   - Check POSIX compatibility where applicable.

2. **Run Test Suite**:
   ```bash
   ./tests/test_svc.sh
   ```
   All test cases must pass.

3. **Regression Tests**:
   - Every bug fix or new command must add an assertion in `tests/test_svc.sh`.
   - Never mock `launchctl` if live non-destructive user LaunchAgents can be inspected.

---

## 5. Non-Goals

- Managing system daemons (`/Library/LaunchDaemons` requiring `sudo`).
- Modifying system-protected plists in `/System/Library/`.
- Managing third-party process managers (Docker, PM2, systemd). `svc` is strictly for macOS `launchd`.
