// SwooshArena/GameHarnessTypes.swift — Cartridge game harness domain model (0.1A)

import Foundation
import SwooshTools

public enum CartridgeDefaults {
    public static let agentName = "Cartridge"
    public static let agentSlug = "cartridge"
}

public enum GameURLPolicy {
    public static func validateLocalGameURL(_ urlString: String) throws -> URL {
        guard let url = URL(string: urlString),
              let components = URLComponents(string: urlString),
              let scheme = components.scheme?.lowercased() else {
            throw GameHarnessError.invalidURL(urlString)
        }

        if scheme == "file" {
            return url
        }

        guard scheme == "http" || scheme == "https" else {
            throw GameHarnessError.unsupportedURLScheme(scheme)
        }

        guard let host = components.host?.lowercased() else {
            throw GameHarnessError.invalidURL(urlString)
        }

        let localHosts: Set<String> = ["localhost", "127.0.0.1", "::1", "0.0.0.0"]
        guard localHosts.contains(host) || host.hasSuffix(".localhost") else {
            throw GameHarnessError.nonLocalURL(host)
        }

        return url
    }
}

public enum GameHarnessError: Error, Equatable, Sendable {
    case invalidURL(String)
    case unsupportedURLScheme(String)
    case nonLocalURL(String)
    case sessionNotFound(String)
    case policyNotFound(String)
    case pipelineNotFound(String)
    case integrationNotFound(String)
    case threeDProviderNotFound(String)
    case twoDProviderNotFound(String)
    case templateNotFound(String)
    case emptyPolicySet
    case emptyPipeline
    case invalidProjectTitle(String)
    case invalidScaffoldPath(String)
    case invalidPipelineImport(String)
    case unsupportedPipelineNodeType(String)
    case invalidPolicyInput(String)
    case invalidEvaluationScore(Double)
}

public enum GameHarnessMode: String, Codable, Sendable, CaseIterable {
    case play
    case test
    case create
    case generate
    case train
}

public enum GameHarnessStatus: String, Codable, Sendable, CaseIterable {
    case loaded
    case running
    case paused
    case completed
    case failed
}

public enum GameTargetKind: String, Codable, Sendable, CaseIterable {
    case localURL
    case cloudStream
    case nativeWindow
    case wasmEnvironment
    case generatedGame
}

public struct GameLaunchTarget: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let kind: GameTargetKind
    public let urlString: String?
    public let engineHint: String?
    public let metadata: [String: JSONValue]

    public init(
        id: String = UUID().uuidString,
        title: String,
        kind: GameTargetKind,
        urlString: String? = nil,
        engineHint: String? = nil,
        metadata: [String: JSONValue] = [:]
    ) throws {
        if kind == .localURL, let urlString {
            _ = try GameURLPolicy.validateLocalGameURL(urlString)
        }
        self.id = id
        self.title = title
        self.kind = kind
        self.urlString = urlString
        self.engineHint = engineHint
        self.metadata = metadata
    }
}

public enum GamePolicyKind: String, Codable, Sendable, CaseIterable {
    case nitroGen
    case providerLLM
    case hybrid
    case scripted
}

public struct GamePolicyDescriptor: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let kind: GamePolicyKind
    public let providerID: String?
    public let modelID: String?
    public let responsibilities: [String]
    public let usesNitroGen: Bool

    public init(
        id: String = UUID().uuidString,
        displayName: String,
        kind: GamePolicyKind,
        providerID: String? = nil,
        modelID: String? = nil,
        responsibilities: [String],
        usesNitroGen: Bool
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.providerID = providerID
        self.modelID = modelID
        self.responsibilities = responsibilities
        self.usesNitroGen = usesNitroGen
    }

    public static let nitroGen = GamePolicyDescriptor(
        id: "nitrogen",
        displayName: "NitroGen",
        kind: .nitroGen,
        responsibilities: ["frame_action"],
        usesNitroGen: true
    )

    public static func providerLLM(providerID: String, modelID: String) -> GamePolicyDescriptor {
        GamePolicyDescriptor(
            id: "llm.\(providerID).\(modelID)",
            displayName: "\(providerID) \(modelID)",
            kind: .providerLLM,
            providerID: providerID,
            modelID: modelID,
            responsibilities: ["reasoning", "menu_navigation", "content_generation", "test_oracle"],
            usesNitroGen: false
        )
    }

    public static func hybrid(providerID: String, modelID: String) -> GamePolicyDescriptor {
        GamePolicyDescriptor(
            id: "hybrid.\(providerID).\(modelID).nitrogen",
            displayName: "\(providerID) \(modelID) + NitroGen",
            kind: .hybrid,
            providerID: providerID,
            modelID: modelID,
            responsibilities: ["reasoning", "menu_navigation", "frame_action", "test_oracle"],
            usesNitroGen: true
        )
    }
}

