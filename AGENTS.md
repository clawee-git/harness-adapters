# harness-adapters — clawee attention adapters

- Repo: `clawee-git/harness-adapters` (PUBLIC, MIT) · shell + python3 (stdlib)
  only, no Go module · `code/main` is the primary clone on `main`; `code/dev`
  is a permanent linked worktree on `dev`; effort worktrees live under
  `code/.worktrees/<branch>` · `gh.account = clawee-git` (call gh via `ghp`,
  never bare `gh`).
- What it is: hook scripts that turn a coding harness's own events into clawee
  attention signals (`clawee sessions signal "/$CLAWEE_SID" <kind> [text]`),
  one directory per harness under `adapters/`. `CONTRACT.md` is the contract
  (kinds, `CLAWEE_SID`, the chat/role events an agent writer reads);
  `CONTRIBUTING.md` is how to add one. The wire is core's; this repo never
  restates it.
- **Best-effort is the rule**: every hook exits 0 whatever happens — no
  `CLAWEE_SID`, no `clawee`, a refused signal. A hook that breaks the harness
  is a bug.
- Tests: `tools/run-tests.sh` runs every `adapters/*/smoke_test.sh` against
  `tools/fake-clawee.sh` (records argv to `$FAKE_CLAWEE_LOG`); no daemon, no
  network. No GitHub Actions — the reviewer runs it.
- Reference adapter: `adapters/claude-code/` (`Notification` → `permission` /
  `question`, `Stop` → `done`; `install.sh` merges two hooks into
  `~/.claude/settings.json` with a `.clawee-bak` backup, `uninstall.sh`
  removes exactly those). `adapters/example/` is the template
  (`CONTRIBUTING.md`).
- Born in project `2026-09-05-clawee-session-viewers` (feature 07) in
  `clawee-git/resources`.
