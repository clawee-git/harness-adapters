# example adapter (template)

Copy this directory to `adapters/<harness>/` and fill in the four files.
Replace this table with the harness's own events:

| harness event | clawee kind | text |
|---|---|---|
| (an event that asks the human something) | `question` | the question |
| (an event that wants approval) | `permission` | what is to be approved |
| (the task ended) | `done` | — |

Minimum clawee cli: state it here.

## Install / uninstall

`install.sh` / `uninstall.sh` — wire and unwire the harness's hook mechanism
to `hook.sh`; keep a backup; touch nothing else.

## Test

`smoke_test.sh` runs `hook.sh` against `tools/fake-clawee.sh` and asserts the
argv.

## No adapter: a job that reports its own status

A harness that emits OSC 7501 needs no adapter (`CONTRACT.md` §0), and neither
does a non-agentic job you wrap yourself: a build, a backup, a sync. The
[Program Status Protocol](https://www.superlogical.com/rex/docs/build/program-status)
gives a shell function for it; this is that function, kept POSIX and inside
the spec's limits:

```sh
status() {
  msg=$(printf '%s' "$2" | tr -d '\000-\037\177' | head -c 2048 | base64 | tr -d '\n')
  printf '\033]7501;state=%s:msg=%s\033\\' "$1" "$msg" >/dev/tty 2>/dev/null || :
}

status working "Syncing photos"
rsync -a ~/Photos backup:/photos && status done "Photos synced" || status error "rsync failed"
```

- It writes to the session's tty, not stdout, so a redirected or piped job
  still reports, and it never fails the job: outside a terminal it does
  nothing.
- `\033` and `\\` are POSIX `printf`; the spec's `\e` is not. The report ends
  with ST (`ESC \`).
- `msg` is base64 on one line (`tr -d '\n'`: wrapped base64 breaks the
  report). Control characters are removed first, because the spec discards a
  report whose text holds one, and the text is cut to 2048 bytes, the spec's
  decoded `msg` limit (2732 bytes encoded; the whole sequence stays far under
  4096). The cut counts bytes, so keep messages short enough that it never
  splits a character.
- `state` is one of the spec's states; inside clawee, `working` hides hook
  signals and the quiet heuristic until the job reports `done` or `error`, or
  exits.
- Needs `base64` and `head -c` (coreutils on Linux, base system on macOS).
