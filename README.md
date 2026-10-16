# svc

A human- and AI-agent-friendly macOS `launchd` service manager.

Think `systemctl` or `pm2`, but built natively and zero-dependency for macOS `launchd`.

---

## Why `svc`?

Managing local background services on macOS with native `launchctl` is notoriously painful:
- Modern macOS requires targeting complex domains (`gui/501/...` instead of simple labels).
- Starting an on-demand service needs `bootstrap` + `kickstart`, while stopping needs `kill SIGTERM`.
- Stopping a `KeepAlive=true` service with `kill` causes `launchd` to instantly respawn it (requiring `bootout`).
- To check logs or configurations, you have to remember deeply nested `.plist` paths.

`svc` wraps all of this into an intuitive, zero-dependency CLI that feels like `systemctl` on Linux.

## Features

- **Intuitive Lifecycle Controls**: `start`, `stop`, `restart`, `status`, `list`.
- **Smart KeepAlive Handling**: Transparently handles on-demand vs. persistent `KeepAlive` services without accidental respawns.
- **Fuzzy Matching**: Type `svc start relay` instead of `svc start com.myorg.openalice.relay`.
- **Automatic Log Tailing**: `svc log <name>` inspects `StandardOutPath` / `StandardErrorPath` directly from the plist and runs `tail -f`.
- **Agent / Script Friendly**: Add `--json` to any command for clean machine-readable JSON output (ideal for LLM agents, automation, or custom status bars).
- **Zero Dependencies**: Pure Bash, works out of the box on standard macOS Monterey, Ventura, Sonoma, and Sequoia.

---

## Quick Comparison

| Task | Native `launchctl` (macOS 10.10+) | With `svc` |
|---|---|---|
| View all user services | `launchctl list \| grep -v com.apple` (cryptic columns) | `svc list` (clean color table) |
| Start on-demand service | `launchctl kickstart -k gui/501/com.foo` | `svc start foo` |
| Stop persistent daemon | `launchctl bootout gui/501/com.foo` | `svc stop foo` |
| View service status | `launchctl print gui/501/com.foo` (100+ raw lines) | `svc status foo` |
| Stream service logs | Find plist, read `StandardOutPath`, `tail -f ...` | `svc log foo -f` |
| Inspect plist config | Find plist, `cat / plutil -p ...` | `svc cat foo` |
| JSON output for AI/scripts | ❌ Not supported | `svc list --json`, `svc status foo --json` |

---

## Installation

### One-line curl:
```bash
curl -fsSL https://raw.githubusercontent.com/iridite/svc/main/install.sh | bash
```

### Or clone and link:
```bash
git clone https://github.com/iridite/svc.git ~/Projects/svc
ln -s ~/Projects/svc/bin/svc ~/.local/bin/svc
```

Ensure `~/.local/bin` is in your `PATH`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## Usage

### Human-Friendly Commands

```bash
# List all your LaunchAgents with color status
svc list

# Check status of a service (fuzzy matching 'relay' -> 'com.openalice.relay')
svc status relay

# Start, Stop, or Restart
svc start relay
svc stop relay
svc restart hapi

# Tail stdout/stderr logs automatically
svc log relay -n 100 -f

# Inspect plist definition
svc cat relay

# Resolve plist path and domain
svc which relay
```

### Agent- / Machine-Friendly (`--json`)

Any LLM Agent (like Claude, Codex, OMP) or script can inspect services deterministically:

```bash
svc status relay --json
```
Output:
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

```bash
svc list --json
```

---

## License

MIT © [iridite](https://github.com/iridite)
