// SwooshToolsets/GameHarnessTools.swift — Cartridge game harness tools (0.1A)

import Foundation
import SwooshArena
import SwooshTools

public struct GameHarnessToolDependencies: Sendable {
    public let harness: CartridgeHarness
    public let firewall: any Firewall

    public init(harness: CartridgeHarness = CartridgeHarness(), firewall: any Firewall) {
        self.harness = harness
        self.firewall = firewall
    }
}

public struct GamePolicyInput: Codable, Sendable, Equatable {
    public let id: String
    public let displayName: String
    public let kind: GamePolicyKind
    public let providerID: String?
    public let modelID: String?
    public let responsibilities: [String]
    public let usesNitroGen: Bool

    func descriptor() throws -> GamePolicyDescriptor {
        switch kind {
        case .nitroGen:
            return .nitroGen
        case .providerLLM, .hybrid:
            guard let providerID, !providerID.isEmpty else {
                throw GameHarnessError.invalidPolicyInput("providerID")
            }
            guard let modelID, !modelID.isEmpty else {
                throw GameHarnessError.invalidPolicyInput("modelID")
            }
            return GamePolicyDescriptor(
                id: id,
                displayName: displayName,
                kind: kind,
                providerID: providerID,
                modelID: modelID,
                responsibilities: responsibilities,
                usesNitroGen: usesNitroGen
            )
        case .scripted:
            guard !id.isEmpty else {
                throw GameHarnessError.invalidPolicyInput("id")
            }
            guard !displayName.isEmpty else {
                throw GameHarnessError.invalidPolicyInput("displayName")
            }
            return GamePolicyDescriptor(
                id: id,
                displayName: displayName,
                kind: kind,
                providerID: providerID,
                modelID: modelID,
                responsibilities: responsibilities,
                usesNitroGen: usesNitroGen
            )
        }
    }
}

private func encodedGameJSONValue<T: Encodable>(_ value: T) throws -> JSONValue {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(JSONValue.self, from: data)
}

public struct GameListSessionsTool: SwooshTool {
    public struct Input: Codable, Sendable {}
    public struct Output: Codable, Sendable {
        public let agentName: String
        public let sessions: [GameHarnessSession]
    }

    public static let name: ToolName = "game.list_sessions"
    public static let displayName = "List Game Sessions"
    public static let description = "List Cartridge game harness sessions."
    public static let permission = SwooshPermission.gameObserve
    public static let risk = ToolRisk.readOnly
    public static let approval = ApprovalPolicy.never
    public static let toolset = ToolsetID.gaming

    private let dependencies: GameHarnessToolDependencies

    public init(dependencies: GameHarnessToolDependencies) {
        self.dependencies = dependencies
    }

    public func call(_ input: Input, context: ToolContext) async throws -> Output {
        try await dependencies.firewall.require(.gameObserve)
        return Output(agentName: CartridgeDefaults.agentName, sessions: try await dependencies.harness.listSessions())
    }
}

public struct GameListIntegrationsTool: SwooshTool {
    public struct Input: Codable, Sendable {
        public let kind: GameIntegrationKind?
        public let ids: [String]?
    }

    public struct Output: Codable, Sendable {
        public let agentName: String
        public let integrations: [GameIntegrationDescriptor]
    }

    public static let name: ToolName = "game.list_integrations"
    public static let displayName = "List Game Integrations"
    public static let description = "List Cartridge engine, DCC, UGC, web runtime, and modding integrations."
    public static let permission = SwooshPermission.gameObserve
    public static let risk = ToolRisk.readOnly
    public static let approval = ApprovalPolicy.never
    public static let toolset = ToolsetID.gaming

    private let dependencies: GameHarnessToolDependencies

    public init(dependencies: GameHarnessToolDependencies) {
        self.dependencies = dependencies
    }

    public func call(_ input: Input, context: ToolContext) async throws -> Output {
        try await dependencies.firewall.require(.gameObserve)
        let integrations: [GameIntegrationDescriptor]
        if let ids = input.ids {
            integrations = try GameIntegrationCatalog.list(kind: input.kind, ids: ids)
        } else {
            integrations = try GameIntegrationCatalog.list(kind: input.kind)
        }
        return Output(agentName: CartridgeDefaults.agentName, integrations: integrations)
    }
}

public struct GameListPipelineTemplatesTool: SwooshTool {
    public struct Input: Codable, Sendable {
        public let integrationID: String?
    }

    public struct Output: Codable, Sendable {
        public let agentName: String
        public let pipelines: [GamePipeline]
    }

    public static let name: ToolName = "game.list_pipeline_templates"
    public static let displayName = "List Game Pipeline Templates"
    public static let description = "List Cartridge pipeline templates for web runtimes, engine plugins, and DCC asset export."
    public static let permission = SwooshPermission.gameObserve
    public static let risk = ToolRisk.readOnly
    public static let approval = ApprovalPolicy.never
    public static let toolset = ToolsetID.gaming

    private let dependencies: GameHarnessToolDependencies

    public init(dependencies: GameHarnessToolDependencies) {
        self.dependencies = dependencies
    }

    public func call(_ input: Input, context: ToolContext) async throws -> Output {
        try await dependencies.firewall.require(.gameObserve)
        let pipelines = try GamePipelineTemplateCatalog.list(integrationID: input.integrationID)
        return Output(agentName: CartridgeDefaults.agentName, pipelines: pipelines)
    }
}

public struct GameLoadLocalURLTool: SwooshTool {
    public struct Input: Codable, Sendable {
        public let title: String
        public let urlString: String
        public let mode: GameHarnessMode
        public let policies: [GamePolicyInput]
    }

