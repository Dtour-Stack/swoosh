// swift-tools-version: 6.3
import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Swoosh",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v26),
        .iOS(.v26)
    ],
    products: [
        // ── Executables ───────────────────────────────────────────────
        .executable(name: "swoosh",  targets: ["SwooshCLIRunner"]),
        // `swooshd` is no longer a standalone binary — the macOS app boots
        // the agent runtime in-process via SwooshDaemon.start(). Exposed as
        // a library so the app target can link it.
        .library(name: "SwooshDaemon", targets: ["SwooshDaemon"]),

        // ── Public SDK ────────────────────────────────────────────────
        .library(name: "SwooshKit", targets: ["SwooshKit"]),

        // ── Individual libraries ──────────────────────────────────────
        .library(name: "SwooshCore",      targets: ["SwooshCore"]),
        .library(name: "SwooshConfig",    targets: ["SwooshConfig"]),
        .library(name: "SwooshTUI",       targets: ["SwooshTUI"]),
        .library(name: "SwooshFirewall",  targets: ["SwooshFirewall"]),
        .library(name: "SwooshFlow",      targets: ["SwooshFlow"]),
        .library(name: "SwooshFoundation",targets: ["SwooshFoundation"]),
        .library(name: "SwooshSecrets",   targets: ["SwooshSecrets"]),
        .library(name: "SwooshUI",        targets: ["SwooshUI"]),
        .library(name: "SwooshApprovals", targets: ["SwooshApprovals"]),
        .library(name: "SwooshWidgets",  targets: ["SwooshWidgets"]),
        .library(name: "SwooshGenerativeUI", targets: ["SwooshGenerativeUI"]),
        .library(name: "SwooshClient",       targets: ["SwooshClient"]),
        .library(name: "SwooshDaemonSupport", targets: ["SwooshDaemonSupport"]),
        .library(name: "SwooshGoals",        targets: ["SwooshGoals"]),
        .library(name: "SwooshManifesting",  targets: ["SwooshManifesting"]),
        .library(name: "SwooshProviderBridge", targets: ["SwooshProviderBridge"]),
        .library(name: "SwooshCron", targets: ["SwooshCron"]),
        .library(name: "SwooshCalendar", targets: ["SwooshCalendar"]),
        .library(name: "SwooshChatSDK", targets: ["SwooshChatSDK"]),
        .library(name: "SwooshLocalLLM", targets: ["SwooshLocalLLM"]),
        .library(name: "SwooshModels", targets: ["SwooshModels"]),
        .library(name: "SwooshSTT", targets: ["SwooshSTT"]),
        .library(name: "SwooshVoiceProviders", targets: ["SwooshVoiceProviders"]),
        .library(name: "SwooshLocalVoice", targets: ["SwooshLocalVoice"]),
        .library(name: "SwooshMusic", targets: ["SwooshMusic"]),
        .library(name: "SwooshVision", targets: ["SwooshVision"]),
        .library(name: "SwooshTranslation", targets: ["SwooshTranslation"]),
        .library(name: "SwooshEmbeddings", targets: ["SwooshEmbeddings"]),
        .library(name: "SwooshImageGen", targets: ["SwooshImageGen"]),
        .library(name: "SwooshCapabilities", targets: ["SwooshCapabilities"]),
        .library(name: "SwooshNetworkPolicy", targets: ["SwooshNetworkPolicy"]),
        .library(name: "SwooshArena", targets: ["SwooshArena"]),
        .library(name: "SwooshCLI",          targets: ["SwooshCLI"]),
    ],
    dependencies: [
        // CLI
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        // Database
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.15.3"),
        // HTTP server
        .package(url: "https://github.com/hummingbird-project/hummingbird", from: "2.0.0"),
        // WhisperKit — Apple Silicon-optimised speech-to-text via Core ML
        .package(url: "https://github.com/argmaxinc/WhisperKit", from: "1.0.0"),
        // WasmKit — embeddable WebAssembly runtime for the wasm-kind plugin
        // executor. Includes the `WAT` package so the bundled .wat demo can
        // be compiled at runtime without shipping a precompiled .wasm.
        .package(url: "https://github.com/swiftwasm/WasmKit.git", from: "0.2.0"),
    ],
    targets: [
        // ══════════════════════════════════════════════════════════════
        // MARK: - CLI & Daemon
        // ══════════════════════════════════════════════════════════════
        .target(
            name: "SwooshCLI",
            dependencies: [
                "SwooshKit",
                "SwooshClient",
                "SwooshConfig",
                "SwooshTUI",
                "SwooshModels",
                "SwooshProviders",
                "SwooshProviderBridge",
                "SwooshToolsets",
                "SwooshSecrets",
                "SwooshDoctor",
                "SwooshFirewall",
                "SwooshFlow",
                "SwooshApprovals",
                "SwooshFiles",
                "SwooshProcess",
                "SwooshArena",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "SwooshCLIRunner",
            dependencies: ["SwooshCLI"]
        ),
        .target(
            name: "SwooshDaemon",
            dependencies: [
                "SwooshKit",
                "SwooshStorage",
                "SwooshConfig",
                "SwooshAPI",
                "SwooshSkills",
                "SwooshGoals",
                "SwooshManifesting",
                "SwooshCron",
                "SwooshCalendar",
                "SwooshDoctor",
                "SwooshProviderBridge",
                "SwooshSecrets",
                "SwooshModels",
                "SwooshProviders",
                "SwooshDaemonSupport",
                "SwooshToolsets",
                "SwooshTools",
                "SwooshFirewall",
                "SwooshFlow",
                "SwooshApprovals",
                "SwooshFiles",
                "SwooshProcess",
                "SwooshFoundation",
                "SwooshPlugins",
                "SwooshPluginRuntime",
                "SwooshDemoPlugins",
                "SwooshImageGen",
                "SwooshMusic",
                "SwooshArena",
            ]
        ),
        .target(
            name: "SwooshDaemonSupport",
            dependencies: []
        ),

        // ══════════════════════════════════════════════════════════════
        // MARK: - SwooshKit — public SDK
        // ══════════════════════════════════════════════════════════════
        .target(
            name: "SwooshKit",
            dependencies: [
                "SwooshCore",
                "SwooshTools",
                "SwooshClient",
                "SwooshStorage",
            ]
        ),

        // ══════════════════════════════════════════════════════════════
        // MARK: - Core runtime
        // ══════════════════════════════════════════════════════════════
        .target(
            name: "SwooshCore",
            dependencies: [
                "SwooshTools",
            ]
        ),

        // ══════════════════════════════════════════════════════════════
        // MARK: - Config, credentials, setup, diagnostics
        // ══════════════════════════════════════════════════════════════
        .target(name: "SwooshConfig", dependencies: ["SwooshClient", "SwooshTools", "SwooshSecrets"]),
        .target(name: "SwooshTUI", dependencies: ["SwooshTools"]),

        // ══════════════════════════════════════════════════════════════
        // MARK: - Models & inference
        // ══════════════════════════════════════════════════════════════
        .target(name: "SwooshModels",    dependencies: []),  // Standalone model catalog + HF discovery
        .target(name: "SwooshFoundation", dependencies: ["SwooshCore", "SwooshClient"]),   // Apple Foundation Models adapter
        .target(name: "SwooshSecrets",    dependencies: ["SwooshTools"]),   // Keychain + SecretRef + SecretResolving
        .target(name: "SwooshNetworkPolicy", dependencies: ["SwooshTools"]),   // Per-host outbound HTTP gate + audit fanout
        .target(name: "SwooshProviders",  dependencies: ["SwooshTools", "SwooshSecrets", "SwooshModels", "SwooshNetworkPolicy"]),
        .target(
            name: "SwooshProviderBridge",
            dependencies: ["SwooshCore", "SwooshProviders", "SwooshSecrets", "SwooshTools", "SwooshModels"]
        ),

        // ══════════════════════════════════════════════════════════════
        // MARK: - Tools
        // ══════════════════════════════════════════════════════════════
        .target(name: "SwooshTools",    dependencies: []),
        .target(name: "SwooshToolsets", dependencies: [
            "SwooshTools",
            "SwooshFiles",
            "SwooshSkills",
            "SwooshGoals",
            "SwooshManifesting",
            "SwooshCron",
            "SwooshCalendar",
            "SwooshMCP",
            "SwooshClient",
            "SwooshImageGen",
            "SwooshMusic",
            "SwooshArena",
        ], exclude: [
            // NitroGen ships a Python helper + keymap JSON + README that
            // are runtime assets installed elsewhere — they aren't Swift
            // sources and don't belong as SwiftPM resources of the Swift
            // target. Excluding silences the SwiftPM unhandled-file
            // warnings without dropping NitroGen's two Swift files
            // (NitroGenTools.swift + NitroGenToolDependencies.swift).
            "NitroGen/nitrogen_mac",
            "NitroGen/keymaps",
            "NitroGen/README.md",
        ]),

        // ══════════════════════════════════════════════════════════════
        // MARK: - Differentiating subsystems
        // ══════════════════════════════════════════════════════════════
        .target(name: "SwooshFirewall", dependencies: [
            "SwooshTools",
        ], exclude: ["CLAUDE.md"]),
        .target(name: "SwooshStorage", dependencies: [
            "SwooshTools",
            "SwooshCore",
            "SwooshApprovals",
            .product(name: "SQLite", package: "SQLite.swift"),
        ]),
        .target(name: "SwooshFlow",     dependencies: ["SwooshTools", "SwooshFirewall"], exclude: ["CLAUDE.md"]),
        .target(name: "SwooshSkills",       dependencies: ["SwooshTools"]),
        .target(name: "SwooshGoals",        dependencies: ["SwooshTools"]),
        .target(name: "SwooshManifesting",  dependencies: ["SwooshTools"]),
        .target(name: "SwooshCron", dependencies: ["SwooshTools"]),
        .target(name: "SwooshCalendar", dependencies: ["SwooshTools"]),
        .target(name: "SwooshCloudGaming", dependencies: ["SwooshTools"]),
        .target(name: "SwooshArena", dependencies: ["SwooshTools"]),
        .target(name: "SwooshChatSDK", dependencies: ["SwooshClient"]),
        .target(
            name: "SwooshApprovals",
            dependencies: ["SwooshTools"]
        ),
        // SwooshVision — Apple Vision wrapper (OCR, depth, foreground mask,
        // document recognition, face detection). Cross-platform.
        .target(
            name: "SwooshVision",
            dependencies: []
        ),
        // SwooshTranslation — Apple Translation framework + OpenAI fallback.
        // Cross-platform.
        .target(
            name: "SwooshTranslation",
            dependencies: []
        ),
        // SwooshEmbeddings — Apple NaturalLanguage + OpenAI cloud fallback
        // wrapped behind a single EmbeddingRouter. Cross-platform.
        .target(
            name: "SwooshEmbeddings",
            dependencies: []
        ),
        // SwooshImageGen — Apple Image Playground + OpenAI cloud fallback.
        // Cross-platform; the local provider gates on macOS 15.2+/iOS 18.2+.
        // Depends on SwooshTools so cloud providers can require permissions
        // and emit AuditEntry records through the Firewall + AuditLogging
        // protocols (concrete impls injected daemon-side; iOS picker passes
        // nil and the gating is a no-op).
        .target(
            name: "SwooshImageGen",
            dependencies: ["SwooshTools"]
        ),
        // SwooshCapabilities — unified router + status snapshot for the
        // four post-LLM modalities (Vision/Translation/Embeddings/ImageGen).
        // Mirrors the VoiceRouter pattern: UserDefaults-driven, swappable.
        // Reads API keys hot from SwooshSecrets' KeychainAPIKeyProvider so
        // a key written by any picker is picked up on the next provider call.
        .target(
            name: "SwooshCapabilities",
            dependencies: [
                "SwooshSecrets",
                "SwooshVision",
                "SwooshTranslation",
                "SwooshEmbeddings",
                "SwooshImageGen",
            ]
        ),
        .testTarget(
            name: "SwooshCapabilitiesTests",
            dependencies: ["SwooshCapabilities", "SwooshSecrets"]
        ),
        .target(
            name: "SwooshFiles",
            dependencies: ["SwooshTools"]
        ),
        .target(
            name: "SwooshProcess",
            dependencies: ["SwooshTools"]
        ),

        // ══════════════════════════════════════════════════════════════
        // MARK: - Infrastructure
        // ══════════════════════════════════════════════════════════════
        .target(name: "SwooshMCP",      dependencies: ["SwooshTools"]),
        .target(name: "SwooshPlugins",  dependencies: ["SwooshTools"]),
        // SwooshPluginRuntime — server-side plugin host. Owns the lifecycle
        // (enable/disable/install/uninstall), the bridge that turns plugin
        // tools into AnySwooshTool instances inside ToolRegistry, and the
        // per-kind executors. macOS/Linux only — iOS never links this.
        .target(
            name: "SwooshPluginRuntime",
            dependencies: [
                "SwooshPlugins",
                "SwooshTools",
                "SwooshFirewall",
                "SwooshMCP",
                .product(name: "WasmKit", package: "WasmKit"),
                .product(name: "WAT", package: "WasmKit"),
                .product(name: "WasmKitWASI", package: "WasmKit"),
            ]
        ),
        // SwooshDemoPlugins — reference Swift plugins linked into swooshd.
        // Authors copy this target's shape when writing their own Swift
        // plugin. Empty on iOS (the iOS app never loads plugins).
        .target(
            name: "SwooshDemoPlugins",
            dependencies: ["SwooshPlugins", "SwooshTools"]
        ),
        .target(name: "SwooshDoctor",        dependencies: ["SwooshTools", "SwooshConfig", "SwooshClient"]),

        // ══════════════════════════════════════════════════════════════
        // MARK: - API server + transport-agnostic client
        // ══════════════════════════════════════════════════════════════
        // SwooshClient holds the wire format (Codable types) plus a
        // URLSession-based client. It is intentionally free of Hummingbird,
        // SwooshCore, or anything that touches `Process`, so the iOS app
        // can import it without pulling in the kernel or the actantdb
        // supervisor.
        .target(
            name: "SwooshClient",
            dependencies: []
        ),
        .target(
            name: "SwooshAPI",
            dependencies: [
                "SwooshCore",
                "SwooshClient",
                "SwooshConfig",
                "SwooshTools",
                "SwooshChatSDK",
                .product(name: "Hummingbird", package: "hummingbird"),
            ]
        ),

        // ══════════════════════════════════════════════════════════════
        // MARK: - SwiftUI (shared)
        // ══════════════════════════════════════════════════════════════
        .target(
            name: "SwooshLocalLLM",
            dependencies: [
                "SwooshClient",
                "SwooshModels",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),

        // ══════════════════════════════════════════════════════════════
        // MARK: - SwooshSTT — speech-to-text providers
        // ══════════════════════════════════════════════════════════════
        .target(
            name: "SwooshSTT",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
            ]
        ),

        // ══════════════════════════════════════════════════════════════
        // MARK: - SwooshVoiceProviders — cloud TTS adapters
        // ══════════════════════════════════════════════════════════════
        .target(
            name: "SwooshVoiceProviders",
            dependencies: ["SwooshSecrets", "SwooshMusic", "SwooshSTT"]
        ),

        // ══════════════════════════════════════════════════════════════
        // MARK: - SwooshLocalVoice — on-device TTS (Kokoro, OmniVoice)
        // ══════════════════════════════════════════════════════════════
        // Mirrors SwooshLocalLLM for voice. Today the engine falls back
        // to AVSpeechSynthesizer (so the audio loop works end-to-end);
        // the swap point is `LocalVoiceEngine.backend`. When an ONNX
        // Runtime / MLX-Audio / CoreML dep lands, add a Backend impl
        // and the rest of the stack (downloader, provider, picker,
        // Settings UI) keeps working.
        .target(
            name: "SwooshLocalVoice",
            dependencies: [
                "SwooshVoiceProviders",
            ]
        ),

        // ══════════════════════════════════════════════════════════════
        // MARK: - SwooshMusic — music generation providers
        // ══════════════════════════════════════════════════════════════
        // Depends on SwooshTools so cloud providers can require permissions
        // and emit AuditEntry records through the Firewall + AuditLogging
        // protocols (concrete impls injected daemon-side; iOS picker passes
        // nil and the gating is a no-op).
        .target(
            name: "SwooshMusic",
            dependencies: ["SwooshSecrets", "SwooshTools"]
        ),

        .target(
            name: "SwooshUI",
            dependencies: [
                "SwooshCore", "SwooshClient", "SwooshConfig", "SwooshTools",
                "SwooshFirewall", "SwooshFlow", "SwooshSecrets", "SwooshProviders",
                "SwooshGenerativeUI", "SwooshModels", "SwooshSkills", "SwooshCloudGaming",
            ],
            resources: [.copy("Resources/GamingIcons")]
        ),
        .target(
            name: "SwooshWidgets",
            dependencies: ["SwooshSecrets", "SwooshProviders"]
        ),


        // ══════════════════════════════════════════════════════════════
        // MARK: - Generative UI (agent-emitted, native renderer)
        // ══════════════════════════════════════════════════════════════
        .target(
            name: "SwooshGenerativeUI",
            dependencies: []
        ),

        // ══════════════════════════════════════════════════════════════
        // MARK: - Tests
        // ══════════════════════════════════════════════════════════════
        .testTarget(
            name: "SwooshApprovalsTests",
            dependencies: ["SwooshApprovals", "SwooshTools"]
        ),
        .testTarget(
            name: "SwooshNetworkPolicyTests",
            dependencies: ["SwooshNetworkPolicy", "SwooshTools"]
        ),
        .testTarget(
            name: "SwooshMCPTests",
            dependencies: ["SwooshMCP", "SwooshTools"]
        ),
        .testTarget(
            name: "SwooshPluginsTests",
            dependencies: ["SwooshPlugins", "SwooshTools"]
        ),
        .testTarget(
            name: "SwooshPluginRuntimeTests",
            dependencies: ["SwooshPluginRuntime", "SwooshPlugins", "SwooshTools", "SwooshFirewall"]
        ),
        .testTarget(
            name: "SwooshDoctorTests",
            dependencies: ["SwooshDoctor", "SwooshTools"]
        ),
        .testTarget(
            name: "SwooshTUITests",
            dependencies: ["SwooshTUI"]
        ),
        .testTarget(
            name: "SwooshCoreTests",
            dependencies: ["SwooshCore", "SwooshTools", "SwooshFirewall", "SwooshApprovals"]
        ),
        .testTarget(
            name: "SwooshToolsTests",
            dependencies: ["SwooshTools", "SwooshFirewall", "SwooshToolsets"]
        ),
        .testTarget(
            name: "SwooshAgentLoopTests",
            dependencies: ["SwooshCore", "SwooshKit", "SwooshTools", "SwooshFirewall", "SwooshApprovals", "SwooshToolsets"]
        ),
        .testTarget(
            name: "SwooshDevToolsTests",
            dependencies: ["SwooshTools", "SwooshFiles", "SwooshProcess", "SwooshFirewall"]
        ),
        .testTarget(
            name: "SwooshFilesTests",
            dependencies: ["SwooshFiles", "SwooshTools"]
        ),
        .testTarget(
            name: "SwooshFlowTests",
            dependencies: ["SwooshFlow", "SwooshTools", "SwooshFirewall"]
        ),
        .testTarget(
            name: "SwooshSecretsTests",
            dependencies: ["SwooshSecrets"]
        ),
        .testTarget(
            name: "SwooshProvidersTests",
            dependencies: ["SwooshProviders", "SwooshProviderBridge", "SwooshSecrets", "SwooshTools", "SwooshCore", "SwooshModels"]
        ),
        .testTarget(
            name: "SwooshUITests",
            dependencies: ["SwooshUI"]
        ),
        .testTarget(
            name: "SwooshWidgetsTests",
            dependencies: ["SwooshWidgets"]
        ),
        .testTarget(
            name: "SwooshGenerativeUITests",
            dependencies: ["SwooshGenerativeUI"]
        ),
        .testTarget(
            name: "SwooshAPITests",
            dependencies: [
                "SwooshAPI",
                "SwooshCore",
                "SwooshConfig",
                "SwooshTools",
                "SwooshFirewall",
                "SwooshApprovals",
                "SwooshToolsets",
                .product(name: "HummingbirdTesting", package: "hummingbird"),
            ]
        ),
        .testTarget(
            name: "SwooshClientTests",
            dependencies: ["SwooshClient", "SwooshChatSDK"]
        ),
        .testTarget(
            name: "SwooshCronTests",
            dependencies: ["SwooshCron", "SwooshTools"]
        ),
        .testTarget(
            name: "SwooshCalendarTests",
            dependencies: ["SwooshCalendar", "SwooshTools"]
        ),
        .testTarget(
            name: "SwooshSkillsTests",
            dependencies: ["SwooshSkills"]
        ),
        .testTarget(
            name: "SwooshChatSDKTests",
            dependencies: ["SwooshChatSDK", "SwooshClient"]
        ),
        .testTarget(
            name: "SwooshDaemonTests",
            dependencies: ["SwooshDaemonSupport"]
        ),
        .testTarget(
            name: "SwooshGoalsTests",
            dependencies: ["SwooshGoals", "SwooshTools"]
        ),
        .testTarget(
            name: "SwooshManifestingTests",
            dependencies: ["SwooshManifesting", "SwooshTools"]
        ),
        .testTarget(
            name: "SwooshConfigTests",
            dependencies: ["SwooshConfig"]
        ),
        .testTarget(
            name: "SwooshFirewallTests",
            dependencies: ["SwooshFirewall", "SwooshTools"]
        ),
        .testTarget(
            name: "SwooshStorageTests",
            dependencies: ["SwooshStorage", "SwooshTools", "SwooshCore", "SwooshApprovals"]
        ),
        .testTarget(
            name: "SwooshModelsTests",
            dependencies: ["SwooshModels"]
        ),
        .testTarget(
            name: "SwooshLocalLLMTests",
            dependencies: ["SwooshLocalLLM"]
        ),
        .testTarget(
            name: "SwooshLocalVoiceTests",
            dependencies: ["SwooshLocalVoice"]
        ),
        .testTarget(
            name: "SwooshFoundationTests",
            dependencies: ["SwooshFoundation", "SwooshCore", "SwooshClient"]
        ),
        .testTarget(
            name: "SwooshEmbeddingsTests",
            dependencies: ["SwooshEmbeddings"]
        ),
        .testTarget(
            name: "SwooshKitTests",
            dependencies: ["SwooshKit", "SwooshClient", "SwooshCore"]
        ),
        .testTarget(
            name: "SwooshToolsetsTests",
            dependencies: [
                "SwooshToolsets",
                "SwooshTools",
                "SwooshFirewall",
                "SwooshFiles",
                "SwooshProcess",
                "SwooshImageGen",
                "SwooshMusic",
                "SwooshArena",
            ]
        ),
        .testTarget(
            name: "SwooshCLITests",
            dependencies: [
                "SwooshCLI",
                "SwooshClient",
                "SwooshConfig",
                "SwooshArena",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "SwooshVisionTests",
            dependencies: ["SwooshVision"]
        ),
        .testTarget(
            name: "SwooshCloudGamingTests",
            dependencies: ["SwooshCloudGaming"]
        ),
        .testTarget(
            name: "SwooshArenaTests",
            dependencies: ["SwooshArena"]
        ),
    ]
)
