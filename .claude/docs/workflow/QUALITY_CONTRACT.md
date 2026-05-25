# SCALE Quality Contract

- Project: MapleOS
- Agent: claude-code
- Stack: Rust + TypeScript
- Scenario: standard

## Source Of Truth
- agentEntry: `CLAUDE.md`
- workflowState: `.scale/workflow.json`
- runtimeCommands: `.agent/project.json`
- qualityContract: `.scale/quality-contract.json`
- skillRegistry: `.scale/skills-registry.json`

## Task Levels
| Level | Intent | Required Artifacts | Required Verification |
| --- | --- | --- | --- |
| S | 单点小改、文案、注释、低风险配置。 | final response evidence | cargo check (affected crate) |
| M | 普通功能、bugfix、2-5 个文件的行为变化。 | explore.md, plan.md, verification.md, summary.md | cargo clippy, cargo test, pnpm typecheck |
| L | 跨模块、架构、数据模型、迁移或高影响重构。 | mini-prd.md when user-facing, explore.md, plan.md, review.md, verification.md, summary.md | cargo build, cargo clippy, cargo test, pnpm build, pnpm lint, pnpm typecheck |
| CRITICAL | 认证、权限、数据库schema、迁移、外部集成。 | mini-prd.md, rollback-plan, security-review, verification.md, summary.md | cargo build, cargo clippy, cargo test, pnpm build, pnpm lint, pnpm typecheck, cargo audit |

## Verification Profiles
| Profile | Required | Optional | Success Rule |
| --- | --- | --- | --- |
| fast | cargo test --all-targets | cargo clippy | 只用于 S 级或局部验证，不能代表发布可用。 |
| default | cargo clippy, cargo test, pnpm typecheck | cargo build, pnpm build | M 级默认闭环，失败必须记录原因和修复循环。 |
| release | cargo build, cargo clippy, cargo test, pnpm build, pnpm lint, pnpm typecheck | coverage profile, security profile, e2e profile | 发版前必须全部真实运行并在 verification.md 记录退出码。 |

## Skill Policy
- Mode: progressive-disclosure
- Max always-visible skills: 24
- Install safety: 只从可信仓库或已审查来源安装。
- Install safety: 安装前检查脚本、二进制、网络下载、postinstall、权限和 license。
- Install safety: 优先固定版本或 commit；禁止无审查执行 curl | bash。
- Usage evidence: 说明为什么选这些 skills、MCP 或 CLI。
- Usage evidence: 记录实际调用的工具和输出证据。
- Usage evidence: 技能失败时记录失败原因和降级方案。

## Resource Governance
| Kind | Git Policy | Retention | Update Trigger | Examples |
| --- | --- | --- | --- | --- |
| canonical-docs | commit | long-lived | 架构、模块关系、规范、命令或用户路径变化时更新。 | README.md, CLAUDE.md, docs/architecture/**, docs/standards/** |
| task-artifacts | commit-summary-only | task-lifetime | M/L/CRITICAL 任务执行和交付时维护，完成后保留 summary 与关键证据。 | docs/worklog/tasks/<task>/*.md |
| generated-evidence | ignore-by-default | evidence-window | 只在审计、回归复现或发布证据需要时保留。 | screenshots, videos, trace logs, e2e reports |
| temporary-work-files | ignore-by-default | short-lived | 任务结束前清理或沉淀为正式脚本/文档。 | tmp/**, .agent/logs/**, one-off scripts |
| large-media-assets | external-store | long-lived | 通过外部资产库管理，git 中只保留索引、用途和版本。 | design videos, audio, large datasets |

## Red Lines
- 不得声称未运行的验证通过。
- 不得把临时日志、截图、视频、抓包和一次性脚本默认提交到 git。
- 不得在日志、文档、测试报告中输出 token、密码、手机号、身份证、密钥和连接串。
- 不得绕过项目的 ORM、框架、日志、错误处理、安全和 UI 规范。
