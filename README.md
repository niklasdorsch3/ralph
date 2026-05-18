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

### 2. Run Ralph

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

## PRD Format

Ralph expects `prd.json` in this structure:

```json
{
  "project": "Project Name",
  "branchName": "ralph/feature-name",
  "description": "Feature description",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "description": "As a user, I want...",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

See `prd.json.example` for a complete example.

## Conversion Rules

When converting a PRD to ralph format:

- **Story Size**: Each story must be completable in one iteration (one LLM context window)
- **Dependencies First**: Order stories by dependency (schema → backend → UI)
- **Verifiable Criteria**: Acceptance criteria must be checkable, not vague
- **Always Include**: "Typecheck passes" in every story's criteria
- **UI Stories**: Add "Verify in browser using dev-browser skill" to frontend changes

For detailed conversion guidance, see `covert_to_prd.md`.

## Files & Structure

- **`ralph.sh`** — Main agent loop script
- **`convert-prd.sh`** — Convert any PRD to ralph format
- **`prompt.md`** — Instructions given to the AI agent
- **`prd.json.example`** — Example PRD structure
- **`covert_to_prd.md`** — Detailed conversion rules (Claude Code skill)

## Outputs

After running ralph:

- **`prd.json`** — Updated with `passes: true` for completed stories
- **`progress.txt`** — Detailed log of each iteration
- **`archive/`** — Previous run results (auto-archived when branch changes)
- **`.last-branch`** — Tracks which branch was last executed

## Understanding Progress

Check `progress.txt` after each run. It includes:

- What each story implemented
- Which files changed
- Learnings for future iterations (patterns, gotchas, context)

Ralph also consolidates codebase patterns at the top of `progress.txt` so future iterations understand the project's conventions.

## Tips

1. **Keep stories small** — If a story takes >1 context window, it will fail. Split big features into smaller stories.
2. **Order by dependency** — Schema changes must come before UI that uses them.
3. **Test as you go** — Each story runs quality checks. Fix broken stories immediately.
4. **Archive between features** — Ralph auto-archives old runs when you switch branches.
5. **Check learnings** — Review `progress.txt` learnings before running the next feature.

## Troubleshooting

**Ralph exceeded max iterations without completing:**
- Check `progress.txt` for which story failed
- Verify acceptance criteria are achievable
- Split oversized stories into smaller ones

**Commit hooks failing:**
- Ralph respects your project's hooks (typecheck, lint, test)
- Fix the underlying issue rather than bypassing hooks

**Branch mismatch:**
- Ralph auto-archives old runs if `branchName` changes
- Check `archive/` for previous run files
