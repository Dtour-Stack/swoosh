# Swoosh Studio — Umbrella Architecture (Design Spec)

**Status:** Approved umbrella (2026-05-30). Integration contract + build sequence only — each pillar gets its own sub-spec → plan → build.
**Lineage:** Extends the gaming pivot ([Gaming-Harness-Plan.md](Gaming-Harness-Plan.md)) after the launchpad removal (`162517e`) and model-catalog trim (`1759b3f`).
**Decision owner:** user (shawgotbags). Brainstormed via `superpowers:brainstorming`.

---

## 1. Motivation

Refocus Swoosh into a best-in-class **gaming AI system**: an agent that can **generate, edit, play, and create** games — from single 3D assets up to streaming massive worlds and driving existing MMOs. The constraint the user set is the design's spine: **stay a light harness.** Swoosh must not become a heavyweight engine; it orchestrates best-of-breed open-source/remote compute and keeps its existing security/audit guarantees intact.

## 2. The one principle — the light-harness contract

Swift **never does heavy compute.** It orchestrates, holds durable state, and enforces the security spine. Specifically:

- All heavy **generation** (image→3D, text→image/video/music) → a remote `GenBackend`. Never in-process. TRELLIS.2-4B alone needs 24 GB NVIDIA/CUDA/Linux and has no Apple-silicon path — this is the design signal, not a blocker.
- All heavy **render / play** → a web surface (WebGL2 today, WebGPU later) inside `WKWebView`. Never a native 3D engine.
- The **agent** reasons, authors node graphs, and drives play. It never renders, trains, or generates inside the kernel process.

If a proposed feature would put GPU rendering, model training, or diffusion sampling inside the Swift process, it is out of scope by construction.

## 3. Five pillars — and the existing enforcement point each threads

This table **is** the umbrella. What makes Swoosh Studio *Swoosh* and not a generic ComfyUI clone is that every new surface threads the existing security spine rather than inventing a parallel path. For each pillar, the third column is mandatory and already exists as a pattern in the codebase.

| # | Pillar | New surface | Reuses (existing spine) |
|---|--------|-------------|--------------------------|
| 1 | **Gen backends** — TRELLIS img→3D, image, video, music | `GenBackend` protocol + managed-first adapter | `MediaGenDependencies` injection · `SwooshNetworkPolicy` egress gate · `SwooshSecrets`/Keychain for API keys · results returned via `Generate3DTool` → `ToolRegistry.execute` (firewall + audit + approval) |
| 2 | **Play existing games (incl. MMO)** | agent action-loop over a cloud stream | `SwooshCloudGaming` (`WebStreamView` / `InteractiveController` / `GamepadBridge` / `GameStreamAdapter`) — *already built*; the only gap is the agent-drive loop; risky inputs are `humanOnly` + replay traces |
| 3 | **Generate + render AI worlds** | Three.js + **WebGL2 (Spark 2.0)** surface; WebGPU/Visionary upgrade | `WebGameBridge` / `WKWebView`; the JS↔Swift bridge is gated by a `ComponentCatalog`-style allowlist — the exact pattern already used by `SwooshGenerativeUI` |
| 4 | **Node-canvas editor (ComfyUI-style)** | **LiteGraph** in `WKWebView`, graphs as JSON | graphs ↔ `SwooshFlow` workflows; **graph execution routes through `ToolRegistry.execute`** (no parallel execution path); agent-emitted graphs are *proposals* in the review inbox, never auto-run |
| 5 | **AI editing** | image / 3D edit nodes | existing `imageEditing` catalog models + the same gen backends; identical firewall / audit / approval / replay |

### Invariants restated (non-negotiable, from `CLAUDE.md` / `README.md`)

- Every new tool is typed (`SwooshTool`, `Codable & Sendable` I/O).
- Every risky action is permissioned through `SwooshFirewallActor.require`; new permission cases land in `SwooshTools/SwooshPermission.swift` and `Docs/PermissionModel.md`.
- Every agent step is audited; every workflow (and therefore every node-graph run) is replayable through `SwooshFlow`.
- Agent-origin graphs/tools cannot self-approve; `humanOnly` gates anything that spends money, moves funds, or sends destructive input to a live game.
- Generated/edited artifacts are content; they never silently enter prompts.

## 4. New modules vs. reuse

**New:**
- `SwooshGen` — cross-platform schema (`GenBackend` protocol, `GenJob`/`GenAsset` wire types) + macOS/Linux host adapters (`ManagedAPIBackend` first; `SelfHostedBackend` later). Mirrors the `SwooshClient` (schema) / `SwooshKit` (host) split so iOS can describe jobs without importing `Process`-using host code.
- `SwooshStudioWeb` — the bundled local web app served into `WKWebView`: LiteGraph canvas + Three.js/Spark render viewport + the gated JS bridge. Shipped as a resource bundle, offline-capable.

