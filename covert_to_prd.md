---
name: ralph
description: "Generate prd.json from individual markdown user story files. Use when you have story files already written and want to create or update Ralph's prd.json. Triggers on: generate prd.json, create ralph prd, convert my stories to ralph format, run ralph setup."
user-invocable: true
---

# Ralph PRD Generator

Generates `prd.json` from individual markdown user story files already written in this project.

---

## The Job

1. Find the markdown user story files in this project (look in `docs/`, `docs/.scratch/`, or wherever `AGENTS.md` points you)
2. Check if `prd.json` already exists (at project root or in `docs/`)
3. If `prd.json` exists, read it and identify which story files are already tracked (by their `doc` field) — **do not recreate or overwrite those entries**
4. For any story markdown file that is NOT yet in `prd.json`, add a new entry with a `doc` field pointing to that file
5. If `prd.json` does not exist at all, generate it fresh from all found story files
6. Follow all the rules below

Ralph will read those markdown files at runtime for the full acceptance criteria. Keep story entries in `prd.json` lean — the detail lives in the markdown.

**Never remove or modify existing entries**, especially ones where `passes: true`. Only append missing stories.

---

## Output Format

```json
{
  "project": "[Project Name]",
  "branchName": "ralph/[feature-name-kebab-case]",
  "description": "[Brief feature description]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "doc": "docs/stories/us-001-story-title.md",
      "acceptanceCriteria": [
        "See doc file for full criteria",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

The `doc` field is the relative path from the project root to the markdown file. Ralph will read it each iteration to get the full acceptance criteria and implementation notes.

---

## Story Size: The Number One Rule

**Each story must be completable in ONE Ralph iteration (one context window).**

Ralph spawns a fresh agent instance per iteration with no memory of previous work. If a story is too big, the agent runs out of context before finishing.

### Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

### Too big (ask the user to split before generating):
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

---

## Story Ordering: Dependencies First

Order entries by dependency, not by file name or discovery order.

**Correct order:**
1. Schema/database changes (migrations)
2. Server actions / backend logic
3. UI components that use the backend
4. Dashboard/summary views that aggregate data

---

## Acceptance Criteria in prd.json

Since full criteria live in the `doc` file, the `acceptanceCriteria` array in `prd.json` should be minimal:

```json
"acceptanceCriteria": [
  "See doc file for full criteria",
  "Typecheck passes"
]
```

Always include `"Typecheck passes"`. For UI stories also include `"Verify in browser using dev-browser skill"`.

---

## Conversion Rules

1. **One markdown file = one story entry**
2. **IDs**: Sequential (US-001, US-002, etc.)
3. **Priority**: Based on dependency order
4. **All stories**: `passes: false` and empty `notes`
5. **branchName**: Derive from feature name, kebab-case, prefixed with `ralph/`
6. **doc**: Relative path from project root to the markdown file

---

## Archiving Previous Runs

Only archive when starting a completely different feature (different `branchName`):

1. Read the current `prd.json` if it exists
2. If the new stories belong to the same feature (same branch), **do not archive** — just append missing entries
3. If the new stories belong to a different feature (different `branchName`) AND `progress.txt` has content beyond the header:
   - Create archive folder: `archive/YYYY-MM-DD-feature-name/`
   - Copy current `prd.json` and `progress.txt` to archive
   - Reset `progress.txt` with fresh header
   - Then generate `prd.json` fresh for the new feature

---

## Output Location

Write `prd.json` to `docs/prd.json` if a `docs/` directory exists, otherwise to the project root.

---

## Checklist Before Saving

- [ ] Each story maps to one markdown file with `doc` field set
- [ ] Stories are ordered by dependency (schema → backend → UI)
- [ ] Every story has "Typecheck passes" as criterion
- [ ] UI stories have "Verify in browser using dev-browser skill"
- [ ] No story depends on a later story
- [ ] Previous run archived if branchName changed
