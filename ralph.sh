#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop
# Usage: ./ralph.sh [--tool amp|claude|pi] [max_iterations]

set -e

# Parse arguments
TOOL="claude"  # Default tool
MAX_ITERATIONS=10

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    *)
      # Assume it's max_iterations if it's a number
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

# Validate tool choice
if [[ "$TOOL" != "amp" && "$TOOL" != "claude" && "$TOOL" != "pi" ]]; then
  echo "Error: Invalid tool '$TOOL'. Must be 'amp', 'claude', or 'pi'."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$PWD"
ARCHIVE_DIR="$PROJECT_DIR/archive"
LAST_BRANCH_FILE="$PROJECT_DIR/.last-branch"

# Step 1: Generate prd.json from markdown story files
echo "Generating prd.json from story files..."
echo ""
if [[ "$TOOL" == "amp" ]]; then
  cat "$SCRIPT_DIR/covert_to_prd.md" | amp --dangerously-allow-all 2>&1 || { echo "Error: Failed to generate prd.json"; exit 1; }
elif [[ "$TOOL" == "claude" ]]; then
  claude --permission-mode acceptEdits --model sonnet --print < "$SCRIPT_DIR/covert_to_prd.md" 2>&1 || { echo "Error: Failed to generate prd.json"; exit 1; }
else
  pi --print < "$SCRIPT_DIR/covert_to_prd.md" 2>&1 || { echo "Error: Failed to generate prd.json"; exit 1; }
fi

# Auto-discover prd.json after generation: check project root, then docs/
if [ -f "$PROJECT_DIR/prd.json" ]; then
  PRD_FILE="$PROJECT_DIR/prd.json"
elif [ -f "$PROJECT_DIR/docs/prd.json" ]; then
  PRD_FILE="$PROJECT_DIR/docs/prd.json"
else
  echo "Error: prd.json was not created. Check your story files."
  exit 1
fi
PROGRESS_FILE="$(dirname "$PRD_FILE")/progress.txt"

# Step 2: Show the generated prd.json and ask for confirmation
echo ""
echo "Generated $PRD_FILE:"
echo "---"
cat "$PRD_FILE"
echo ""
echo "---"
echo ""
read -r -p "Can you confirm the structure about to run Ralph continuously? Make sure everything looks good? (yes/no): " CONFIRM
echo ""

if [[ "$CONFIRM" != "yes" && "$CONFIRM" != "y" ]]; then
  echo "Aborted."
  exit 0
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

echo "Starting Ralph — Tool: $TOOL — Max iterations: $MAX_ITERATIONS"

# Gather recent git context once before the loop
RECENT_COMMITS=$(git log -n 5 --format="%H%n%ad%n%B--" --date=short 2>/dev/null || echo "No commits found")

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "==============================================================="
  echo "  Ralph Iteration $i of $MAX_ITERATIONS ($TOOL)"
  echo "==============================================================="

  # Build prompt with recent commit context prepended
  FULL_PROMPT="## Recent Commits

$RECENT_COMMITS

$(cat "$SCRIPT_DIR/prompt.md")"

  # Run the selected tool with the ralph prompt
  if [[ "$TOOL" == "amp" ]]; then
    OUTPUT=$(echo "$FULL_PROMPT" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
  elif [[ "$TOOL" == "claude" ]]; then
    # Claude Code: bypassPermissions for autonomous operation in sandboxed environments (Codespaces)
    OUTPUT=$(echo "$FULL_PROMPT" | claude --permission-mode bypassPermissions \
      --tools default \
      --model sonnet --print 2>&1 | tee /dev/stderr) || true
  else
    # Pi: non-interactive mode with all built-in tools enabled
    OUTPUT=$(echo "$FULL_PROMPT" | pi --print 2>&1 | tee /dev/stderr) || true
  fi

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Ralph completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
