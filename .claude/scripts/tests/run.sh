#!/usr/bin/env bash
set -euo pipefail

failures=0
for file in .claude/agent/project.json .claude/agent/report.json .claude/scale/workflow.json .claude/scale/quality-contract.json .claude/scale/skills-registry.json; do
  node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" "$file" || failures=$((failures + 1))
done

if [ ! -x .claude/scripts/validate-config.sh ] || [ ! -x .claude/scripts/gates/all.sh ] || [ ! -x .claude/scripts/workflow/verify.sh ]; then
  echo "[FAIL] expected generated scripts to be executable"
  failures=$((failures + 1))
fi

echo "$failures 失败"
[ "$failures" -eq 0 ]
