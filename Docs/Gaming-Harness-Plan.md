# Cartridge Game Harness — Implementation Notes (play / create / test / generate)

> Status: **core harness built.** `SwooshArena` now owns the Cartridge domain model and session store, `SwooshToolsets` registers the `gaming` toolset, and `SwooshCloudGaming` can load local game URLs into the WKWebView surface.

## Vision
Point Swoosh's existing agent runtime at **game environments**. A "game" is just an environment an agent observes and acts on. Cartridge supports five modes, one spine:
- **Play** — a loaded model (a `Policy`) runs the agent loop against an env.
- **Create** — a generation task (existing code/file/`swiftDev` tools + `SwooshImageGen`/`SwooshGenerativeUI`/3D) whose output is a new env.
- **Test** — Play + a test-oracle where the reward signal is "bug / imbalance / exploit found."
- **Generate** — produce characters, NPCs, dialogue, items, lore, assets, scripts, and content packs.
- **Esports** — matches as replayable `SwooshFlow` workflows; tournaments = brackets + ELO.
- **Training** — collect `(obs, action, reward)` trajectories from Play, then imitation/LoRA/RL.

## Shipped slice

- `SwooshArena`: `CartridgeDefaults`, local URL policy, launch targets, policies (`nitroGen`, provider LLM, hybrid, scripted), observations, actions, trajectories, content artifacts, pipelines, evaluations, and the `CartridgeHarness` actor.
- `gaming` toolset: `game.list_sessions`, `game.list_integrations`, `game.list_3d_generation_providers`, `game.list_pipeline_templates`, `game.load_local_url`, `game.init_project`, `game.record_observation`, `game.record_action`, `game.generate_content`, `game.save_pipeline`, `game.import_pipeline`, `game.evaluate_session`.
- Permissions: `gameObserve`, `gameLoad`, `gameAct`, `gameGenerate`, `gameEvaluate`; developer profiles can load/observe/generate/evaluate, automation adds active gameplay actions.
- UI: the Gaming pane can load a local `file://`, `localhost`, loopback, or `*.localhost` game URL into `WebGameBridge`.
- Provider flexibility: policies are data descriptors, so a session can be NitroGen-only, provider-LLM-only, hybrid LLM + NitroGen, or scripted.

## June 2026 integration layer

- `GameIntegrationCatalog` defines the first Cartridge integration surface for Three.js, WebGPU, Unity, Unreal Engine, Blender, Roblox, Fortnite UEFN, Minecraft, and Autodesk 3ds Max.
- `Game3DGenerationCatalog` tracks the June 2026 3D asset stack: wired FAL endpoints, cloud providers (Meshy, Tripo, Hyper3D Rodin, Stability), local-hostable/open-source models (TRELLIS.2, Hunyuan3D 2.1, TripoSR), asset libraries (Sketchfab, Poly Haven, Fab, Khronos glTF samples), and mesh-processing services.
- `GameProjectScaffoldFactory` initializes starter game projects and plugin bridges. Three.js and WebGPU emit runnable Vite/TypeScript starters; engine and DCC integrations emit installable bridge skeletons or export scripts.
- `GamePipelineTemplateCatalog` turns the Pipeline-style idea into first-class Cartridge graph templates: web runtime scaffolds, engine plugin bridges, and DCC asset export.
- `GamePipelineImportDocument` imports Pipeline/React Flow workflow exports into Cartridge graphs, preserving source node data and positions for later inspection or round-trip UI work.
- `game.init_project` creates a generated-game session, attaches the scaffold as a content-pack artifact, saves the relevant pipeline templates to the session for replayable testing, and can materialize the scaffold to a local output directory when `fileWrite` is granted.

## Locked decisions (user, 2026-05-29)
1. **Env format: WASM** (deterministic, sandboxed via `WasmPluginExecutor`, replayable — best for training reproducibility + esports fairness).
2. **First build scope: core loop + model training** (trajectory collection + an MLX training loop; **note MLX is inference-only today — training is greenfield**, so phase it: loop first, training second).
3. **Esports topology: single-kernel, multi-seat** (one kernel runs N policies against one env per match).

