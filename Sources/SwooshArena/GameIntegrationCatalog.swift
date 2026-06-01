// SwooshArena/GameIntegrationCatalog.swift — Cartridge integration catalog (0.1B)

import Foundation

public enum GameIntegrationKind: String, Codable, Sendable, CaseIterable {
    case webRuntime
    case gameEngine
    case dccTool
    case ugcPlatform
    case moddingPlatform
}

public enum GameIntegrationCapability: String, Codable, Sendable, CaseIterable {
    case loadLocalURL
    case runHarness
    case generateContent
    case exportContentPack
    case starterScaffold
    case pluginBridge
    case assetImport
    case playtest
    case telemetry
    case webgpuRender
    case nativeEngineBridge
    case dccBridge
}

public struct GameIntegrationDescriptor: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let kind: GameIntegrationKind
    public let capabilities: [GameIntegrationCapability]
    public let supportedModes: [GameHarnessMode]
    public let exportFormats: [GameExportFormat]
    public let pluginSurfaces: [String]
    public let localURLPatterns: [String]
    public let pipelineNodeKinds: [GamePipelineNodeKind]
    public let notes: [String]

    public init(
        id: String,
        displayName: String,
        kind: GameIntegrationKind,
        capabilities: [GameIntegrationCapability],
        supportedModes: [GameHarnessMode],
        exportFormats: [GameExportFormat],
        pluginSurfaces: [String],
        localURLPatterns: [String],
        pipelineNodeKinds: [GamePipelineNodeKind],
        notes: [String]
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.capabilities = capabilities
        self.supportedModes = supportedModes
        self.exportFormats = exportFormats
        self.pluginSurfaces = pluginSurfaces
        self.localURLPatterns = localURLPatterns
        self.pipelineNodeKinds = pipelineNodeKinds
        self.notes = notes
    }
}

public enum GameProjectTemplateKind: String, Codable, Sendable, CaseIterable {
    case threeJS
    case webGPU
    case unityPackage
    case unrealPlugin
    case blenderAddon
    case robloxExperience
    case fortniteUEFN
    case minecraftDatapack
    case threeDSMaxScript
}

public struct GameScaffoldFile: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let path: String
    public let role: String
    public let body: String

    public init(id: String = UUID().uuidString, path: String, role: String, body: String) {
        self.id = id
        self.path = path
        self.role = role
        self.body = body
    }
}

public struct GameProjectScaffold: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let template: GameProjectTemplateKind
    public let integrationIDs: [String]
    public let files: [GameScaffoldFile]
    public let pipelines: [GamePipeline]
    public let nextSteps: [String]
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        title: String,
        template: GameProjectTemplateKind,
        integrationIDs: [String],
        files: [GameScaffoldFile],
        pipelines: [GamePipeline],
        nextSteps: [String],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.template = template
        self.integrationIDs = integrationIDs
        self.files = files
        self.pipelines = pipelines
        self.nextSteps = nextSteps
        self.createdAt = createdAt
    }
}

