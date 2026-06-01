# Swoosh v1 — Changelog

Released: **May 2026**.

The shipping spine in one document. Every capability below is wired,
built, and exercised by `swift test` (1757 tests / 396 suites, all
passing) and the `xcodebuild SwooshiOS` simulator build.

## v1.1.5 — June 2026 Cartridge CLI starter generator

- Added `GameCLIStarterCatalog` and `GameCLIStarterFactory` for generating focused game, agent, character, and laptop navigator CLIs from text, voice transcript, vision summary, and NitroGen/provider-policy prompts.
- Added the `cartridge-laptop-cli` starter so agents can turn user voice prompts into CLI-driven laptop navigation plans and optional macOS actions for screenshots, app focus, URL launch, clicks, typing, and hotkeys.
- Added `game.list_cli_starters`, `game.init_cli_starter`, and `GET /api/game/creation-catalog` so agents and the iOS Game Lab can discover CLI starters alongside 2D, 3D, and pipeline catalogs.
- Updated Game Lab to surface Cartridge CLI starters while retaining local game URL loading.

## v1.1.4 — June 2026 Cartridge 2D creation catalog

- Added a Cartridge 2D creation catalog covering Swoosh image generation, cloud image APIs, local-hostable sprite studios, pixel editors, atlas packers, and tilemap tools.
- Added `game.list_2d_creation_providers` so agents can choose sprite, tile, parallax, prop, outpaint, local pixel-editing, or engine-packaging paths before generating 2D game assets.
- Added a Pipeline-style 2D asset-studio template for anchor locking, sheet generation, deterministic normalization, and engine-ready packaging.

## v1.1.3 — June 2026 Cartridge 3D generation catalog

- Added a Cartridge 3D generation provider catalog covering wired FAL endpoints, cloud providers, open-source/local-hostable models, asset libraries, and mesh-processing services.
- Added `game.list_3d_generation_providers` so agents can choose cloud, local-hostable, asset-library, or post-processing 3D paths before generating game content.
- Updated the FAL 3D provider surface for Hunyuan 3D v3.1 Pro and Trellis 2 model IDs, and added image PNG input support to `media.generate_3d`.

## v1.1.2 — June 2026 Pipeline import bridge

- Added Pipeline/React Flow graph import for Cartridge sessions through `GamePipelineImportDocument` and `game.import_pipeline`.

## v1.1.1 — June 2026 Cartridge scaffold materialization

- Added on-disk scaffold materialization for `game.init_project` behind the existing `fileWrite` permission.
- Reused the shared Cartridge local URL policy in the iOS game lab and wired the iOS target to `SwooshArena`.

## v1.1 — June 2026 Cartridge game harness

- Removed the remaining token/rebate anchor surface from the runtime, API, storage, provider naming, and visible app copy.
- Promoted Cartridge as the default agent and app-facing name across macOS, iOS, providers, and the game harness.
- Added `SwooshArena` as the Cartridge game harness domain: sessions, local URL loading, policies, observations, actions, generated content artifacts, pipeline graphs, and evaluations.
- Added the first integration catalog for Three.js, WebGPU, Unity, Unreal Engine, Blender, Roblox, Fortnite UEFN, Minecraft, and Autodesk 3ds Max.
- Added starter scaffold generation for runnable Three.js/WebGPU projects plus engine, DCC, UGC, and modding bridge skeletons.
- Added Pipeline-style graph templates for web runtimes, engine plugin bridges, and DCC asset export.
- Added gaming tools: `game.list_integrations`, `game.list_pipeline_templates`, and `game.init_project`.

## macOS app

- **Menu-bar tray popover** (`MenuBarExtra`) — agent shell as the
  primary surface; older fixed status sections still available via
  config.
