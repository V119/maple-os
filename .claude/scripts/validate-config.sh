#!/usr/bin/env bash
set -euo pipefail

failures=0
warnings=0

echo "=== MapleOS SCALE Configuration Validator ==="
echo ""

# 1. Check required files
echo "[CHECK] File existence..."
required=(".claude/agent/project.json" ".claude/agent/report.json" ".claude/scale/workflow.json" ".claude/scale/quality-contract.json" ".claude/scale/skills-registry.json")

for file in "${required[@]}"; do
  if [ ! -f "$file" ]; then
    echo "[FAIL] missing $file"
    failures=$((failures + 1))
  else
    echo "[OK] $file exists"
  fi
done

optional_files=("CLAUDE.md" ".claude/scripts/gates/all.sh" ".claude/scripts/workflow/verify.sh" ".claude/scripts/tests/run.sh")
for file in "${optional_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "[WARN] missing optional $file"
    warnings=$((warnings + 1))
  fi
done

echo ""

# 2. Validate JSON syntax
echo "[CHECK] JSON validity..."
for file in .claude/agent/project.json .claude/agent/report.json .claude/scale/workflow.json .claude/scale/quality-contract.json .claude/scale/skills-registry.json; do
  if [ -f "$file" ]; then
    if node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" "$file" 2>/dev/null; then
      echo "[OK] $file is valid JSON"
    else
      echo "[FAIL] $file has invalid JSON syntax"
      failures=$((failures + 1))
    fi
  fi
done

echo ""

# 3. Stack consistency check
echo "[CHECK] Stack consistency..."
if [ -f ".claude/agent/project.json" ]; then
  STACK=$(node -e "const d=JSON.parse(require('fs').readFileSync('.claude/agent/project.json','utf8')); console.log(d.stack||'unknown')" 2>/dev/null || echo "unknown")
  DEV_CMD=$(node -e "const d=JSON.parse(require('fs').readFileSync('.claude/agent/project.json','utf8')); console.log(d.commands?.dev||'')" 2>/dev/null || echo "")

  if [ "$STACK" = "go" ] && echo "$DEV_CMD" | grep -qi "python\|uvicorn\|pytest"; then
    echo "[FAIL] Stack is 'go' but dev command uses Python: $DEV_CMD"
    failures=$((failures + 1))
  elif [ "$STACK" = "python" ] && echo "$DEV_CMD" | grep -qi "pnpm\|npm\|node"; then
    echo "[FAIL] Stack is 'python' but dev command uses Node: $DEV_CMD"
    failures=$((failures + 1))
  elif [ "$STACK" = "rust" ] && echo "$DEV_CMD" | grep -qi "python\|uvicorn"; then
    echo "[FAIL] Stack is 'rust' but dev command uses Python: $DEV_CMD"
    failures=$((failures + 1))
  elif [ "$STACK" = "java" ] && echo "$DEV_CMD" | grep -qi "pnpm\|npm\|cargo\|go run"; then
    echo "[FAIL] Stack is 'java' but dev command uses non-Java tools: $DEV_CMD"
    failures=$((failures + 1))
  else
    echo "[OK] Stack '$STACK' is consistent with dev command"
  fi

  LINT_CMD=$(node -e "const d=JSON.parse(require('fs').readFileSync('.claude/agent/project.json','utf8')); console.log(d.commands?.lint||'')" 2>/dev/null || echo "")
  if [ -n "$LINT_CMD" ] && [ "$LINT_CMD" != "echo"* ]; then
    echo "[OK] Lint command configured: $LINT_CMD"
  fi
fi

echo ""

# 4. Summary
echo "=== Validation Summary ==="
if [ "$failures" -gt 0 ]; then
  echo "[FAIL] $failures failure(s), $warnings warning(s)"
  exit 1
fi

echo "[OK] Configuration valid ($warnings warning(s))"