public enum GameIntegrationCatalog {
    public static let all: [GameIntegrationDescriptor] = [
        GameIntegrationDescriptor(
            id: "threejs",
            displayName: "Three.js",
            kind: .webRuntime,
            capabilities: [.loadLocalURL, .runHarness, .starterScaffold, .assetImport, .playtest, .telemetry],
            supportedModes: [.play, .test, .create, .generate, .train],
            exportFormats: [.typescript, .json, .threejs, .glb, .gltf, .usd],
            pluginSurfaces: ["Vite dev server", "DOM HUD", "GLB asset manifest", "Cartridge local URL bridge"],
            localURLPatterns: ["http://localhost:*", "http://127.0.0.1:*", "file://*.html"],
            pipelineNodeKinds: [.trigger, .runtimeScaffold, .simulation, .render, .assetImport, .telemetry, .playtest, .export],
            notes: ["Plain TypeScript starter keeps simulation state outside renderer objects."]
        ),
        GameIntegrationDescriptor(
            id: "webgpu",
            displayName: "WebGPU",
            kind: .webRuntime,
            capabilities: [.loadLocalURL, .runHarness, .starterScaffold, .playtest, .telemetry, .webgpuRender],
            supportedModes: [.play, .test, .create, .generate, .train],
            exportFormats: [.typescript, .json, .webgpu],
            pluginSurfaces: ["GPUCanvasContext", "WGSL shader modules", "Cartridge local URL bridge"],
            localURLPatterns: ["http://localhost:*", "http://127.0.0.1:*"],
            pipelineNodeKinds: [.trigger, .runtimeScaffold, .simulation, .render, .telemetry, .playtest, .export],
            notes: ["Starter checks navigator.gpu before requesting an adapter."]
        ),
        GameIntegrationDescriptor(
            id: "unity",
            displayName: "Unity",
            kind: .gameEngine,
            capabilities: [.pluginBridge, .generateContent, .exportContentPack, .assetImport, .playtest, .nativeEngineBridge],
            supportedModes: [.play, .test, .create, .generate],
            exportFormats: [.unity, .csharp, .json, .glb, .fbx],
            pluginSurfaces: ["UPM package", "EditorWindow", "MonoBehaviour bridge", "PlayMode test hooks"],
            localURLPatterns: [],
            pipelineNodeKinds: [.pluginBridge, .assetImport, .engineAdapter, .playtest, .telemetry, .export],
            notes: ["Generated package is editor-installable and can call Cartridge HTTP endpoints."]
        ),
        GameIntegrationDescriptor(
            id: "unreal",
            displayName: "Unreal Engine",
            kind: .gameEngine,
            capabilities: [.pluginBridge, .generateContent, .exportContentPack, .assetImport, .playtest, .nativeEngineBridge],
            supportedModes: [.play, .test, .create, .generate],
            exportFormats: [.unreal, .cpp, .json, .glb, .fbx],
            pluginSurfaces: ["uplugin", "Subsystem", "Automation test hook", "Editor utility bridge"],
            localURLPatterns: [],
            pipelineNodeKinds: [.pluginBridge, .assetImport, .engineAdapter, .playtest, .telemetry, .export],
            notes: ["UEFN uses the Fortnite descriptor because the deploy surface is different."]
        ),
        GameIntegrationDescriptor(
            id: "blender",
            displayName: "Blender",
            kind: .dccTool,
            capabilities: [.pluginBridge, .generateContent, .assetImport, .dccBridge, .exportContentPack],
            supportedModes: [.create, .generate, .test],
            exportFormats: [.blender, .python, .json, .glb, .gltf, .usd, .fbx, .obj],
            pluginSurfaces: ["Python addon", "Asset export operator", "Scene metadata panel"],
            localURLPatterns: [],
            pipelineNodeKinds: [.pluginBridge, .assetGeneration, .assetImport, .export],
            notes: ["Use GLB or USD as the handoff format rather than DCC-native files."]
        ),
        GameIntegrationDescriptor(
            id: "roblox",
            displayName: "Roblox",
            kind: .ugcPlatform,
            capabilities: [.pluginBridge, .generateContent, .exportContentPack, .playtest, .telemetry],
            supportedModes: [.play, .test, .create, .generate],
            exportFormats: [.roblox, .lua, .json],
            pluginSurfaces: ["Rojo project", "ServerScriptService bridge", "Studio plugin"],
            localURLPatterns: [],
            pipelineNodeKinds: [.pluginBridge, .engineAdapter, .playtest, .telemetry, .export],
            notes: ["Starter emits a Rojo-compatible project shape."]
        ),
        GameIntegrationDescriptor(
            id: "fortnite-uefn",
            displayName: "Fortnite UEFN",
            kind: .ugcPlatform,
            capabilities: [.generateContent, .exportContentPack, .playtest],
            supportedModes: [.play, .test, .create, .generate],
            exportFormats: [.fortniteUEFN, .verse, .json],
            pluginSurfaces: ["UEFN content pack", "Verse device scaffold", "playtest checklist"],
            localURLPatterns: [],
            pipelineNodeKinds: [.assetGeneration, .engineAdapter, .playtest, .export],
            notes: ["Generated files stay in project-local content and Verse surfaces."]
        ),
        GameIntegrationDescriptor(
            id: "minecraft",
            displayName: "Minecraft",
            kind: .moddingPlatform,
            capabilities: [.generateContent, .exportContentPack, .playtest],
            supportedModes: [.play, .test, .create, .generate],
            exportFormats: [.minecraft, .mcfunction, .json],
            pluginSurfaces: ["datapack", "function tags", "resource-pack handoff"],
            localURLPatterns: [],
            pipelineNodeKinds: [.assetGeneration, .simulation, .playtest, .export],
            notes: ["Datapack scaffold keeps generated behavior deterministic and inspectable."]
        ),
        GameIntegrationDescriptor(
            id: "3ds-max",
            displayName: "Autodesk 3ds Max",
            kind: .dccTool,
            capabilities: [.pluginBridge, .assetImport, .dccBridge, .exportContentPack],
            supportedModes: [.create, .generate, .test],
            exportFormats: [.threeDSMax, .json, .fbx, .obj, .glb],
            pluginSurfaces: ["MAXScript exporter", "metadata sidecar"],
            localURLPatterns: [],
            pipelineNodeKinds: [.pluginBridge, .assetImport, .export],
            notes: ["Template starts with an export script instead of assuming a runtime plugin."]
        )
    ]

    public static func list(kind: GameIntegrationKind? = nil, ids: [String] = []) throws -> [GameIntegrationDescriptor] {
        let selected: [GameIntegrationDescriptor]
        if ids.isEmpty {
            selected = all
        } else {
            selected = try ids.map { try require(id: $0) }
        }
        if let kind {
            return selected.filter { $0.kind == kind }
        }
        return selected
    }

    public static func require(id: String) throws -> GameIntegrationDescriptor {
        let normalized = normalize(id)
        guard let descriptor = all.first(where: { $0.id == normalized }) else {
            throw GameHarnessError.integrationNotFound(id)
        }
        return descriptor
    }

    private static func normalize(_ id: String) -> String {
        let lowered = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let aliases = [
            "three": "threejs",
            "three.js": "threejs",
            "web-gpu": "webgpu",
            "uefn": "fortnite-uefn",
            "fortnite": "fortnite-uefn",
            "3ds": "3ds-max",
            "3dsmax": "3ds-max",
            "autodesk-3ds-max": "3ds-max"
        ]
        return aliases[lowered] ?? lowered
    }
}
