#!/usr/bin/env bash
# .claude/hooks/session-end-gate.sh
# P0 Hook: 会话结束门控

STATE_FILE=".claude/session/.flow-state"
VERIFY_MARKER=".claude/session/.verified"
POLLUTION_MARKER=".claude/session/.pollution-detected"

# 检查污染标记
if [[ -f "$POLLUTION_MARKER" ]] && grep -q "POLLUTION=1" "$POLLUTION_MARKER"; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  [GATE BLOCK] 上下文污染未清理                            ║"
    echo "║  必须执行 /clear 或输出 [POLLUTION CLEARED]               ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    exit 2
fi

# 检查验证标记
if [[ ! -f "$VERIFY_MARKER" ]]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  [GATE BLOCK] 验证未完成                                  ║"
    echo "║  必须执行验证并输出 [VERIFY] ✓ 检查项 ✓ | ...              ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    exit 2
fi

# 检查状态文件
if [[ -f "$STATE_FILE" ]]; then
    PHASES="SKILL_SCAN EXPLORE PLAN EXECUTE VERIFY SETTLE"
    MISSING=""
    for phase in $PHASES; do
        if ! grep -q "${phase}=✓" "$STATE_FILE"; then
            MISSING="$MISSING $phase"
        fi
    done
    if [[ -n "$MISSING" ]]; then
        echo ""
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║  [GATE BLOCK] 认知工作流未完成 — 缺失:$MISSING            ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        exit 2
    fi
fi

# 所有检查通过
echo "[GATE PASS] 认知工作流验证通过"

# 清理状态文件
rm -f "$STATE_FILE" ".claude/session/.tool-history" ".claude/session/.lazy-detected" ".claude/session/.fail-count" "$POLLUTION_MARKER" "$VERIFY_MARKER" ".claude/session/.skill-scanned"

exit 0
