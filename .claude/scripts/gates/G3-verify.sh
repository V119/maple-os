#!/usr/bin/env bash
set -euo pipefail

# G3: TDD compliance gate
PLAN_FILE=".claude/scale/plan.md"
EXEMPT_FILE=".claude/scale/tdd-exempt.md"

if [ -f "$EXEMPT_FILE" ]; then
  echo "[PASS] G3: TDD exemption recorded in $EXEMPT_FILE"
  exit 0
fi

# Find test files matching Rust and TypeScript patterns
TEST_FILES=$(find . -type f \( \
  -name '*_test.rs' \
  -o -path '*/tests/*.rs' \
  -o -name '*.test.ts' \
  -o -name '*.test.tsx' \
  -o -name '*.spec.ts' \
  \) ! -path '*/node_modules/*' \
    ! -path '*/.agent/*' \
    ! -path '*/.git/*' \
    ! -path '*/target/*' \
  2>/dev/null | head -5)

if [ -z "$TEST_FILES" ]; then
  echo "[FAIL] G3: No test files found matching project patterns"
  echo "  If TDD is not applicable, create .claude/scale/tdd-exempt.md with justification"
  exit 1
fi

if [ -f "$PLAN_FILE" ]; then
  PLAN_TIME=$(stat -f %m "$PLAN_FILE" 2>/dev/null || stat -c %Y "$PLAN_FILE" 2>/dev/null || echo 0)
  NEWER_TESTS=$(find . -type f \( \
    -name '*_test.rs' \
    -o -path '*/tests/*.rs' \
    -o -name '*.test.ts' \
    -o -name '*.test.tsx' \
    -o -name '*.spec.ts' \
    \) ! -path '*/node_modules/*' \
      ! -path '*/.agent/*' \
      ! -path '*/target/*' \
      -newer "$PLAN_FILE" 2>/dev/null | head -1)

  if [ -n "$NEWER_TESTS" ]; then
    echo "[PASS] G3: TDD evidence found — test files newer than plan.md"
    echo "  Test file: $NEWER_TESTS"
    exit 0
  fi
fi

echo "[PASS] G3: Test files exist — TDD evidence found"
echo "  Files: $(echo "$TEST_FILES" | head -3)"
exit 0
