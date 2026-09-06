# Claude Code adapter

Turns Claude Code's hook events into clawee attention signals for the session
Claude Code runs in.

| Claude Code event | payload | clawee kind | text |
|---|---|---|---|
| `Notification` | `notification_type: permission_prompt` | `permission` | the notification message |
| `Notification` | any other type (`idle_prompt`, a question) | `question` | the notification message |
| `Stop` | — | `done` | — |

Minimum clawee cli: the session-viewers release (`clawee sessions signal`).
The host's claweed must be ≥ 0.3.3 (exports `CLAWEE_SID`).

## Install

On the gateway host (where Claude Code runs inside a clawee session):

```
adapters/claude-code/install.sh      # merges two hooks into ~/.claude/settings.json
adapters/claude-code/uninstall.sh    # removes exactly those two
```

`CLAUDE_SETTINGS=<path>` points both at another settings file. The hook
command is the absolute path of this directory's `hook.sh`, so move the
checkout and re-run `install.sh`.

## How it works

`hook.sh <event>` reads the event JSON on stdin, picks the kind from the
table, and runs `clawee sessions signal "/$CLAWEE_SID" <kind> [text]`. It
exits 0 always: outside a clawee session (`CLAWEE_SID` unset), with no
`clawee` on `PATH`, or on a failed signal, Claude Code sees nothing.

## Test

```
adapters/claude-code/smoke_test.sh
```

runs the hook against `tools/fake-clawee.sh`, asserts the recorded argv for
each event, and round-trips install/uninstall on a scratch settings file.
