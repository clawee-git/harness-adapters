# harness-adapters — attention signals and chat for clawee sessions

A clawee session is a room: **one writer** (the device holding the keyboard),
any number of **viewers**, an **attention state** (`none | question |
permission | idle | done | waiting | working | error`) shown in every client's session list, and
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

**Program status comes first.** A harness that reports its own state with
OSC 7501 (the [Program Status
Protocol](https://www.superlogical.com/rex/docs/build/program-status); Claude
Code from v2.1.295) needs no adapter: clawee's holder reads the report from
the session's output, and it outranks any hook. Adapters are the fallback for
harnesses that do not emit it (`CONTRACT.md` §0).

**Messages reach a model through MCP.** `clawee mcp` is one stdio MCP server
for any MCP harness (Claude Code, Grok, Codex); a turn hook running
`clawee message inbox --pending --format prompt` is the optional backup. A
harness in a person's session sends as the person only when they confirmed
it or handed the message over (`CONTRACT.md` §5).

**Notifications need no adapter.** claweed broadcasts status on topics
(`session.state`, `harness.state`, `project.state`, …); a subscriber runs
`clawee notify watch <topic>` and decides what to do. What an agent does with
each state is `CONTRACT.md` §6.

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

The preferred path is the Claude Code plugin: this repo is its marketplace
(`claude plugin marketplace add clawee-git/harness-adapters`, then `claude
plugin install clawee@harness-adapters`). The fallback installer merges five
hooks (`Notification`, `Stop`, `UserPromptSubmit`, `SessionStart`,
`SessionEnd`) into `~/.claude/settings.json` (a backup is kept beside it) and
registers the MCP server with `claude mcp add --scope user clawee -- clawee mcp`.
`uninstall.sh` removes exactly those five hooks, and the MCP server only when
the installer added it; use one path, not both (`adapters/claude-code/README.md`).
Codex and Grok report their conversation for crash resume through
`adapters/codex/` and `adapters/grok/` (`CONTRACT.md` §8). Run `adapters/claude-code/smoke_test.sh` to see the adapter drive a fake
`clawee` with the argv it would send.

## Requirements

- clawee cli ≥ the session-viewers release (`clawee sessions signal` exists),
  installed on the gateway host, paired to its local claweed.
- claweed ≥ 0.3.3 on that host (it exports `CLAWEE_SID` into every session's
  shell and serves `session.signal`).
- For messages: a clawee cli with `clawee mcp` and `clawee message`, and a
  claweed that serves them (the harness-mode release).

## Licence

MIT — see `LICENSE`.