## ⚠️ Critical design constraint (decide before writing the protocol)
`WasmPluginExecutor.call(manifest:toolName:args:context:)` is **one-shot / stateless** — it runs the module per call and returns. `GameEnvironment.step()` needs state **across** steps. Resolution: **WASM envs must be pure-functional** — full game state passed in `args`, new state returned. This is *ideal* for determinism + perfect replay (every step is a pure function of (state, action)). The alternative (a persistent WASM instance) the current executor does not provide. Design `step(state, action) -> (state, observation, reward, done)` accordingly.

## Architecture

**New module `SwooshArena` (pure, Sendable, iOS-buildable — depends only on Foundation/SwooshTools for JSONValue):**
- `protocol GameEnvironment`: `reset() async throws -> EnvState`, `step(_ state: EnvState, _ action: Action) async throws -> StepResult`, `render(_ state: EnvState) -> Frame?`, `var actionSpace`, `var observationSpace`. (State-in/state-out per the constraint above.)
- `protocol Policy`: `act(_ observation: Observation) async throws -> Action` — implemented by a loaded model (MLX / provider) or a scripted baseline.
- Value types: `EnvState`, `Observation`, `Action`, `StepResult(state, observation, reward: Double, done: Bool, info)`, `ActionSpace`/`ObservationSpace`, `Transition`, `Trajectory`, `EpisodeRecord`.
- `actor PlaySession`: runs Policy × Env for N steps/episodes → collects a `Trajectory`; emits an audit entry per step.
- `Match` (single-kernel multi-seat): N policies vs one env; scoring + ELO.

**macOS-side WASM adapter** (in `SwooshPluginRuntime` or a new `SwooshArenaRuntime` — NOT in `SwooshArena`, to keep it a clean iOS-buildable leaf): `WasmGameEnvironment` wraps `WasmPluginExecutor`, mapping `step()`/`reset()` to pure-functional WASM calls (state JSON in, state JSON out).

**`gaming` ToolsetID + tools (SwooshToolsets):** `case gaming` is registered through `DefaultToolRegistrar.registerGameHarness`. Tools are firewall-gated + typed (`Codable & Sendable` I/O via `TypeErasedTool`).

**Permissions (SwooshPermission.swift):** `gameObserve`, `gameLoad`, `gameAct`, `gameGenerate`, and `gameEvaluate` are documented in `Docs/PermissionModel.md` and covered by config/tool tests.

**Training (phase 2 — greenfield):** a `Trajectory` store + a `Trainer` protocol. Real gradient loop needs MLX training (MLXNN/MLXOptimizers — not yet wired in `SwooshMLX`). Start with behavior-cloning / LoRA on collected trajectories; RL (PPO) later.

**Esports (phase 3):** tournament orchestration via `SwooshFlow` (each match = a replayable workflow instance; bracket = a workflow of workflows). Leaderboard/replay UI in `SwooshUI/Gaming` (Volt Paper).

## Invariants preserved
- **Firewall:** every `game.observe/act` is permission-gated; env plugins run in the existing WASM sandbox (no network, fs-confined).
- **Audit:** every step logged via the existing tool-loop `AuditLog` → replayable matches.
- **Replay:** pure-functional WASM envs are deterministic → exact match replay (esports fairness + training reproducibility) via `SwooshFlow`.
- **Privacy boundary:** game trajectories are agent data, kept separate from the Scout/personal-data privacy spine — they do NOT enter `PromptBuilder` via the memory path.
- **LOC ≤ 400/file; Sendable-clean; macOS 26 / iOS 26.**

## Phased build
1. **Spine + one env (validate the loop):** `SwooshArena` contract + `gaming` ToolsetID + permission cases + `WasmGameEnvironment` adapter + one pure-functional WASM env (e.g. 2048/snake) + `PlaySession` running a scripted baseline `Policy`, with audited steps + a replayable trajectory. Build + `check-flow` + `plumber` PASS.
2. **Models as policies + trajectory collection:** MLX/provider-backed `Policy`; persist trajectories.
3. **Training:** wire MLX training (behavior cloning / LoRA) over trajectories.
4. **Esports:** `Match` multi-seat + `SwooshFlow` tournaments + ELO + leaderboard/replay UI.

Existing assets to reuse: `WasmPluginExecutor` (env runner), `SwooshCloudGaming` (`GamepadBridge`/`WebGameBridge`/`NativeGameBridge` for non-WASM env adapters later), `SwooshMLX`/providers (policies), `SwooshFlow` (match replay/orchestration), `SwooshUI/Gaming` (surfaces), firewall/audit/replay spine.
