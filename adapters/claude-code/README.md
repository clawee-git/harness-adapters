# Claude Code adapter

Turns Claude Code's hook events into clawee attention signals for the session
Claude Code runs in.

## Claude Code ≥ 2.1.295: native program status

Claude Code reports its own state over OSC 7501 from **v2.1.295**
(`CONTRACT.md` §0). It probes once at startup with `OSC 7501 ; ?` and reports
only when the terminal answers, which a claweed with program status does; the
environment plays no part (`TERM_PROGRAM` changes nothing). Its reports are
`working`, `blocked` (permission prompts, with the action as text) and `done`,
and it sends `clear` itself on exit.

- On those versions **this adapter is optional**. If it is installed, the
  program's report outranks it: while Claude Code is `working` or `blocked`
  the hook's signals are not shown.
- It stays **the fallback** for older Claude Code, for a host whose claweed
  does not answer the probe yet, and for a Claude Code process started before
  that claweed was installed (it stays silent until restarted).

| Claude Code event | payload | clawee kind | text |
|---|---|---|---|
| `Notification` | `notification_type: permission_prompt` | `permission` | the notification message |
| `Notification` | any other type (`idle_prompt`, a question) | `question` | the notification message |
| `Stop` | — | `done` | — |

**Messages.** `UserPromptSubmit` runs `clawee message inbox --pending --format
prompt` and prints its output, which Claude Code adds to the turn's context:
this terminal's pending messages in clawee's fixed frame, or nothing. The main
path is the MCP server `clawee mcp`, which `install.sh` registers
(`CONTRACT.md` §5). Both need a clawee cli with `message` and `mcp`; an older
cli prints nothing and the hook still exits 0.

Minimum clawee cli: the session-viewers release (`clawee sessions signal`).
The host's claweed must be ≥ 0.3.3 (exports `CLAWEE_SID`).

**Harness session.** `SessionStart` (every `source`) runs `clawee sessions
harness "/$CLAWEE_SID" claude-code <session_id> --start-dir
<CLAUDE_PROJECT_DIR> --transcript <transcript_path>`, so claweed can resume
the conversation after a crash (`CONTRACT.md` §8). The start directory is
`CLAUDE_PROJECT_DIR` made absolute, never the hook's `cwd` (it moves with a
`cd`); with none set, nothing is sent. `SessionEnd` sends `clawee sessions
harness "/$CLAWEE_SID" claude-code --clear` only for `prompt_input_exit` and
`logout`; `clear` and `resume` (a new start reports the next conversation),
and `other` (signals included) send nothing. With `GROK_HOOK_EVENT` set (Grok
runs these hooks too) both events are silent, so Grok is reported once by its
own adapter; the other three events behave as under Claude Code.

## Plugin (preferred)

This repo is a Claude Code plugin marketplace (`.claude-plugin/marketplace.json`);
the plugin `clawee` is this directory. It carries all five hooks through
`${CLAUDE_PLUGIN_ROOT}/hook.sh <Event>` and the `clawee mcp` server
(`.mcp.json`), so it replaces `install.sh` entirely.

```
adapters/claude-code/uninstall.sh                  # first, if install.sh was used
claude plugin marketplace add clawee-git/harness-adapters
claude plugin install clawee@harness-adapters      # update: claude plugin update clawee@harness-adapters
claude plugin uninstall clawee@harness-adapters    # remove
```

The two paths exclude each other: `install.sh` refuses, naming the plugin,
while `clawee@harness-adapters` is enabled in the settings file; nothing stops
enabling the plugin over an `install.sh` setup, so run `uninstall.sh` first or
every hook fires twice.

## Install (fallback)

On the gateway host (where Claude Code runs inside a clawee session):

```
adapters/claude-code/install.sh      # merges five hooks into ~/.claude/settings.json, registers clawee mcp
adapters/claude-code/uninstall.sh    # removes exactly what install added
```

`CLAUDE_SETTINGS=<path>` points both at another settings file. The hook
command is the absolute path of this directory's `hook.sh`, so move the
checkout and re-run `install.sh`.

`install.sh` is idempotent: a hook already present is not added twice. On its
first run it copies the settings file to `<settings>.clawee-bak` beside it
and never overwrites that backup. It touches nothing in the file but the five
hooks.

The MCP server is registered with `claude mcp add --scope user clawee --
clawee mcp`, since Claude Code does not read user-scope MCP servers from
`settings.json`. When that succeeds, `install.sh` writes
`<settings>.clawee-mcp`. Both scripts check the marker against
`claude mcp get clawee`: a re-run with the marker and the server present adds
nothing, and one whose server was removed by hand registers it again.
`uninstall.sh` runs `claude mcp remove --scope user clawee` only when the
marker is there and the server still is; a server already gone just loses its
marker ("already removed"). A `clawee` server you registered yourself has no
marker and is left alone. With no `claude` on `PATH` (`CLAUDE_BIN` overrides
it) the installer adds the hooks and prints the command to run.

## How it works

Claude Code runs `hook.sh <event>` as a hook, with `<event>` one of
`Notification`, `Stop`, `UserPromptSubmit`, `SessionStart` or `SessionEnd`
(`settings.snippet.json`); any
other event sends nothing. The hook reads the event JSON on stdin, picks the kind from the
table, and runs `clawee sessions signal "/$CLAWEE_SID" <kind> [text]`: one
signal per event. It exits 0 always: outside a clawee session (`CLAWEE_SID`,
which claweed sets in every session's shell, is unset), with no `clawee` on
`PATH`, or on a failed signal, Claude Code sees nothing. `CLAWEE_BIN`
overrides the path of the clawee cli.

A `Notification` payload is parsed with python3's `json` module, the one
parser every gateway host has. A missing or malformed payload still signals a
`question`.

## Test

```
adapters/claude-code/smoke_test.sh
```

runs the hook against `tools/fake-clawee.sh`, asserts the recorded argv and
the turn hook's output for each event, and round-trips install/uninstall
against `tools/fake-claude.sh` on a scratch settings file and `HOME`: twice
each, over pre-existing hooks, and over a `clawee` server it did not add. It
checks the plugin manifest, `hooks/hooks.json`, `.mcp.json` and the
marketplace entry, and the plugin / `install.sh` exclusion. With
`CLAUDE_VALIDATE_BIN` set to a real `claude` it also runs `claude plugin
validate` on the plugin and the marketplace; otherwise it says it skipped.
