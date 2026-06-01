// SwooshClient/WireTypes+Game.swift — 0.1A Cartridge creation catalog wire types

import Foundation

public struct GameCreationCatalogResponse: Codable, Sendable, Equatable {
    public let agentName: String
    public let integrations: [GameIntegrationSummary]
    public let cliStarters: [GameCLIStarterSummary]
    public let twoD: [GameAssetProviderSummary]
    public let threeD: [GameAssetProviderSummary]
    public let pipelines: [GamePipelineTemplateSummary]
    public let generatedAt: Date

    public init(
        agentName: String,
        integrations: [GameIntegrationSummary],
        cliStarters: [GameCLIStarterSummary],
        twoD: [GameAssetProviderSummary],
        threeD: [GameAssetProviderSummary],
        pipelines: [GamePipelineTemplateSummary],
        generatedAt: Date = Date()
    ) {
        self.agentName = agentName
        self.integrations = integrations
        self.cliStarters = cliStarters
        self.twoD = twoD
        self.threeD = threeD
        self.pipelines = pipelines
        self.generatedAt = generatedAt
    }
}

public struct GameIntegrationSummary: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let kind: String
    public let capabilities: [String]
    public let supportedModes: [String]
    public let exportFormats: [String]
    public let pluginSurfaces: [String]
    public let localURLPatterns: [String]
    public let pipelineNodeKinds: [String]
    public let notes: [String]

    public init(
        id: String,
        displayName: String,
        kind: String,
        capabilities: [String],
        supportedModes: [String],
        exportFormats: [String],
        pluginSurfaces: [String],
        localURLPatterns: [String],
        pipelineNodeKinds: [String],
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

public struct GameCLIStarterSummary: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let kind: String
    public let capabilities: [String]
    public let inputModalities: [String]
    public let outputFiles: [String]
    public let commandGroups: [String]
    public let recommendedFor: [String]
    public let sourceInspirations: [String]
    public let notes: [String]

    public init(
        id: String,
        displayName: String,
        kind: String,
        capabilities: [String],
        inputModalities: [String],
        outputFiles: [String],
        commandGroups: [String],
        recommendedFor: [String],
        sourceInspirations: [String],
        notes: [String]
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.capabilities = capabilities
        self.inputModalities = inputModalities
        self.outputFiles = outputFiles
        self.commandGroups = commandGroups
        self.recommendedFor = recommendedFor
        self.sourceInspirations = sourceInspirations
        self.notes = notes
    }
}

public struct GameAssetProviderSummary: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let dimension: String
    public let deployment: String
    public let websiteURL: String
    public let capabilities: [String]
    public let requiredSecretNames: [String]
    public let defaultOutputFormats: [String]
    public let integrationIDs: [String]
    public let workflows: [GameAssetWorkflowSummary]
    public let strengths: [String]
    public let limitations: [String]
    public let sourceURLs: [String]

    public init(
        id: String,
        displayName: String,
        dimension: String,
        deployment: String,
        websiteURL: String,
        capabilities: [String],
        requiredSecretNames: [String],
        defaultOutputFormats: [String],
        integrationIDs: [String],
        workflows: [GameAssetWorkflowSummary],
        strengths: [String],
        limitations: [String],
        sourceURLs: [String]
    ) {
        self.id = id
        self.displayName = displayName
        self.dimension = dimension
        self.deployment = deployment
        self.websiteURL = websiteURL
        self.capabilities = capabilities
        self.requiredSecretNames = requiredSecretNames
        self.defaultOutputFormats = defaultOutputFormats
        self.integrationIDs = integrationIDs
        self.workflows = workflows
        self.strengths = strengths
        self.limitations = limitations
        self.sourceURLs = sourceURLs
    }
}

public struct GameAssetWorkflowSummary: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let providerID: String
    public let deployment: String
    public let capabilities: [String]
    public let inputKinds: [String]
    public let outputFormats: [String]
    public let recommendedFor: [String]
    public let sourceURLs: [String]
    public let notes: [String]

    public init(
        id: String,
        displayName: String,
        providerID: String,
        deployment: String,
        capabilities: [String],
        inputKinds: [String],
        outputFormats: [String],
        recommendedFor: [String],
        sourceURLs: [String],
        notes: [String] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.providerID = providerID
        self.deployment = deployment
        self.capabilities = capabilities
        self.inputKinds = inputKinds
        self.outputFormats = outputFormats
        self.recommendedFor = recommendedFor
        self.sourceURLs = sourceURLs
        self.notes = notes
    }
}

public struct GamePipelineTemplateSummary: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let nodeCount: Int
    public let edgeCount: Int
    public let integrationIDs: [String]

    public init(id: String, name: String, nodeCount: Int, edgeCount: Int, integrationIDs: [String]) {
        self.id = id
        self.name = name
        self.nodeCount = nodeCount
        self.edgeCount = edgeCount
        self.integrationIDs = integrationIDs
    }
}
