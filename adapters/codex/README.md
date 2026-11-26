# Codex adapter

Reports the Codex conversation running in a clawee session, so claweed can
resume it after a crash (`CONTRACT.md` §8).

| Codex event | sends |
|---|---|
| `SessionStart` (every `source`) | `clawee sessions harness "/$CLAWEE_SID" codex <session_id> --start-dir <cwd> [--transcript <transcript_path>]` |
| `SessionEnd` | nothing |

- The start directory is the start event's `cwd`, made absolute; with none,
  nothing is sent. `--transcript` is sent only when `transcript_path` is a
  non-empty string (Codex sends `null` when it has none).
- **Never `--clear`.** In Codex 0.172.0 `SessionEnd.reason` is always
  `other`, for a quit, a signal and a crash alike, so no end is known to be
  deliberate. A deliberate quit is still safe: the shell is back in front, so
  claweed does not treat the report as in force. No `SessionEnd` hook is
  installed.
- Best-effort: no `CLAWEE_SID`, no `clawee` on `PATH` (`CLAWEE_BIN`
  overrides), bad input or a refused call → silent, exit 0.

Minimum clawee cli: the release with `clawee sessions harness`.

## Install, update, remove

```
adapters/codex/install.sh      # merges one SessionStart hook into $CODEX_HOME/hooks.json
adapters/codex/uninstall.sh    # removes exactly that hook
```

`CODEX_HOME` defaults to `~/.codex`. Codex plugins can no longer carry hooks,
so this is the only path. `install.sh` is idempotent, keeps a
`hooks.json.clawee-bak` from its first run and edits nothing else (no
`config.toml`). **Codex does not run a new hook until you approve it:** open
Codex and review the hook in `/hooks`. To update, pull the checkout; a moved
checkout needs `uninstall.sh` from the old path and `install.sh` from the new.

## Test

`adapters/codex/smoke_test.sh`: the hook against `tools/fake-clawee.sh` with
Codex 0.172.0's input shape, and install / uninstall in a scratch
`CODEX_HOME`.
