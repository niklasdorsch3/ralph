# Ralph - Autonomous AI Agent Loop

Ralph is an autonomous AI agent that executes your PRD (Product Requirements Document) story-by-story, implementing each one until all are complete.

## Quick Start

### 1. Convert Your PRD

If you have an existing PRD, convert it to ralph format:

```bash
cd /path/to/your/project
/path/to/ralph/convert-prd.sh /path/to/your/prd.md
```

This creates `prd.json` in your project root.

Alternatively, manually create `prd.json` using the structure in `prd.json.example`.

### 2. (optional) Add Project Instructions (Optional)

Create a `ralph.md` file in your project root with any specific instructions Ralph should follow:


### 3. Run Ralph

```bash
cd /path/to/your/project
/path/to/ralph/ralph.sh [--tool amp|claude] [max_iterations]
```

**Options:**
- `--tool amp` — Use Amp (default)
- `--tool claude` — Use Claude Code (with Sonnet model)
- `max_iterations` — Max loops (default: 10)

**Examples:**
```bash
./ralph.sh                        # Run with amp, max 10 iterations
./ralph.sh --tool claude 20       # Run with claude, max 20 iterations
./ralph.sh 5                      # Run with amp, max 5 iterations
```

Ralph will:
1. Read your `prd.json`
2. Pick the highest-priority incomplete story (`passes: false`)
3. Implement it
4. Run quality checks (typecheck, lint, test)
5. Commit changes if all checks pass
6. Update the PRD status
7. Log progress to `progress.txt`
8. Loop until all stories are complete or max iterations reached


## Understanding Progress

Check `progress.txt` after each run. It includes:

- What each story implemented
- Which files changed
- Learnings for future iterations (patterns, gotchas, context)

Ralph also consolidates codebase patterns at the top of `progress.txt` so future iterations understand the project's conventions.


