# Ralph - Autonomous AI Agent Loop

Ralph is an autonomous AI agent that executes your PRD (Product Requirements Document) story-by-story, implementing each one until all are complete.

## Requirements

- [Amp](https://ampcode.com) or [Claude Code](https://claude.ai/code) installed and authenticated
- `jq` installed (`brew install jq`)

## Setting up a new project

### 1. Make sure your project has an `AGENTS.md`

Ralph reads `AGENTS.md` at the project root for project-specific instructions — testing requirements, git workflow, documentation rules, architecture guidance. If your project doesn't have one, create it before running Ralph.

### 2. Convert your PRD to `prd.json`

Ralph expects a `prd.json` in the project root. If you have a markdown PRD, convert it:

```bash
cd /path/to/your/project
/path/to/ralph/convert-prd.sh /path/to/your/prd.md
```

This uses Claude to parse your PRD and output a `prd.json`. Check the result before running Ralph — make sure stories are in dependency order and acceptance criteria are specific.

Alternatively, create `prd.json` manually using the structure in `prd.json.example`.

### 3. Run Ralph

```bash
cd /path/to/your/project
/path/to/ralph/ralph.sh [--tool amp|claude] [max_iterations]
```

**Options:**
- `--tool amp` — Use Amp (default)
- `--tool claude` — Use Claude Code (Sonnet)
- `max_iterations` — Max loops before stopping (default: 10)

**Examples:**
```bash
/path/to/ralph/ralph.sh                    # Amp, max 10 iterations
/path/to/ralph/ralph.sh --tool claude 20   # Claude, max 20 iterations
/path/to/ralph/ralph.sh 5                  # Amp, max 5 iterations
```

### 4. Monitor progress

Ralph logs every iteration to `progress.txt` in your project root. Check it to see what was implemented, which files changed, and any patterns discovered. Codebase patterns are consolidated at the top of the file so future iterations learn from earlier ones.

## How Ralph works

Each iteration Ralph will:
1. Read `AGENTS.md` for project instructions
2. Read `prd.json` and `progress.txt`
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

Amp (`--tool amp`) uses its own `--dangerously-allow-all` flag for the same reason.

## Tips

- **Keep stories small.** One story per iteration. If a story takes more than one iteration to implement, split it.
- **Dependency order matters.** Make sure schema/foundation stories come before the stories that depend on them.
- **Check `progress.txt` if something goes wrong.** It will tell you exactly what Ralph tried and why it stopped.
- **Re-run after failures.** If Ralph hits max iterations without finishing, just run it again — it picks up where it left off.