    public struct Output: Codable, Sendable {
        public let agentName: String
        public let session: GameHarnessSession
    }

    public static let name: ToolName = "game.load_local_url"
    public static let displayName = "Load Local Game URL"
    public static let description = "Create a Cartridge session for a local file, localhost, or loopback game URL."
    public static let permission = SwooshPermission.gameLoad
    public static let risk = ToolRisk.medium
    public static let approval = ApprovalPolicy.askFirstTime
    public static let toolset = ToolsetID.gaming

    private let dependencies: GameHarnessToolDependencies

    public init(dependencies: GameHarnessToolDependencies) {
        self.dependencies = dependencies
    }

    public func call(_ input: Input, context: ToolContext) async throws -> Output {
        try await dependencies.firewall.require(.gameLoad)
        let url = try GameURLPolicy.validateLocalGameURL(input.urlString)
        guard let scheme = url.scheme?.lowercased() else {
            throw GameHarnessError.invalidURL(input.urlString)
        }
        if scheme == "file" {
            try await dependencies.firewall.require(.fileRead)
        } else {
            try await dependencies.firewall.require(.networkAccess)
        }
        let policies = try input.policies.map { try $0.descriptor() }
        let session = try await dependencies.harness.loadLocalURL(
            title: input.title,
            urlString: input.urlString,
            mode: input.mode,
            policies: policies
        )
        return Output(agentName: CartridgeDefaults.agentName, session: session)
    }
}

public struct GameInitProjectTool: SwooshTool {
    public struct Input: Codable, Sendable {
        public let title: String
        public let template: GameProjectTemplateKind
        public let mode: GameHarnessMode
        public let policies: [GamePolicyInput]
        public let outputDirectory: String?
    }

    public struct Output: Codable, Sendable {
        public let agentName: String
        public let scaffold: GameProjectScaffold
        public let artifact: GameContentArtifact
        public let session: GameHarnessSession
        public let writtenFiles: [String]
    }

    public static let name: ToolName = "game.init_project"
    public static let displayName = "Initialize Game Project"
    public static let description = "Create a generated-game Cartridge session and attach a starter scaffold for a web runtime, engine plugin, DCC bridge, UGC platform, or mod pack."
    public static let permission = SwooshPermission.gameGenerate
    public static let risk = ToolRisk.high
    public static let approval = ApprovalPolicy.askEveryTime
    public static let toolset = ToolsetID.gaming

    private let dependencies: GameHarnessToolDependencies

    public init(dependencies: GameHarnessToolDependencies) {
        self.dependencies = dependencies
    }

    public func call(_ input: Input, context: ToolContext) async throws -> Output {
        try await dependencies.firewall.require(.gameGenerate)
        let scaffold = try GameProjectScaffoldFactory.make(template: input.template, title: input.title)
        let writtenFiles: [String]
        if let outputDirectory = input.outputDirectory {
            try await dependencies.firewall.require(.fileWrite)
            writtenFiles = try write(scaffold: scaffold, to: outputDirectory)
        } else {
            writtenFiles = []
        }
        let policies = try input.policies.map { try $0.descriptor() }
        let session = try await dependencies.harness.createGeneratedGame(
            title: input.title,
            template: input.template,
            mode: input.mode,
            policies: policies
        )
        let artifact = GameContentArtifact(
            kind: .contentPack,
            title: "\(input.title) scaffold",
            body: try encodedGameJSONValue(scaffold),
            exportFormats: scaffoldExportFormats(for: input.template)
        )
        try await dependencies.harness.addArtifact(sessionID: session.id, artifact: artifact)
        for pipeline in scaffold.pipelines {
            try await dependencies.harness.addPipeline(sessionID: session.id, pipeline: pipeline)
        }
        return Output(
            agentName: CartridgeDefaults.agentName,
            scaffold: scaffold,
            artifact: artifact,
            session: try await dependencies.harness.requireSession(id: session.id),
            writtenFiles: writtenFiles
        )
    }

    private func write(scaffold: GameProjectScaffold, to outputDirectory: String) throws -> [String] {
        let root = URL(fileURLWithPath: outputDirectory, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true, attributes: nil)
        var writtenFiles: [String] = []
        for file in scaffold.files {
            let relativePath = try validatedRelativePath(file.path)
            let url = root.appendingPathComponent(relativePath, isDirectory: false)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            try file.body.write(to: url, atomically: true, encoding: .utf8)
            writtenFiles.append(url.path)
        }
        return writtenFiles
    }

    private func validatedRelativePath(_ path: String) throws -> String {
        let pieces = path.split(separator: "/").map(String.init)
        guard !pieces.isEmpty, !path.hasPrefix("/"), !pieces.contains("..") else {
            throw GameHarnessError.invalidScaffoldPath(path)
        }
        return pieces.joined(separator: "/")
    }

    private func scaffoldExportFormats(for template: GameProjectTemplateKind) -> [GameExportFormat] {
        switch template {
        case .threeJS:
            return [.typescript, .threejs, .json]
        case .webGPU:
            return [.typescript, .webgpu, .json]
        case .unityPackage:
            return [.unity, .csharp, .json]
        case .unrealPlugin:
            return [.unreal, .cpp, .json]
        case .blenderAddon:
            return [.blender, .python, .glb]
        case .robloxExperience:
            return [.roblox, .lua, .json]
        case .fortniteUEFN:
            return [.fortniteUEFN, .verse, .json]
        case .minecraftDatapack:
            return [.minecraft, .mcfunction, .json]
        case .threeDSMaxScript:
            return [.threeDSMax, .fbx, .json]
        }
    }
}
