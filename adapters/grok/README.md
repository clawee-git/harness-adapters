# Grok adapter

Reports the Grok conversation running in a clawee session, so claweed can
resume it after a crash (`CONTRACT.md` §8).

| Grok event | sends |
|---|---|
| `SessionStart` (`new`, `load`) | `clawee sessions harness "/$CLAWEE_SID" grok <sessionId> --start-dir <cwd>` |
| `SessionEnd` | nothing (see "End reasons") |

- The session id is `sessionId`, falling back to `session_id`. The start
  directory is the event's `cwd`, the directory Grok was launched in and the
  one it keys `~/.grok/sessions/` by, made absolute. Never the hook's working
  directory, `GROK_WORKSPACE_ROOT` or `CLAUDE_PROJECT_DIR`: Grok runs hooks in
  the workspace root and sets both to it.
- No `--transcript`: Grok events carry no transcript path.
- An event carrying `subagentType` (a child session) is ignored, start and end.
- Grok also runs `~/.claude/settings.json` hooks; the Claude Code adapter stays
  silent on `SessionStart` / `SessionEnd` when `GROK_HOOK_EVENT` is set, so
  Grok is reported once, by this adapter.
- Best-effort: no `CLAWEE_SID`, no `clawee` on `PATH` (`CLAWEE_BIN`
  overrides), bad input or a refused call → silent, exit 0.

## End reasons

The adapter sends `--clear` only for `SessionEnd` reasons proven on Grok to
mark a deliberate end. **None is proven yet** for 1.0.92: its guide names no
values, and the logging-hook probe (quit by `/exit` or Ctrl-D, SIGHUP,
SIGTERM) has not been run. Until it is, the set is empty and Grok never
clears. That is safe: after a deliberate quit the shell is back in front, so
claweed does not treat the report as in force. Proven values go into
`deliberate_end_reasons` in `hook.sh` and into this section.

## Install, update, remove

```
adapters/grok/install.sh      # writes ${GROK_HOME:-~/.grok}/hooks/clawee.json
adapters/grok/uninstall.sh    # removes that file, only if this adapter wrote it
```

One file of its own, so no other hook is touched; `install.sh` refuses when a
`clawee.json` there was not written by this adapter. The `--clear` call, once a
reason is proven, is started detached so the hook returns at once. Each handler has a 10 s
`timeout` (Grok's `SessionEnd` default is 1.5 s) and the call itself is cut
at 8 s. Grok runs your hooks only in a trusted folder (`/hooks-trust`; your
home directory always counts). Re-run `install.sh` after moving the checkout.

## Test

`adapters/grok/smoke_test.sh`: the hook against `tools/fake-clawee.sh` with
Grok's input shape (launched in a subfolder of its workspace root), and
install / uninstall under a scratch `HOME` and `GROK_HOME`.
