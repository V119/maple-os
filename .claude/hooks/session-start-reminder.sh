#!/usr/bin/env bash
# .claude/hooks/session-start-reminder.sh
# P1 Hook: 会话开始提醒

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  认知工作流提醒                                            ║"
echo "║  ────────────────────────────────────────────────────────║"
echo "║  1. 请先扫描已安装技能清单                                 ║"
echo "║  2. 确认本次任务级别 (S/M/L/CRITICAL)                     ║"
echo "║  3. M/L级任务需执行完整5阶段流程                           ║"
echo "║  验证: cargo clippy + cargo test + pnpm typecheck       ║"
echo "║  输出: [SKILL SCAN] ✓ | [EXPLORE] ✓ | [PLAN] ✓ | ...     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

exit 0
