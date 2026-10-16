<div align="center">

# `svc`

### A human- and agent-friendly macOS `launchd` service manager.

[![macOS](https://img.shields.io/badge/macOS-12%2B-black?style=flat&logo=apple)](https://apple.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zero Dependency](https://img.shields.io/badge/Dependencies-Zero%20(Pure%20Bash)-success.svg)](bin/svc)
[![Agent Friendly](https://img.shields.io/badge/AI%20Agent-JSON%20Ready-purple.svg)](#agent---json-mode)

*Think `systemctl` or `pm2`, but native, zero-dependency, and built for macOS `launchd`.*

</div>

---

## 💡 Why `svc`?

Managing local background services on macOS with native `launchctl` has been painful ever since OS X 10.10:
- **Cryptic Domain Syntax**: Commands require targeting `gui/501/...` instead of human-friendly names.
- **The KeepAlive Respawn Trap**: Running `kill SIGTERM` on a `KeepAlive=true` service causes `launchd` to immediately restart it in 0.4 seconds. Truly stopping it requires `bootout`.
- **Two-phase Lifecycle**: Starting an on-demand service needs both `bootstrap` and `kickstart -k`.
- **Log Scavenging**: To check stderr/stdout, you must manually locate the `.plist`, extract `StandardOutPath`, and then run `tail`.

`svc` eliminates all of this boilerplate. It provides an ergonomic CLI that feels like `systemctl` on Linux, while remaining **100% faithful to native macOS launchd semantics**.

---

## ✨ Features

- **🚀 Systemctl-style Commands**: `svc start`, `svc stop`, `svc restart`, `svc status`, `svc list`.
- **🔒 Native Enable / Disable**: `svc enable` and `svc disable` to persist boot/login autostart in macOS launchd's disabled database without mutating plist files.
- **🔍 Smart Fuzzy Matching**: Run `svc start relay` instead of `svc start com.mycompany.openalice.relay`.
- **🛡️ KeepAlive Aware**: Transparently distinguishes on-demand services (clean signal kill) from persistent daemons (`bootout` to prevent unwanted auto-respawn).
- **📋 Live Colored Status Table**: Clean terminal view of all your LaunchAgents, running PIDs, and active/disabled states.
- **📜 Automatic Log Tailing**: `svc log <name> -f` parses `StandardOutPath` / `StandardErrorPath` directly from plist and streams the log.
- **🤖 Native AI-Agent Protocol**: First-class `--json` flag on every command for structured, predictable output with AI coding tools (Claude Code, Codex, OMP).
- **📦 Zero External Dependencies**: 100% pure POSIX/Bash. No Node.js, no Python, no Rust, no Homebrew required.

---

## 🖥️ Terminal Experience

```text
$ svc list
SERVICE                    STATUS     PID      RESTART/RUN  PLIST
---------------------------------------------------------------------------------------------------
hapi.runner                ! disabled -        keep-alive   ~/Library/LaunchAgents/com.hapi.runner.plist
openalice.relay            ○ loaded   -        on-demand    ~/Library/LaunchAgents/com.openalice.relay.plist
yixian.omp-session-tidy    ○ loaded   -        on-demand    ~/Library/LaunchAgents/com.yixian.omp-session-tidy.plist
```

```text
$ svc status relay
● com.openalice.relay - com.openalice.relay
     Loaded: 1 (/Users/yixian/Library/LaunchAgents/com.openalice.relay.plist)
     Active: active (running)
        PID: 7899
  Last Exit: 0
  KeepAlive: false
  RunAtLoad: false
     Stdout: /Users/yixian/.openalice/logs/relay.stdout.log
     Stderr: /Users/yixian/.openalice/logs/relay.stderr.log
```

---

## ⚡ Quick Comparison

| Operation | Native macOS `launchctl` (10.10+) | With `svc` |
|---|---|---|
| **View user services** | `launchctl list \| grep -v com.apple` *(cryptic numbers)* | `svc list` *(colorized dashboard)* |
| **Start on-demand service** | `launchctl kickstart -k gui/501/com.foo` | `svc start foo` |
| **Stop persistent daemon** | `launchctl bootout gui/501/com.foo` | `svc stop foo` |
| **Service status** | `launchctl print gui/501/com.foo` *(100+ raw lines)* | `svc status foo` *(clean summary)* |
| **Follow logs** | Find plist $\rightarrow$ read XML $\rightarrow$ `tail -f <path>` | `svc log foo -f` |
| **Disable autostart** | `launchctl disable gui/501/com.foo` + `bootout` | `svc disable foo` *(no plist editing)* |
| **Enable autostart** | `launchctl enable gui/501/com.foo` | `svc enable foo` |
| **Machine / Agent JSON** | ❌ Not supported | `svc status foo --json` |
---

## 🚀 Installation

### One-line Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/iridite/svc/main/install.sh | bash
```

### Or Manual Install

```bash
git clone https://github.com/iridite/svc.git ~/Projects/svc
ln -s ~/Projects/svc/bin/svc ~/.local/bin/svc
```

Ensure `~/.local/bin` is in your `PATH` (in `~/.zshrc` or `~/.bashrc`):
```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## 📖 Usage Guide

```bash
# Service lifecycle
svc start <name>       # Start or trigger a service
svc stop <name>        # Stop a service (handles KeepAlive correctly)
svc restart <name>     # Restart a service
svc status <name>      # Show detailed status card
svc enable <name>      # Enable service to run/autostart at login
svc disable <name>     # Stop & disable service (prevents login autostart without touching plist)
# Inspection & Logs
svc list               # List all user LaunchAgents
svc log <name> -f      # Follow live logs (stdout/stderr)
svc log <name> -n 100  # Show last 100 lines of log
svc cat <name>         # View raw plist configuration
svc which <name>       # Show resolved label, plist, and domain
```

### 🤖 Agent & Scripting Mode (`--json`)

Every query command supports `--json` for predictable, typed integration:

```bash
svc status relay --json
```

```json
{
  "name": "com.openalice.relay",
  "label": "com.openalice.relay",
  "plist": "/Users/yixian/Library/LaunchAgents/com.openalice.relay.plist",
  "loaded": 1,
  "running": 1,
  "pid": 7899,
  "last_exit": "0",
  "keepalive": false,
  "run_at_load": false,
  "stdout": "/Users/yixian/.openalice/logs/relay.stdout.log",
  "stderr": "/Users/yixian/.openalice/logs/relay.stderr.log"
}
```

---

## 📚 Documentation

- [Architecture & Internal State Machine](docs/architecture.md)
- [Agent Guidance & Conventions](AGENTS.md)

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to check [issues page](https://github.com/iridite/svc/issues).

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat: Add AmazingFeature'`)
4. Run tests: `./tests/test_svc.sh`
5. Push to the Branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for more information.

Copyright (c) 2026 [iridite](https://github.com/iridite)