**Reuse (no forks):** `SwooshCloudGaming`, `SwooshFlow`, `SwooshToolsets` (`mediaGen` family + `Generate3DTool`), `SwooshGenerativeUI` (catalog-gate pattern), `SwooshNetworkPolicy`, `SwooshSecrets`, `SwooshFirewall`, `ToolRegistry`.

## 5. Decisions made (this brainstorm)

- **Gen backend = pluggable, managed-first.** One `GenBackend` protocol; ship a managed-API adapter (fal.ai / Replicate / HF Endpoints) first for zero-infra working demos; allow a self-hosted CUDA endpoint to be slotted in later. Matches the existing `ProviderRouter` / `MediaGenDependencies` pattern.
- **Render baseline = WebGL2 via Spark 2.0** (Three.js, runs in `WKWebView` today, 100M+ Gaussian splats). WebGPU/Visionary is a **feature-detected upgrade**, not a dependency.
- **Platform = macOS hub first.** The Mac runs `swooshd`, the gen orchestration, and the Studio web surface. iOS is a later thin viewer (it already only imports `SwooshClient`).
- **Catalog stays at 75 entries** (gaming/R&D/persona/voice/NSFW); TRELLIS.2-4B entry remains but is now backed by a remote `GenBackend`, and its `estimatedMemoryGB` note should reflect "remote" rather than 12 GB local.

## 6. Build sequence

Each is an independent spec → plan → build cycle:

1. **Pillar 1 — `GenBackend` + TRELLIS** (foundational; proves the remote-gen pattern end to end: image → managed API → GLB → cache → tool output).
2. **Pillar 3 — web render surface** (WebGL2/Spark in `WKWebView`; where generated assets land and AI worlds play).
3. **Pillar 4 — node-canvas editor** (LiteGraph; orchestrates pillars 1 + 3 visually; graphs ↔ `SwooshFlow`).
4. **Pillar 5 — AI editing** (image/3D edit nodes over the same backends).

**Pillar 2 (drive existing games)** is an independent track reusing already-built `SwooshCloudGaming`; schedulable at any point — its only new work is the agent action loop.

## 7. Known forks — resolved in sub-specs, **not** here

- **DAG vs. linear steps.** LiteGraph is a DAG; `SwooshFlow` executes linear steps. The node-editor sub-spec (Pillar 4) chooses among: extend `SwooshFlow` to a DAG, compile a DAG into a linear plan, or introduce a dedicated graph model. Naming the fork now; not resolving it.
- **WebGPU enablement.** Verified (2026-05): WebGPU is default-on in Safari 26 but **off by default in `WKWebView`** — hybrid apps need a WebGL fallback or to flip an experimental WebKit preference. Baseline is therefore WebGL2/Spark; the render sub-spec (Pillar 3) resolves the `navigator.gpu` detection + `_WKPreferences` flag path for the Visionary/WebGPU fast lane.

## 8. MVP slice (definition of "the umbrella works")

A user drags an image into Studio → the agent submits it to a managed `GenBackend` (TRELLIS) → a GLB returns, is cached, and renders in the WebGL2/Spark viewport — with the network call passing `SwooshNetworkPolicy`, the API key from Keychain, and the whole run appearing as a replayable, audited `ToolRegistry.execute`. That single path exercises pillars 1 + 3 and every invariant; everything else extends it.

## 9. Out of scope (YAGNI for the umbrella)

- Native (non-web) 3D rendering or a Swift game engine.
- On-device/MLX path for 24 GB-class gen models.
- Real-time generation (TRELLIS is 3–60 s/asset — treated as offline jobs).
- Training/fine-tuning models in-process (training harness remains the separate [Gaming-Harness-Plan.md](Gaming-Harness-Plan.md) track).
- Multiplayer/MMO *hosting* (we drive/stream existing MMOs; we do not run game servers).

## 10. References (open-source tech surveyed)

- **TRELLIS.2-4B** — Microsoft, image→3D, GLB + PBR, MIT, 24 GB CUDA, offline. <https://huggingface.co/microsoft/TRELLIS.2-4B>
- **Spark 2.0** — World Labs, Three.js + WebGL2 Gaussian-splat world runtime, 100M+ points in-browser. <https://sparkjs.dev/docs/overview/>
- **Visionary** — WebGPU + ONNX real-time 3D/4D splatting + world models. <https://arxiv.org/html/2512.08478v1>
- **LiteGraph.js** — HTML5 node-graph engine/editor, JSON serialization (ComfyUI's frontend lineage). <https://github.com/jagenjo/litegraph.js>
- Node-editor alternatives surveyed: React Flow, Rete, BaklavaJS, Flume — <https://github.com/xyflow/awesome-node-based-uis>
- WebGPU-in-WKWebView status — <https://webkit.org/blog/16993/news-from-wwdc25-web-technology-coming-this-fall-in-safari-26-beta/>
