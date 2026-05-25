# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Rust (cargo workspace)
cargo check --all-targets          # Type-check all Rust code
cargo build -p mapleos-server      # Build the server binary
cargo run -p mapleos-server        # Run the server
cargo test --all-targets           # Run all Rust tests
cargo test -p <crate>              # Run tests for a specific crate
cargo clippy --all-targets -- -D warnings

# Frontend (pnpm + turbo)
pnpm install                       # Install all frontend deps
pnpm dev                           # Run all frontend dev servers (turbo)
pnpm --filter=mapleos-web dev      # Run just the Next.js web app
pnpm build                         # Build all frontend packages
pnpm lint                          # Lint all frontend packages
pnpm typecheck                     # TypeScript type-check (tsc --noEmit per package)

# E2E tests
pnpm test:e2e                      # Playwright tests (requires web app on localhost:3000)
pnpm test:e2e:ui                   # Playwright in UI mode

# Docker
docker compose -f infra/docker/docker-compose.yml up    # Full stack
docker build -f infra/docker/Dockerfile -t mapleos-server .
```

## Architecture

MapleOS is an AI-native multi-agent collaboration workstation. The backend is a Rust workspace (`edition = "2024"`, Rust 1.95+), the frontend is a Next.js 15 app (React 19, Tailwind CSS), and there is a Tauri 2 desktop client.

### Crate dependency hierarchy

The Rust workspace has 9 crates in a layered architecture. Each layer depends on the layer below it — there are no circular dependencies.

```
                  ┌─────────────┐
                  │ mapleos-    │  Binary: starts Axum HTTP server, wires all
                  │ server      │  services together in AppState
                  └──────┬──────┘
                         │ depends on everything below
                  ┌──────┴──────┐
                  │ maple-rpc   │  JSON-RPC 2.0 API layer (the primary API surface)
                  └──────┬──────┘
          ┌──────────────┼──────────────┐
          │              │              │
    ┌─────┴─────┐  ┌─────┴─────┐  ┌─────┴─────┐
    │ maple-    │  │ maple-    │  │ maple-    │  Async WS/SSE gateway for
    │ gateway   │  │ collab    │  │ sync      │  agent connections, auth, CRDT sync
    └─────┬─────┘  └─────┬─────┘  └─────┬─────┘
          │              │              │
    ┌─────┴─────┐  ┌─────┴─────┐        │
    │ maple-    │  │ maple-kb  │        │
    │ agent     │  └─────┬─────┘        │
    └─────┬─────┘        │              │
          │              │              │
    ┌─────┴──────────────┴──────────────┘
    │            maple-engine            │  Workflow DAG, task queue, scheduler,
    └─────────────┬─────────────────────┘  event bus, hooks, skill registry
                  │
    ┌─────────────┴─────────────────────┐
    │            maple-llm              │  LLM routing, adapters (Ollama, OpenAI),
    └───────────────────────────────────┘  embeddings, usage tracking
```

**maple-llm** — Lowest-level crate. LLM routing based on cost/latency/privacy/complexity. Adapters for Ollama and cloud providers. Usage tracking and embedding generation.

**maple-engine** — Workflow execution engine: DAG-based workflows (petgraph), task queue with priorities/retries, cron scheduler, event bus, hook pipeline, skill registry, and checkpoint management for workflow state recovery.

**maple-agent** — Agent lifecycle: agent registry, ReAct loop implementation (think → tool-call → observe → repeat), session store, tool executor. Depends on maple-engine and maple-llm.

**maple-kb** — Knowledge base: document indexing, BM25 text search, vector store (in-memory or Qdrant via `qdrant` feature flag), hybrid retrieval (BM25 + vector), memory store (working/episodic/semantic), prompt version manager.

**maple-gateway** — Agent access gateway: WebSocket and SSE transports, token/auth verification, stream management.

**maple-sync** — Local-first sync via Automerge CRDTs. Handles offline writes and automatic conflict resolution. WebDAV support.

**maple-collab** — Multi-agent collaboration: workspace management, member roles, message routing between agents/humans.

**maple-rpc** — JSON-RPC 2.0 server and dispatcher. Routes `method` strings to handler functions. Depends on all other crates to expose their functionality via a unified API.

**mapleos-server** — The binary. Creates an Axum HTTP server on port 7790. Initializes a SQLite database (via sqlx), builds all services into `AppState`, starts the scheduler and sync engine, and mounts REST/SSE/WS routes.

### Database

SQLite via `sqlx` (compile-time checked queries). The schema is in `migrations/001_init.sql`. Key tables: `workflows`, `workflow_executions`, `agents`, `kb_documents`, `kb_chunks`, `task_queue`, `chat_messages`, `memories`, `workspaces`.

### Frontend monorepo

- **apps/web** — Next.js 15 App Router, React 19, Tailwind CSS 3, Zustand for state. Consumes `@mapleos/sdk` and `@mapleos/ui`.
- **apps/desktop** — Tauri 2 desktop app wrapping the web frontend with native capabilities.
- **packages/ui** — shadcn/ui React components shared across apps.
- **packages/sdk** — TypeScript SDK for JSON-RPC communication with the Rust backend.
- **packages/config** — Shared config (ESLint, TypeScript).

### SCALE Engine (git submodule)

`core/scale-engine/` is a git submodule containing a Node.js governance engine (Spec/Plan/Task/Defect lifecycle with FSM state machines). It runs as a separate process on port 7790 via `node bridge-http.mjs`.

### E2E tests

Playwright tests in `tests/e2e/` mock the API layer at the HTTP level (using `page.route`). They test the web app against mocked JSON-RPC responses. The fixture in `tests/e2e/fixtures.ts` sets up common API mocks.

### Commit conventions

```
feat: new feature
fix: bug fix
refactor: refactoring
docs: documentation
chore: build/CI/dependencies
```

Git branches: `main` (production), `feat/*`, `fix/*`.