public enum GameActionKind: String, Codable, Sendable, CaseIterable {
    case move
    case interact
    case attack
    case useItem
    case speak
    case questAction
    case inventoryAction
    case wait
    case keyboard
    case mouse
    case gamepad
    case menuNavigate
    case generateContent
    case evaluate
}

public struct GameAction: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let kind: GameActionKind
    public let policyID: String
    public let parameters: JSONValue
    public let issuedAt: Date

    public init(
        id: String = UUID().uuidString,
        kind: GameActionKind,
        policyID: String,
        parameters: JSONValue,
        issuedAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.policyID = policyID
        self.parameters = parameters
        self.issuedAt = issuedAt
    }
}

public struct GameObservation: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let summary: String
    public let state: JSONValue
    public let frameReference: String?
    public let events: [String]
    public let observedAt: Date

    public init(
        id: String = UUID().uuidString,
        summary: String,
        state: JSONValue = .object([:]),
        frameReference: String? = nil,
        events: [String] = [],
        observedAt: Date = Date()
    ) {
        self.id = id
        self.summary = summary
        self.state = state
        self.frameReference = frameReference
        self.events = events
        self.observedAt = observedAt
    }
}

public struct GameTrajectoryStep: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let index: Int
    public let observation: GameObservation
    public let action: GameAction?
    public let reward: Double
    public let done: Bool
    public let recordedAt: Date

    public init(
        id: String = UUID().uuidString,
        index: Int,
        observation: GameObservation,
        action: GameAction?,
        reward: Double,
        done: Bool,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.index = index
        self.observation = observation
        self.action = action
        self.reward = reward
        self.done = done
        self.recordedAt = recordedAt
    }
}

public enum GameArtifactKind: String, Codable, Sendable, CaseIterable {
    case character
    case npc
    case dialogue
    case quest
    case lore
    case item
    case asset2D
    case asset3D
    case audio
    case script
    case testReport
    case contentPack
}

public enum GameExportFormat: String, Codable, Sendable, CaseIterable {
    case json
    case png
    case gif
    case apng
    case spriteSheet
    case aseprite
    case texturePacker
    case tiled
    case phaser
    case defold
    case typescript
    case csharp
    case cpp
    case lua
    case python
    case verse
    case mcfunction
    case unity
    case unreal
    case godot
    case elizaOS
    case roblox
    case fortniteUEFN
    case minecraft
    case blender
    case threeDSMax
    case threejs
    case webgpu
    case glb
    case gltf
    case usd
    case fbx
    case obj
    case usdz
    case stl
    case ply
    case threeMF = "3mf"
}

public struct GameContentArtifact: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let kind: GameArtifactKind
    public let title: String
    public let body: JSONValue
    public let exportFormats: [GameExportFormat]
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        kind: GameArtifactKind,
        title: String,
        body: JSONValue,
        exportFormats: [GameExportFormat],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.exportFormats = exportFormats
        self.createdAt = createdAt
    }
}

public enum GamePipelineNodeKind: String, Codable, Sendable, CaseIterable {
    case trigger
    case ingest
    case contextProvider
    case aiGeneration
    case characterGeneration
    case assetGeneration
    case assetImport
    case assetProcessing
    case voiceConfig
    case simulation
    case render
    case physics
    case engineAdapter
    case runtimeScaffold
    case pluginBridge
    case telemetry
    case playtest
    case evaluator
    case conditional
    case export
}

public struct GamePipelineNode: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let kind: GamePipelineNodeKind
    public let title: String
    public let config: JSONValue

    public init(id: String = UUID().uuidString, kind: GamePipelineNodeKind, title: String, config: JSONValue = .object([:])) {
        self.id = id
        self.kind = kind
        self.title = title
        self.config = config
    }
}

public struct GamePipelineEdge: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let sourceNodeID: String
    public let targetNodeID: String

    public init(id: String = UUID().uuidString, sourceNodeID: String, targetNodeID: String) {
        self.id = id
        self.sourceNodeID = sourceNodeID
        self.targetNodeID = targetNodeID
    }
}

public struct GamePipeline: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let nodes: [GamePipelineNode]
    public let edges: [GamePipelineEdge]
    public let createdAt: Date

    public init(id: String = UUID().uuidString, name: String, nodes: [GamePipelineNode], edges: [GamePipelineEdge], createdAt: Date = Date()) throws {
        guard !nodes.isEmpty else { throw GameHarnessError.emptyPipeline }
        self.id = id
        self.name = name
        self.nodes = nodes
        self.edges = edges
        self.createdAt = createdAt
    }
}
