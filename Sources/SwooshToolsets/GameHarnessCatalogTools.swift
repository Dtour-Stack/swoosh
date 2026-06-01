// SwooshToolsets/GameHarnessCatalogTools.swift — Cartridge provider catalog tools (0.1A)

import Foundation
import SwooshArena
import SwooshTools

public struct GameList3DGenerationProvidersTool: SwooshTool {
    public struct Input: Codable, Sendable {
        public let deployment: Game3DProviderDeployment?
        public let ids: [String]?
        public let localHostableOnly: Bool?
        public let supportsTextInput: Bool?
        public let supportsImageInput: Bool?
        public let capability: Game3DGenerationCapability?
    }

    public struct Output: Codable, Sendable {
        public let agentName: String
        public let providers: [Game3DProviderDescriptor]
    }

    public static let name: ToolName = "game.list_3d_generation_providers"
    public static let displayName = "List 3D Generation Providers"
    public static let description = "List Cartridge 3D model generation, local-hostable model, asset library, and mesh-processing providers."
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
        let providers = try Game3DGenerationCatalog.list(
            deployment: input.deployment,
            ids: input.ids ?? [],
            localHostableOnly: input.localHostableOnly,
            supportsTextInput: input.supportsTextInput,
            supportsImageInput: input.supportsImageInput,
            capability: input.capability
        )
        return Output(agentName: CartridgeDefaults.agentName, providers: providers)
    }
}

public struct GameList2DCreationProvidersTool: SwooshTool {
    public struct Input: Codable, Sendable {
        public let deployment: Game2DProviderDeployment?
        public let ids: [String]?
        public let localRunnableOnly: Bool?
        public let supportsTextInput: Bool?
        public let supportsImageInput: Bool?
        public let capability: Game2DCreationCapability?
    }

    public struct Output: Codable, Sendable {
        public let agentName: String
        public let providers: [Game2DProviderDescriptor]
    }

    public static let name: ToolName = "game.list_2d_creation_providers"
    public static let displayName = "List 2D Creation Providers"
    public static let description = "List Cartridge 2D game-art providers for sprites, tiles, parallax backgrounds, outpainting, local editors, and atlas export."
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
        let providers = try Game2DCreationCatalog.list(
            deployment: input.deployment,
            ids: input.ids ?? [],
            localRunnableOnly: input.localRunnableOnly,
            supportsTextInput: input.supportsTextInput,
            supportsImageInput: input.supportsImageInput,
            capability: input.capability
        )
        return Output(agentName: CartridgeDefaults.agentName, providers: providers)
    }
}
