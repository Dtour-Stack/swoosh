# Swoosh Gaming Harness — Build Plan (agent play / create / test + esports + training)

> Status: **designed, not built.** Decisions locked 2026-05-29; build as a fresh, focused effort (this plan was designed at the tail of a large session — the architecture is ready, the code should be born clean). Out of scope for the design: shipping a trained model — this is the harness/runtime scaffold.

## Vision
Point Swoosh's existing agent runtime at **game environments**. A "game" is just an environment an agent observes and acts on. Three modes, one spine:
- **Play** — a loaded model (a `Policy`) runs the agent loop against an env.
- **Create** — a generation task (existing code/file/`swiftDev` tools + `SwooshImageGen`/`SwooshGenerativeUI`/3D) whose output is a new env.
- **Test** — Play + a test-oracle where the reward signal is "bug / imbalance / exploit found."
- **Esports** — matches as replayable `SwooshFlow` workflows; tournaments = brackets + ELO.
- **Training** — collect `(obs, action, reward)` trajectories from Play, then imitation/LoRA/RL.

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

**`gaming` ToolsetID + tools (SwooshToolsets):** add `case gaming` to `ToolsetID` (Tool.swift). `GamingToolDependencies` struct + typed tools: `game.list_envs`, `game.reset`, `game.observe`, `game.act`, `game.reward`. Register via a `registerGaming` hook in `Exports.swift`. Tools are firewall-gated + typed (`Codable & Sendable` I/O via `TypeErasedTool`).

**Permissions (SwooshPermission.swift):** new cases `gameObserve`, `gameAct`, `gameTrain` (follow the `add-permission-case` checklist: enum + profile grants + docs + tests).

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
