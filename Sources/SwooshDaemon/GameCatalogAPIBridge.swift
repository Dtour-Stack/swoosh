// SwooshDaemon/GameCatalogAPIBridge.swift — 0.1A Cartridge creation catalog ↔ HTTP API

import Foundation
import SwooshArena
import SwooshClient

extension SwooshDaemon {
    static func gameCreationCatalogResponse() -> GameCreationCatalogResponse {
        let pipelines = try! GamePipelineTemplateCatalog.list()
        return GameCreationCatalogResponse(
            agentName: CartridgeDefaults.agentName,
            integrations: GameIntegrationCatalog.all.map(gameIntegrationSummary),
            cliStarters: GameCLIStarterCatalog.all.map(gameCLIStarterSummary),
            twoD: Game2DCreationCatalog.all.map(game2DProviderSummary),
            threeD: Game3DGenerationCatalog.all.map(game3DProviderSummary),
            pipelines: pipelines.map(gamePipelineTemplateSummary)
        )
    }

    static func gameIntegrationSummary(_ integration: GameIntegrationDescriptor) -> GameIntegrationSummary {
        GameIntegrationSummary(
            id: integration.id,
            displayName: integration.displayName,
            kind: integration.kind.rawValue,
            capabilities: integration.capabilities.map(\.rawValue),
            supportedModes: integration.supportedModes.map(\.rawValue),
            exportFormats: integration.exportFormats.map(\.rawValue),
            pluginSurfaces: integration.pluginSurfaces,
            localURLPatterns: integration.localURLPatterns,
            pipelineNodeKinds: integration.pipelineNodeKinds.map(\.rawValue),
            notes: integration.notes
        )
    }

    static func gameCLIStarterSummary(_ starter: GameCLIStarterDescriptor) -> GameCLIStarterSummary {
        GameCLIStarterSummary(
            id: starter.id,
            displayName: starter.displayName,
            kind: starter.kind.rawValue,
            capabilities: starter.capabilities.map(\.rawValue),
            inputModalities: starter.inputModalities.map(\.rawValue),
            outputFiles: starter.outputFiles,
            commandGroups: starter.commandGroups,
            recommendedFor: starter.recommendedFor,
            sourceInspirations: starter.sourceInspirations,
            notes: starter.notes
        )
    }

    static func game2DProviderSummary(_ provider: Game2DProviderDescriptor) -> GameAssetProviderSummary {
        GameAssetProviderSummary(
            id: provider.id,
            displayName: provider.displayName,
            dimension: "2d",
            deployment: provider.deployment.rawValue,
            websiteURL: provider.websiteURL,
            capabilities: provider.capabilities.map(\.rawValue),
            requiredSecretNames: provider.requiredSecretNames,
            defaultOutputFormats: provider.defaultOutputFormats.map(\.rawValue),
            integrationIDs: provider.integrationIDs,
            workflows: provider.workflows.map(game2DWorkflowSummary),
            strengths: provider.strengths,
            limitations: provider.limitations,
            sourceURLs: provider.sourceURLs
        )
    }

    static func game2DWorkflowSummary(_ workflow: Game2DWorkflowDescriptor) -> GameAssetWorkflowSummary {
        GameAssetWorkflowSummary(
            id: workflow.id,
            displayName: workflow.displayName,
            providerID: workflow.providerID,
            deployment: workflow.deployment.rawValue,
            capabilities: workflow.capabilities.map(\.rawValue),
            inputKinds: workflow.inputKinds.map(\.rawValue),
            outputFormats: workflow.outputFormats.map(\.rawValue),
            recommendedFor: workflow.recommendedFor,
            sourceURLs: workflow.sourceURLs,
            notes: workflow.notes
        )
    }

    static func game3DProviderSummary(_ provider: Game3DProviderDescriptor) -> GameAssetProviderSummary {
        GameAssetProviderSummary(
            id: provider.id,
            displayName: provider.displayName,
            dimension: "3d",
            deployment: provider.deployment.rawValue,
            websiteURL: provider.websiteURL,
            capabilities: provider.capabilities.map(\.rawValue),
            requiredSecretNames: provider.requiredSecretNames,
            defaultOutputFormats: provider.defaultOutputFormats.map(\.rawValue),
            integrationIDs: provider.integrationIDs,
            workflows: provider.models.map(game3DModelSummary),
            strengths: provider.strengths,
            limitations: provider.limitations,
            sourceURLs: provider.sourceURLs
        )
    }

    static func game3DModelSummary(_ model: Game3DModelDescriptor) -> GameAssetWorkflowSummary {
        var inputKinds: [String] = []
        if model.supportsTextInput { inputKinds.append("textPrompt") }
        if model.supportsImageInput { inputKinds.append("referenceImage") }
        return GameAssetWorkflowSummary(
            id: model.id,
            displayName: model.displayName,
            providerID: model.providerID,
            deployment: model.deployment.rawValue,
            capabilities: model.capabilities.map(\.rawValue),
            inputKinds: inputKinds,
            outputFormats: model.outputFormats.map(\.rawValue),
            recommendedFor: model.recommendedFor,
            sourceURLs: model.sourceURLs,
            notes: [model.license] + model.localRequirements
        )
    }

    static func gamePipelineTemplateSummary(_ pipeline: GamePipeline) -> GamePipelineTemplateSummary {
        GamePipelineTemplateSummary(
            id: pipeline.id,
            name: pipeline.name,
            nodeCount: pipeline.nodes.count,
            edgeCount: pipeline.edges.count,
            integrationIDs: GamePipelineTemplateCatalog.integrationIDs(for: pipeline.id)
        )
    }
}
