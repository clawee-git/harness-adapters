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
- Tests: `tools/run-tests.sh` runs every `adapters/*/smoke_test.sh` in turn,
  then exits non-zero if any failed. Each runs against `tools/fake-clawee.sh`,
  which stands in for the clawee cli: put first on `PATH` as `clawee`, it
  records its argv, one invocation per line, to `$FAKE_CLAWEE_LOG` and exits 0.
  The smoke tests set `HOME` to a scratch folder, so nothing reaches a real
  `~/.claude`; run them on the CI box (`masdetta-ci`).
  No daemon, no network. No GitHub Actions — the reviewer runs it.
- Reference adapter: `adapters/claude-code/` (`Notification` → `permission` /
  `question`, `Stop` → `done`, `UserPromptSubmit` → the turn hook
  `clawee message inbox --pending --format prompt`; `install.sh` merges those
  three hooks into `~/.claude/settings.json` with a `.clawee-bak` backup and
  runs `claude mcp add --scope user clawee -- clawee mcp`, leaving a
  `<settings>.clawee-mcp` marker; `uninstall.sh` removes exactly those hooks,
  and the server only when the marker says install added it).
  `tools/fake-claude.sh` stands in for `claude` in the smoke test: argv to
  `$FAKE_CLAUDE_LOG`, a user-scope MCP list in `$FAKE_CLAUDE_MCP`.
  `fake-clawee.sh` prints `$FAKE_CLAWEE_STDOUT` and exits `$FAKE_CLAWEE_EXIT`
  when set. `adapters/example/` is the template
  (`CONTRIBUTING.md`).
- Born in project `2026-09-05-clawee-session-viewers` (feature 07) in
  `clawee-git/resources`.