- **Customizable PanelHost** — 36 panel kinds across every Swoosh
  module (Wallet, Wallet Analytics, Recent Chats, Skills, Audit,
  Providers, Local Models, Memories, Goals, Manifesting, MCP, etc.).
  Drag-drop reorder via `Transferable`; add/remove via picker sheet.
  Adaptive grid: 1 col ≤700pt → 2 cols 700–1100 → 3 cols 1100–1500
  → 4 cols >1500. Density picker (compact / cozy / comfortable).
- **Voice pills** — top floating (⌥Space, frameless) + bottom
  anchored (persistent during voice mode) + desktop overlay scene
  that hosts agent-emitted generative-UI surfaces.
- **Global hotkey** — `Carbon.HIToolbox.RegisterEventHotKey`
  wrapped in `GlobalHotKey` actor.
- **Menu commands** — Show/Hide Voice Pill, Toggle Voice Mode, Open
  Dashboard, Toggle Full Screen.
- **Neon design tokens** in `SwooshGenerativeUI/Tokens/` —
  cyan/gold/green accents on pure black, hairline outlines, glow
  scale, shared by static screens and agent-emitted UI.

## iOS companion app

- **`AgentRoot`** — replaces the bespoke ChatScreen with cross-
  platform `AgentShellView` powered by the same `AgentShellModel`
  the Mac uses.
- **`WorkspaceScreen`** — `PanelHost(surface: "ios")` with iOS-
  shaped DnD (long-press) and a default panel layout that fits
  phone form factor.
- **`IOSVoicePill`** — bottom-anchored capsule with push-to-talk,
  live transcript, TTS toggle, waveform, exit affordance.
- **`VoicePickerScreen`** — unified Settings → Voice. Four sections:
  STT engine (Apple Dictation / Whisper + per-model download), TTS
  engine (System voices / ElevenLabs / OpenAI / Cartesia + voice
  search), music provider (Suno V5.5 / ElevenLabs Music / Stable
  Audio), and Keychain key entry with **Get key →** provider
  signup-URL deep links.
- **`LocalFallbackToggleRow`** in Settings → enables the "use
  on-device LLM when daemon offline" route.
- **Info.plist** — `NSMicrophoneUsageDescription`,
  `NSSpeechRecognitionUsageDescription`, `NSLocalNetworkUsageDescription`,
  `NSFaceIDUsageDescription`, `NSBonjourServices=_swoosh._tcp`.

## Voice stack

- **`SpeechCapture`** — `SFSpeechRecognizer` + `AVAudioEngine` live
  mic capture with RMS-derived audio levels.
- **`TTSEngine`** — `AVSpeechSynthesizer` wrapper with rate/pitch
  configuration and system-voice picker integration.
- **`VoiceMode`** — orchestrator coordinating STT + agent + TTS +
  optional desktop overlay. Each subsystem independent:
  - No TTS engine = transcribe-only.
  - No overlay = surfaces render in pill.
  - No mic = text-only.
- **`StreamingTTSPlayer`** — `AVAudioEngine` + `AVAudioPlayerNode`
  with PCM-fast-path and compressed-via-`AVAudioFile` paths.
  - Cartesia raw PCM → ~40 ms first audible byte.
  - ElevenLabs / OpenAI MP3 → ~400 ms.
  - 3-try open with 80/160/320 ms backoff for iOS growing-file
    robustness.
  - 12-band RMS levels via `installTap` for waveform UI.
- **`TTSPlayback`** — blob `AVAudioPlayer` wrapper with pause/seek/
  rate (0.5–2×) / volume + 200 ms position polling for scrubber.
- **`VoiceRouter.shared`** — UserDefaults-driven dispatcher with
  per-provider Keychain-bound API key closures.

## STT providers

- **Apple Speech (`SystemFileSTTProvider`)** — file transcription
  via `SFSpeechURLRecognitionRequest`.
- **WhisperKit (`WhisperSTTProvider`)** — 4 model sizes:
  - `openai_whisper-tiny.en` (40 MB)
  - `openai_whisper-small.en` (250 MB)
  - `openai_whisper-small` multilingual (250 MB)
  - `openai_whisper-large-v3-turbo` (800 MB)
