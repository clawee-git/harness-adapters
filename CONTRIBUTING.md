# Contributing an adapter

One directory per harness: `adapters/<harness>/`, lowercase, hyphenated. It
holds:

| file | what |
|---|---|
| `README.md` | what the harness is, which of its events map to which kind (a table), the minimum clawee cli version, how to install/uninstall |
| `install.sh` | idempotent; wires the harness's hook mechanism to the adapter; never touches anything but the harness's own config, and keeps a backup |
| `uninstall.sh` | removes exactly what `install.sh` added |
| the adapter itself | a hook script (`hook.sh`) or a small program; reads the harness's event, calls `clawee sessions signal "/$CLAWEE_SID" <kind> [text]`; exits 0 whatever happens |
| `smoke_test.sh` | runs the adapter against `tools/fake-clawee.sh` and asserts the argv it produced |

Rules every adapter follows:

1. **Best-effort, never in the harness's way.** No `CLAWEE_SID` → exit 0. clawee
   missing or failing → exit 0. A hook that breaks the harness is a bug.
2. **Only the contract's kinds** (`CONTRACT.md` §3). Map the harness's events
   conservatively: when in doubt, `question`.
3. **No secrets, no network of its own.** The adapter talks to `clawee` and
   nothing else.
4. **POSIX sh + python3 (stdlib) at most.** Anything the gateway host may not
   have is a dependency the README must state.
5. **A smoke test that needs no daemon.** `tools/fake-clawee.sh` records every
   invocation to `$FAKE_CLAWEE_LOG`; assert on that file.

## Adding one

```
cp -r adapters/example adapters/<harness>
```

edit the four files, run `adapters/<harness>/smoke_test.sh`, open a PR
against `dev`. The review checks the rules above, the kind mapping table, and
that `smoke_test.sh` fails when the hook sends the wrong kind (make it fail
once on purpose).

## Repo conventions

- Trunk `main`, integration on `dev`; PRs into `dev`, merged as merge commits.
- No GitHub Actions for first-party checks; `tools/run-tests.sh` runs every
  adapter's smoke test and is what a reviewer runs.
- MIT licence; by contributing you agree your contribution is MIT too.
