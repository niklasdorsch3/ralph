#!/bin/bash
# convert-prd.sh - Convert any PRD to ralph's prd.json format
# Usage: ./convert-prd.sh <prd-file>
# Example: ./convert-prd.sh my-feature-prd.md

if [ $# -eq 0 ]; then
  echo "Usage: convert-prd.sh <prd-file>"
  echo "Example: convert-prd.sh my-feature-prd.md"
  exit 1
fi

PRD_FILE="$1"

if [ ! -f "$PRD_FILE" ]; then
  echo "Error: File not found: $PRD_FILE"
  exit 1
fi

# Get the directory where this script lives and where the output should go
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_DIR="$(cd "$(dirname "$PRD_FILE")" && pwd)"
OUTPUT_FILE="$PRD_DIR/prd.json"

# Read the PRD and example format
PRD_CONTENT=$(cat "$PRD_FILE")
EXAMPLE_FORMAT=$(cat "$SCRIPT_DIR/prd.json.example")

echo "Converting $PRD_FILE to prd.json..."
echo "Output: $OUTPUT_FILE"
echo ""

# Call Claude with the covert_to_prd skill, passing both the PRD and example
OUTPUT=$(claude --permission-mode acceptEdits --model sonnet \
  --print "Convert this PRD to ralph's prd.json format.

## PRD to Convert:
$PRD_CONTENT

## Example Output Format:
\`\`\`json
$EXAMPLE_FORMAT
\`\`\`

Follow the rules from the covert_to_prd skill:
- Each user story becomes one JSON entry
- IDs: Sequential (US-001, US-002, etc.)
- Priority: Based on dependency order, then document order
- All stories: passes: false and empty notes
- branchName: Kebab-case, prefixed with 'ralph/'
- Always add 'Typecheck passes' to every story's acceptance criteria
- For UI stories, add 'Verify in browser using dev-browser skill'
- Keep stories small (completable in one iteration)
- Order by dependencies (schema → backend → UI)

Output ONLY the valid JSON in a code block, nothing else." 2>&1)

# Extract JSON from the output (between ```json and ```)
JSON=$(echo "$OUTPUT" | sed -n '/```json/,/```/p' | sed '1d;$d')

if [ -z "$JSON" ]; then
  echo "Error: Failed to extract JSON from Claude output"
  echo "Output: $OUTPUT"
  exit 1
fi

# Save to prd.json in the original directory
echo "$JSON" > "$OUTPUT_FILE"
echo "✓ Conversion complete: $OUTPUT_FILE"
