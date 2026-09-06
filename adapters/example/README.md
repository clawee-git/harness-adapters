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
