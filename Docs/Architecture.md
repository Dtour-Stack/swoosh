# Swoosh Architecture

## Process model

```
Swoosh.app ──┐
swoosh CLI ──┤── Keychain (secrets)
swooshd ─────┴── actantdb serve (subprocess)
                 └─ event ledger / replay / approvals / memories / setup reports
                    at ~/.swoosh/actant.db
```

**All durable state** — sessions, tool calls, response-audit records, memory
candidates, approved memories, setup reports, permissions, game sessions,
trajectories, and generated artifacts —
routes through **ActantDB**, the event-sourced backend with hash-chained
events, replay, and Studio. `swooshd` spawns `actantdb serve --db
~/.swoosh/actant.db --bind 127.0.0.1:<port>` as a child process via
`ActantAgent.ActantDBSupervisor` and exports the listening URL as
`ACTANT_BASE_URL`. `SwooshKit.configure` picks up that env var to build
default loaders/stores/auditors through `SwooshActantBackend`'s conformance
extensions over `ActantAgent.MemoryStore` / `ApprovalCenter` /
`Session<ChatMessage>` / `Auditor<ResponseAuditRecord>`.

The SQLite `SwooshStorage` target and the SpacetimeDB spike were both
retired in favor of this stack.

## Module Map

```
SwooshKit             SDK entry point, re-exports
SwooshCore            AgentKernel actor, agent loop
SwooshConfig          Setup graph, credentials, hardware, permissions, doctor
SwooshFirewall        Permission model, approval engine, audit log
SwooshTools           Tool protocol, registry, types
SwooshFoundation      Apple Foundation Models adapter
SwooshActantBackend   ActantAgent ↔ SwooshCore conformance shim (<100 LoC)
SwooshGenerativeUI    Agent-emitted UI (A2UI-shaped: typed UIComponent enum,
                      UISurfaceUpdate wire format, ComponentCatalog gate,
                      UIRenderer SwiftUI walker, sentinel envelope for tools)
SwooshUI              Dashboard, menu bar, toolbar, theme editor, drag-drop,
                      Inspector, Tips, Spatial (RealityView orb / Model3D),
                      Spotlight indexer, FocusFilter, Live Activities,
                      WritingTools + Image Playground hooks, generative
                      surface host
SwooshCLI             ArgumentParser commands
SwooshDaemon          in-process runtime host
SwooshArena           Cartridge game harness, integrations, pipelines
```

## Storage layout

```
~/.swoosh/
├── actant.db             ActantDB ledger (event-sourced)
├── config.json           non-secret config
├── theme.json            UI theme
├── logs/                 daemon/agent logs (incl. actantdb.log)
├── artifacts/            generated files
└── models/               downloaded MLX models
```

Keychain services:

- `ai.swoosh.agent` for setup/runtime credentials managed by `SwooshConfig`.
- `ai.swoosh.secrets` for provider secrets managed by `SwooshSecrets.KeychainSecretStore`.

## Cartridge game harness pipeline

```
Local URL / starter request
  → Cartridge session
  → provider policy (NitroGen, LLM, hybrid, or scripted)
  → observations + actions
  → generated content artifacts
  → pipeline graph import/export
  → evaluation report
  → replayable audit trace
```

## Model Path

```
Local summarizer:  Apple Foundation Models (free, on-device)
Remote reasoner:   OpenAI-compatible provider via Keychain API key
```

## CLI Commands

```
swoosh setup quick       full onboarding flow
swoosh doctor            system diagnostics
swoosh game cli list     list Cartridge CLI starters
swoosh game cli init     generate a game/agent/character/laptop CLI starter
swoosh provider list     list model providers
swoosh terminal backends list terminal execution backends
swoosh plugin list       list game harness plugins
```

## Backend schema

The canonical schema lives in ActantDB (`actantDB/migrations/0001_initial.sql`,
~80 tables). Swoosh consumes the following slice via the `ActantDB` and
`ActantAgent` Swift SDKs:

```
memory               approved memories
memory_candidate     pending/rejected proposals
memory_conflict      detected conflicts
authority_scope      granted permissions
artifact             setup_report and generated-artifact rows
agent_event          session messages + audit sentinels
tool_call            tool dispatch + approval requests
```

Swoosh never speaks SQL directly; all access goes through `ActantClient` /
`ActantAgent` over HTTP.
