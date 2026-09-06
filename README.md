# harness-adapters — attention signals and chat for clawee sessions

A clawee session is a room: **one writer** (the device holding the keyboard),
any number of **viewers**, an **attention state** (`none | question |
permission | idle | done | waiting`) shown in every client's session list, and
a **chat** the viewers use to talk to the writer — human or agent.

A coding harness running inside a session (Claude Code, Codex, aider, …) knows
when it is waiting for a human: a permission prompt, a question, a finished
task. clawee's daemon can only guess that from a quiet screen. An **adapter**
closes the gap: a small hook that translates the harness's own events into
clawee attention signals, so the phone in your pocket says *"build wants
permission"* instead of *"live"*.

```
harness event ──(hook)──▶ clawee sessions signal "/$CLAWEE_SID" permission "Allow rm -rf?"
                                                 └── the daemon marks the session; every viewer sees it
```

Adapters live here, one directory per harness under `adapters/`. The contract
they implement is `CONTRACT.md`; how to add one is `CONTRIBUTING.md`. The
reference adapter is `adapters/claude-code/`.

## Install (Claude Code)

On the machine where the session's shell runs (the clawee **gateway** host),
with `clawee` installed and paired to that host's own daemon over the local
link:

```
git clone https://github.com/clawee-git/harness-adapters.git
harness-adapters/adapters/claude-code/install.sh
```

The installer merges two hooks into `~/.claude/settings.json` (a backup is
kept beside it) and does nothing else. `uninstall.sh` removes exactly those
two. Run `adapters/claude-code/smoke_test.sh` to see the adapter drive a fake
`clawee` with the argv it would send.

## Requirements

- clawee cli ≥ the session-viewers release (`clawee sessions signal` exists),
  installed on the gateway host, paired to its local claweed.
- claweed ≥ 0.3.3 on that host (it exports `CLAWEE_SID` into every session's
  shell and serves `session.signal`).

## Licence

MIT — see `LICENSE`.
