# Ralph - Autonomous AI Agent Loop

Ralph is an autonomous AI agent that executes your PRD (Product Requirements Document) story-by-story, implementing each one until all are complete.

## Requirements

- [Amp](https://ampcode.com), [Claude Code](https://claude.ai/code), or [Pi](https://pi.dev) installed and authenticated
- `jq` installed (`brew install jq`)

## Setting up a new project

### 1. Make sure your project has an `AGENTS.md`

Ralph reads `AGENTS.md` at the project root for project-specific instructions — testing requirements, git workflow, documentation rules, architecture guidance. If your project doesn't have one, create it before running Ralph.

### 2. Write your user stories as markdown files

Write each user story as its own markdown file (e.g. in `docs/`). Ralph will generate `prd.json` automatically when you run it.

### 3. Run Ralph

When you run Ralph, it will first generate `prd.json` from your story files using Claude, display the result, and ask you to confirm before starting the loop. Type `yes` to proceed or `no` to abort.

```bash
cd /path/to/your/project
/path/to/ralph/ralph.sh [--tool amp|claude|pi] [max_iterations]
```

**Options:**
- `--tool amp` — Use Amp (default)
- `--tool claude` — Use Claude Code (Sonnet)
- `--tool pi` — Use Pi
- `max_iterations` — Max loops before stopping (default: 10)

**Examples:**
```bash
/path/to/ralph/ralph.sh                    # Amp, max 10 iterations
/path/to/ralph/ralph.sh --tool claude 20   # Claude, max 20 iterations
/path/to/ralph/ralph.sh --tool pi 20       # Pi, max 20 iterations
/path/to/ralph/ralph.sh 5                  # Amp, max 5 iterations
```

### 4. Monitor progress

Ralph logs every iteration to `progress.txt` in the same directory as `prd.json` (project root or `docs/`). Check it to see what was implemented, which files changed, and any patterns discovered. Codebase patterns are consolidated at the top of the file so future iterations learn from earlier ones.

## How Ralph works

On startup, Ralph will:
1. Generate `prd.json` from your markdown story files (using Claude)
2. Display the result and ask for confirmation — type `yes` to proceed, `no` to abort

Each iteration Ralph will:
1. Read `AGENTS.md` for project instructions
2. Find and read `prd.json` (project root or `docs/`) and `progress.txt` (same directory)
3. Pick the highest-priority incomplete story (`passes: false`)
4. Implement it
5. Run quality checks (typecheck, lint, test)
6. Commit all changes if checks pass
7. Mark the story `passes: true` in `prd.json`
8. Append learnings to `progress.txt`
9. Loop — or exit if all stories are complete

## Permissions

Ralph runs Claude with `--permission-mode bypassPermissions` — all tool calls (file writes, shell commands, web fetch) are auto-approved with no prompts. This is required for the autonomous loop to work in `--print` mode.

**Only run Ralph in a sandboxed environment** such as GitHub Codespaces or a Docker container. Do not run it with `--tool claude` directly on your laptop — it has unrestricted access to your filesystem and shell.

Amp (`--tool amp`) uses its own `--dangerously-allow-all` flag for the same reason. Pi (`--tool pi`) runs with `--print` in non-interactive mode — it too has unrestricted filesystem and shell access, so the same sandboxing advice applies.

## Tips

- **Keep stories small.** One story per iteration. If a story takes more than one iteration to implement, split it.
- **Dependency order matters.** Make sure schema/foundation stories come before the stories that depend on them.
- **Check `progress.txt` if something goes wrong.** It will tell you exactly what Ralph tried and why it stopped.
- **Re-run after failures.** If Ralph hits max iterations without finishing, just run it again — it picks up where it left off.
