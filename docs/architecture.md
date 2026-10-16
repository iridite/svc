# svc Architecture & Design

This document details the internal design of `svc`, the modern `launchd` service manager for macOS.

---

## 1. Context & Motivation

Apple's `launchd` is a capable unified service and event broker. However, the command-line interface (`launchctl`) was redesigned in OS X 10.10 (Yosemite) with strict domain target specifiers and lower-level lifecycle semantics (`bootstrap`, `bootout`, `kickstart`, `kill`) that are notoriously user-unfriendly compared to Linux's `systemctl` or process managers like `pm2`.

`svc` bridges this gap: it translates high-level user commands (`start`, `stop`, `restart`, `status`, `log`) into accurate, safe `launchctl` domain invocations.

```
+--------------------------------------------------------+
|                User / AI Coding Agent                  |
|          svc [start|stop|restart|status|log]           |
+---------------------------+----------------------------+
                            |
                            v
+---------------------------+----------------------------+
|                        svc CLI                         |
|  - Fuzzy label resolver                                |
|  - KeepAlive vs. on-demand lifecycle state machine     |
|  - Automatic log inspection (via plutil)               |
|  - Structured JSON & human-friendly color tables       |
+---------------------------+----------------------------+
                            |
                            v
+---------------------------+----------------------------+
|            macOS launchctl (gui/<uid> domain)          |
|    bootstrap / bootout / kickstart -k / kill SIGTERM   |
+--------------------------------------------------------+
```

---

## 2. Domain & Boundary Model

`launchd` operates across multiple hierarchical domains:
- `system/`: Global system daemons (requires root).
- `user/<uid>/`: Headless per-user daemons (no GUI, no WindowServer).
- `gui/<uid>/`: Interactive user GUI sessions (where user LaunchAgents run).

`svc` operates strictly within the current user's **`gui/<uid>`** domain (defaulting to `gui/$(id -u)`).

### Why `gui/<uid>`?
On macOS, user services in `~/Library/LaunchAgents` belong to the user's GUI login session. If a CLI accidentally targets `user/<uid>`, services lose access to WindowServer, keychain, and desktop notifications.

---

## 3. Lifecycle State Machine: KeepAlive vs. On-Demand

One of `launchctl`'s biggest traps is that killing a process does not always stop it:

| Service Type | Defined by Plist | Behavior on `kill SIGTERM` | Correct Stop Action in `svc` |
|---|---|---|---|
| **On-Demand** | `KeepAlive=false`, `RunAtLoad=false` | Exits cleanly, stays loaded in launchd, waits for next invocation. | `launchctl kill SIGTERM gui/<uid>/<label>` |
| **Persistent** | `KeepAlive=true` (e.g. runner/daemon) | `launchd` detects exit and **immediately respawns** a new instance. | `launchctl bootout gui/<uid>/<label>` |

### State Transitions in `svc`:

```
               [ Plist exists in ~/Library/LaunchAgents ]
                                  |
                                  | (svc start)
                                  v
+--------------------------------------------------------------------+
|                         LOADED IN LAUNCHD                          |
|                                                                    |
|  On-Demand:                                                        |
|    - Start:  launchctl kickstart -k gui/<uid>/<label>              |
|    - Stop:   launchctl kill SIGTERM gui/<uid>/<label> (idle)       |
|                                                                    |
|  Persistent (KeepAlive=true):                                      |
|    - Start:  launchctl bootstrap gui/<uid> <plist>                 |
|    - Stop:   launchctl bootout gui/<uid>/<label> (unloaded)        |
|    - Restart: launchctl kickstart -k gui/<uid>/<label>             |
+--------------------------------------------------------------------+
```

---

## 4. Fuzzy Resolution

Users shouldn't need to type `com.company.project.runner`. `svc` resolves service names through a 3-tier lookup:
1. Exact match against filenames in `~/Library/LaunchAgents/*.plist`.
2. Substring match against filenames (e.g. `relay` -> `com.openalice.relay.plist`).
3. Substring match against active labels reported by `launchctl list`.

If more than one service matches, `svc` halts with an unambiguous error listing all candidates, unless one candidate is an exact match.

---

## 5. Agent & Automation Protocol (`--json`)

Every read operation supports `--json`. The JSON format guarantees:
- Predictable types: `loaded` and `running` are integers `1` or `0`; `pid` is integer or `null`.
- Raw metadata: `plist`, `label`, `stdout`, `stderr`, `keepalive`, and `run_at_load`.
- Error payload: structured `{"error": "not_found", "query": "..."}` with exit code `1`.

This allows LLM agents (Claude, Codex, OMP) to reliably parse, monitor, and reason about services without regex-scraping terminal formatting.

---

## 6. Safety & Non-Goals

- **No Root Required**: `svc` does not touch `/System/Library` or `/Library/LaunchDaemons`.
- **Zero Dependencies**: Implemented in pure POSIX Bash, compatible with macOS default tools (`plutil`, `launchctl`, `awk`).
- **No Shadow State**: `svc` keeps no proprietary database or daemon. The single source of truth is `launchd` itself.
