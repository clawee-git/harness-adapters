# The adapter contract

An adapter turns a harness's own events into clawee attention signals, and
(optionally) reads clawee chat as instructions for an agent that is the
session's writer. This file is the whole contract; it links to the wire
definition in `clawee-git/core` (`protocol/viewers.go`, and the README's
"Viewers" section) and never restates it.

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
| `waiting` | the daemon's OWN quiet detection (heuristic); an adapter may send it too | new output, a keystroke |
| `none` | clear the state explicitly | — |

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
