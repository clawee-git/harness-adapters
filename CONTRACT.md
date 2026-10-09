# The adapter contract

An adapter turns a harness's own events into clawee attention signals, and
(optionally) reads clawee chat as instructions for an agent that is the
session's writer. This file is the whole contract; it links to the wire
definition in `clawee-git/core` (`protocol/viewers.go`, and the README's
"Viewers" section) and never restates it.

## 0. Program status first

A harness that reports its own state with **OSC 7501** (the [Program Status
Protocol](https://www.superlogical.com/rex/docs/build/program-status)) needs
**no adapter**. The escape is plain bytes in the session's output, so clawee's
holder (the terminal of record for every session) reads it on every route:
local, ssh, relayed, and through an `ssh` inside the session. The grammar, the
states and the limits are the spec's; how clawee parses them and maps them
onto attention is core's README, "Viewers" → "Program status (OSC 7501)".
This file restates neither.

- **The holder answers the support query.** A program probes with `OSC 7501
  ; ?`; the holder replies `OSC 7501 ; ?` while a program (not the session
  shell) is in the foreground. Claude Code ≥ 2.1.295 sends that probe once,
  at startup, and reports **only when it is answered**: a Claude Code process
  started before its host's claweed carried program status stays silent until
  it is restarted. Nothing in the session's environment changes.
- **Precedence: program > hook > heuristic**, keyed on a **live** program
  record. While the program's record is `working` or `blocked`, a hook signal
  is stored but not shown, and the daemon's quiet detection does not run. A
  non-live record (`done`, `error`, `idle`) is shown, and a newer hook signal
  or quiet detection replaces it. A keystroke never clears program-sourced
  attention: the program's next report does. Hook signals sent while the
  record was live are dropped when it ends; they never reappear.
- **Adapters are the fallback**, for a harness that does not emit OSC 7501
  (or an older version of one that does). Everything below still holds for
  them.
- **A non-agentic job can report too.** A wrapper script around a build or a
  sync writes the escape to the session's tty itself; see the `status()`
  snippet in `adapters/example/README.md`.

## 1. Where an adapter runs

Inside the session — on the clawee **gateway** host, in the shell claweed
spawned — because that is where the harness runs and where its hooks fire.
The adapter therefore talks to the host's OWN claweed over the local link,
through the `clawee` cli installed on that host. Nothing here reaches the
operator's laptop; the daemon fans the signal out to every client.

## 2. Which session am I in?

claweed exports **`CLAWEE_SID`** — the session id — into every session's
shell environment (daemon ≥ 0.3.3). The session's clawee address from inside
the session is therefore

```
/$CLAWEE_SID
```

(the bare `/session` form: the pinned gateway, which on the gateway host is
the local link; the sid is an exact match, and a unique prefix also works).
An adapter that finds `CLAWEE_SID` unset is not running inside a clawee
session and MUST exit 0 silently — a harness used outside clawee must never
see an error from the hook.

## 3. Signalling attention

```
clawee sessions signal <addr> <kind> [text ...]
```

Kinds, and what they mean to a human looking at the session list:

| kind | meaning | who clears it |
|---|---|---|
| `question` | the harness asked the human something | the writer's next keystroke, or new output |
| `permission` | the harness wants an action approved | the writer's next keystroke, or new output |
| `idle` | the harness reports nothing to do | the writer's next keystroke, or a `none` |
| `done` | the harness reports the task finished | the writer's next keystroke, or a `none` |
| `working` | the harness reports it is busy | the writer's next keystroke, or a `none` — never new output |
| `error` | the harness reports the task failed | the writer's next keystroke, or a `none` — never new output |
| `waiting` | the daemon's OWN quiet detection (heuristic); an adapter may send it too | new output, a keystroke |
| `none` | clear the state explicitly | — |

The clearing column is for hook-sourced attention. Program-sourced attention
(§0) ignores keystrokes and output: the program's next report or its `clear`
replaces it, `working` and `blocked` end when the program exits, and a `none`
hides the current report until the program's next one.

**Source.** Attention comes from one of three sources: `program` (an OSC 7501
report, §0), `hook` (an adapter's `signal`), or `heuristic` (the daemon's quiet
detection). An adapter never sets it; `clawee sessions signal` is always a
`hook`. On the wire only program attention carries the `source` field; a
reader that meets attention without it reads `waiting` as `heuristic` and
every other kind as `hook` (core's `EffectiveSource`), which is also how an
older daemon's attention reads. Precedence between the three is §0's.

`text` is a short free line (the question, the command awaiting approval),
shown beside the kind. Kinds are **append-only**: a future release may add
one, never rename or remove one; an adapter that sends a kind the daemon does
not know is refused with a usage error and should treat that as "signal
unsupported", not as a failure of the harness.

An adapter that speaks the wire directly (no cli) sends `session.signal
{sid, kind, text?}` on a control stream — see core.

**Exit status.** `clawee sessions signal` exits 0 on success, 1 on a chain
failure, 2 on a usage error (unknown kind, bad address). A hook MUST NOT
propagate a non-zero status to the harness: signalling is best-effort.

## 4. Reading chat as an agent writer

An agent that holds the writer role can subscribe to the session's events
(`session.watch` on a control stream, or `clawee agent` which does it for every
gateway) and act on:

- `chat` — one message `{seq, at, device, text, paste}` from a viewer; `paste`
  means the sender meant it as input for the session.
- `role` — `{role: writer|viewer|free, by_device}`: the agent was demoted
  (`viewer`), or the session went free.
- `take_request` — a device asks for the writer role; an agent writer is
  auto-accepted by the daemon and need not answer.

Typing into the session is `clawee sessions send <addr> …`, which exits **3**
with `read-only, taken by <device>` when the agent no longer holds the role;
`clawee sessions take <addr>` asks for it back, `sessions release` gives it up.

## 5. Versioning

- This contract is versioned with the clawee release it ships in; a change
  that adds a kind or an event is a minor bump, a change that alters the
  meaning of an existing one is not allowed.
- Adapters declare the minimum clawee cli version they need in their README.
