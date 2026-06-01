// SwooshArena/Game2DCreationCatalog.swift — Cartridge 2D creation provider catalog (0.1A)

import Foundation

public enum Game2DProviderDeployment: String, Codable, Sendable, CaseIterable {
    case cloudAPI
    case localHostable
    case openSource
    case runtimeLibrary
    case assetPipeline
    case assetProcessing
}

public enum Game2DCreationCapability: String, Codable, Sendable, CaseIterable {
    case textToSprite
    case imageToSprite
    case imageEditing
    case styleReference
    case characterConsistency
    case spriteSheetGeneration
    case frameAnimation
    case framePlayback
    case pixelEditing
    case layerEditing
    case paletteControl
    case transparentSprites
    case backgroundRemoval
    case imageExtension
    case outpainting
    case parallaxBackgrounds
    case autotileGeneration
    case tilemapEditing
    case propGeneration
    case particleFX
    case hitboxEditing
    case rigging2D
    case stateMachineEditing
    case exportPackaging
    case qaValidation
    case localFirst
}

public enum Game2DAssetInputKind: String, Codable, Sendable, CaseIterable {
    case textPrompt
    case referenceImage
    case styleImage
    case existingImage
    case spriteSheet
    case frameGrid
    case localCanvas
    case structuralGuide
    case mask
}

public struct Game2DWorkflowDescriptor: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let providerID: String
    public let deployment: Game2DProviderDeployment
    public let capabilities: [Game2DCreationCapability]
    public let inputKinds: [Game2DAssetInputKind]
    public let outputFormats: [GameExportFormat]
    public let recommendedFor: [String]
    public let sourceURLs: [String]
    public let notes: [String]
}

public struct Game2DProviderDescriptor: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let deployment: Game2DProviderDeployment
    public let websiteURL: String
    public let capabilities: [Game2DCreationCapability]
    public let requiredSecretNames: [String]
    public let defaultOutputFormats: [GameExportFormat]
    public let integrationIDs: [String]
    public let workflows: [Game2DWorkflowDescriptor]
    public let strengths: [String]
    public let limitations: [String]
    public let sourceURLs: [String]

    public var hasLocalRunnableWorkflow: Bool {
        deployment == .localHostable || deployment == .openSource || deployment == .runtimeLibrary ||
            workflows.contains { $0.deployment == .localHostable || $0.deployment == .openSource || $0.deployment == .runtimeLibrary }
    }

    public var supportsTextInput: Bool {
        workflows.contains { $0.inputKinds.contains(.textPrompt) }
    }

    public var supportsImageInput: Bool {
        workflows.contains {
            !$0.inputKinds.filter { input in
                input == .referenceImage || input == .styleImage || input == .existingImage || input == .spriteSheet || input == .frameGrid || input == .mask
            }.isEmpty
        }
    }
}

public enum Game2DCreationCatalog {
    public static let all: [Game2DProviderDescriptor] = cloudProviders + localProviders + editorProviders

    public static func list(
        deployment: Game2DProviderDeployment? = nil,
        ids: [String] = [],
        localRunnableOnly: Bool? = nil,
        supportsTextInput: Bool? = nil,
        supportsImageInput: Bool? = nil,
        capability: Game2DCreationCapability? = nil
    ) throws -> [Game2DProviderDescriptor] {
        let selected = ids.isEmpty ? all : try ids.map { try require(id: $0) }
        return selected.filter { provider in
            if let deployment, provider.deployment != deployment { return false }
            if localRunnableOnly == true, !provider.hasLocalRunnableWorkflow { return false }
            if let supportsTextInput, provider.supportsTextInput != supportsTextInput { return false }
            if let supportsImageInput, provider.supportsImageInput != supportsImageInput { return false }
            if let capability, !provider.capabilities.contains(capability) { return false }
            return true
        }
    }

    public static func require(id: String) throws -> Game2DProviderDescriptor {
        let normalized = normalize(id)
        guard let descriptor = all.first(where: { normalize($0.id) == normalized }) else {
            throw GameHarnessError.twoDProviderNotFound(id)
        }
        return descriptor
    }

    static func makeProvider(
        id: String,
        displayName: String,
        deployment: Game2DProviderDeployment,
        websiteURL: String,
        capabilities: [Game2DCreationCapability],
        requiredSecretNames: [String],
        defaultOutputFormats: [GameExportFormat],
        integrationIDs: [String],
        workflows: [Game2DWorkflowDescriptor],
        strengths: [String],
        limitations: [String],
        sourceURLs: [String]
    ) -> Game2DProviderDescriptor {
        Game2DProviderDescriptor(
            id: id,
            displayName: displayName,
            deployment: deployment,
            websiteURL: websiteURL,
            capabilities: capabilities,
            requiredSecretNames: requiredSecretNames,
            defaultOutputFormats: defaultOutputFormats,
            integrationIDs: integrationIDs,
            workflows: workflows,
            strengths: strengths,
            limitations: limitations,
            sourceURLs: sourceURLs
        )
    }

    static func makeWorkflow(
        id: String,
        displayName: String,
        providerID: String,
        deployment: Game2DProviderDeployment,
        capabilities: [Game2DCreationCapability],
        inputKinds: [Game2DAssetInputKind],
        outputFormats: [GameExportFormat],
        recommendedFor: [String],
        sourceURLs: [String],
        notes: [String] = []
    ) -> Game2DWorkflowDescriptor {
        Game2DWorkflowDescriptor(
            id: id,
            displayName: displayName,
            providerID: providerID,
            deployment: deployment,
            capabilities: capabilities,
            inputKinds: inputKinds,
            outputFormats: outputFormats,
            recommendedFor: recommendedFor,
            sourceURLs: sourceURLs,
            notes: notes
        )
    }

    static func normalize(_ id: String) -> String {
        id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
