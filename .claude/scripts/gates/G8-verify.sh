#!/usr/bin/env bash
set -euo pipefail

# G8: No-AI-slop gate
SLOP_PATTERNS=0

echo "[CHECK] G8: Scanning for AI-generated code quality issues..."

# Check for AI conversation remnants in comments
AI_REMNANTS=$(grep -rn --include='*.ts' --include='*.tsx' --include='*.rs' --include='*.py' \
  -iE "(//|#) (i'll|let me|now let's|i will|i can|here's)" \
  . 2>/dev/null | grep -v 'node_modules' | grep -v '.agent/' | grep -v 'target/' | head -5 || true)

if [ -n "$AI_REMNANTS" ]; then
  echo "[WARN] G8: Found AI conversation remnants in comments:"
  echo "$AI_REMNANTS"
  SLOP_PATTERNS=$((SLOP_PATTERNS + 1))
fi

# Check for empty TODO comments
EMPTY_TODOS=$(grep -rn --include='*.ts' --include='*.tsx' --include='*.rs' \
  -E '(//|#) TODO:?\s*$' \
  . 2>/dev/null | grep -v 'node_modules' | grep -v '.agent/' | grep -v 'target/' | head -5 || true)

if [ -n "$EMPTY_TODOS" ]; then
  echo "[WARN] G8: Found empty TODO comments without descriptions:"
  echo "$EMPTY_TODOS"
  SLOP_PATTERNS=$((SLOP_PATTERNS + 1))
fi

if [ "$SLOP_PATTERNS" -gt 2 ]; then
  echo "[FAIL] G8: Too many AI-slop patterns detected"
  exit 1
fi

echo "[PASS] G8: No-AI-slop check passed (warnings: $SLOP_PATTERNS)"
exit 0