- **`WhisperModelManager`** — `@Observable` per-model download state
  machine. Explicit "Download" + "Delete" buttons in the picker.

## Cloud TTS providers

| Provider | Endpoint | Streaming | Notes |
|---|---|---|---|
| **ElevenLabs** | `/v1/text-to-speech/{voice}/stream` | ✓ MP3 chunks | Voice cloning, 30+ langs |
| **OpenAI** | `/v1/audio/speech` | ✓ chunked + PCM | Alloy / echo / fable / onyx / nova / shimmer |
| **Cartesia** | `/tts/sse` | ✓ SSE base64 PCM | Sonic, ~40 ms first-byte |

Each provider exposes `signupURL` so the picker can deep-link to the
right API-key dashboard.

## Music generation

| Provider | Endpoint | Model |
|---|---|---|
| **Suno** | `api.sunoapi.org/api/v1/generate` (poll `/record-info`) | V5_5 / V5 / V4_5+ |
| **ElevenLabs Music** | `/v1/music` | `music_v1` |
| **Stable Audio** | `/v2beta/audio/stable-audio-2/text-to-audio` | `stable-audio-2` |

## Local LLM

- **`SwooshLocalLLM`** — wraps vendored `LiteRTLM` swift wrapper
  (`google-ai-edge/LiteRT-LM v0.12` — vendored to avoid SwiftPM's
  multi-GB full-repo clone tax).
- **Catalog**: Gemma 4 E4B (default, 3.7 GB, multimodal vision + audio),
  Gemma 4 E2B (2.6 GB, multimodal vision + audio).
- **`LiteRTSwooshToolBridge`** — `SwooshDispatchTool` lets the
  on-device model invoke any registered Swoosh tool through the
  same `SwooshFirewall` gate as the cloud path.
- **`FallbackExecutor`** — wraps the remote `swooshd` executor with
  automatic fall-through to the local model on daemon-unreachable.
- **`FoundationExecutor`** — Apple Foundation Models adapter
  conforming to `SwooshExecutor`. Free, private, on-device, no
  download.

## Persistence

- **`OfflineMessageCache`** — append-only JSONL ledger + outbox per
  session. iOS and macOS both write here; iPhone sees yesterday's
  conversation on launch even with the Mac off.
- **`CachedExecutor`** — decorator wrapping any `SwooshExecutor`
  with cache append + outbox queue. Auto-drains on next success.
- **`MessageSync` (planned, v1.5)** — CloudKit zone for cross-
  device merge. Foundation is in `Docs/iOS-Kernel-and-Sync.md`.

## Observability

- **`os.Logger` across the audio + provider stack** — subsystem
  `ai.swoosh`, categories: `tts`, `streaming`, `whisper`,
  `music.suno`, `music.elevenlabs`, `music.stable`, `stt.whisper`,
  `stt.system`, `keychain`. Use:
  ```
  xcrun simctl spawn booted log stream --predicate 'subsystem == "ai.swoosh"' --style compact
  ```

## Build status

```
swift build                          ✓ clean
swift test                           ✓ 1757 / 396 / 0 failures
xcodebuild SwooshiOS iOS Simulator   ✓ BUILD SUCCEEDED
```

## What's NOT in v1 (deliberate v2 candidates)

- Cross-device sync via CloudKit (foundation in
  `Docs/iOS-Kernel-and-Sync.md`).
- Anthropic / OpenAI third-party OAuth-to-inference (blocked in
  Q1 2026 by both vendors — see `Docs/PRD.md` provider notes).
- Live waveform on the bottom voice pill drawing from
  `StreamingTTSPlayer.levels` (currently driven by mic RMS).
- Saved generative surfaces as `PanelKind.custom(surfaceID:)`
  panels in the workspace.
- Settings → Voice provider sample previews via in-app player.
