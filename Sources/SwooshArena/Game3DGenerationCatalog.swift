// SwooshArena/Game3DGenerationCatalog.swift — Cartridge 3D generation provider catalog (0.1A)

import Foundation

public enum Game3DProviderDeployment: String, Codable, Sendable, CaseIterable {
    case cloudAPI
    case openSource
    case localHostable
    case assetLibrary
    case assetProcessing
}

public enum Game3DGenerationCapability: String, Codable, Sendable, CaseIterable {
    case textTo3D
    case imageTo3D
    case multiViewTo3D
    case textureGeneration
    case pbrMaterials
    case rigging
    case retopology
    case lodGeneration
    case assetSearch
    case formatConversion
    case validation
}

public struct Game3DModelDescriptor: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let providerID: String
    public let deployment: Game3DProviderDeployment
    public let capabilities: [Game3DGenerationCapability]
    public let supportsTextInput: Bool
    public let supportsImageInput: Bool
    public let outputFormats: [GameExportFormat]
    public let license: String
    public let localRequirements: [String]
    public let recommendedFor: [String]
    public let sourceURLs: [String]
}

public struct Game3DProviderDescriptor: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let deployment: Game3DProviderDeployment
    public let websiteURL: String
    public let capabilities: [Game3DGenerationCapability]
    public let requiredSecretNames: [String]
    public let defaultOutputFormats: [GameExportFormat]
    public let integrationIDs: [String]
    public let models: [Game3DModelDescriptor]
    public let strengths: [String]
    public let limitations: [String]
    public let sourceURLs: [String]

    public var hasLocalHostableModel: Bool {
        deployment == .localHostable || models.contains { $0.deployment == .localHostable }
    }
}

public enum Game3DGenerationCatalog {
    public static let all: [Game3DProviderDescriptor] = cloudProviders + localProviders + assetProviders

    public static func list(
        deployment: Game3DProviderDeployment? = nil,
        ids: [String] = [],
        localHostableOnly: Bool? = nil,
        supportsTextInput: Bool? = nil,
        supportsImageInput: Bool? = nil,
        capability: Game3DGenerationCapability? = nil
    ) throws -> [Game3DProviderDescriptor] {
        let selected = ids.isEmpty ? all : try ids.map { try require(id: $0) }
        return selected.filter { provider in
            if let deployment, provider.deployment != deployment { return false }
            if localHostableOnly == true, !provider.hasLocalHostableModel { return false }
            if let supportsTextInput, !provider.models.isEmpty, !provider.models.contains(where: { $0.supportsTextInput == supportsTextInput }) { return false }
            if let supportsImageInput, !provider.models.isEmpty, !provider.models.contains(where: { $0.supportsImageInput == supportsImageInput }) { return false }
            if let capability, !provider.capabilities.contains(capability) { return false }
            return true
        }
    }

    public static func require(id: String) throws -> Game3DProviderDescriptor {
        let normalized = normalize(id)
        guard let descriptor = all.first(where: { normalize($0.id) == normalized }) else {
            throw GameHarnessError.threeDProviderNotFound(id)
        }
        return descriptor
    }

    static func makeProvider(
        id: String,
        displayName: String,
        deployment: Game3DProviderDeployment,
        websiteURL: String,
        capabilities: [Game3DGenerationCapability],
        requiredSecretNames: [String],
        defaultOutputFormats: [GameExportFormat],
        integrationIDs: [String],
        models: [Game3DModelDescriptor],
        strengths: [String],
        limitations: [String],
        sourceURLs: [String]
    ) -> Game3DProviderDescriptor {
        Game3DProviderDescriptor(
            id: id,
            displayName: displayName,
            deployment: deployment,
            websiteURL: websiteURL,
            capabilities: capabilities,
            requiredSecretNames: requiredSecretNames,
            defaultOutputFormats: defaultOutputFormats,
            integrationIDs: integrationIDs,
            models: models,
            strengths: strengths,
            limitations: limitations,
            sourceURLs: sourceURLs
        )
    }

    static func makeModel(
        id: String,
        displayName: String,
        providerID: String,
        deployment: Game3DProviderDeployment,
        capabilities: [Game3DGenerationCapability],
        supportsTextInput: Bool,
        supportsImageInput: Bool,
        outputFormats: [GameExportFormat],
        license: String,
        localRequirements: [String] = [],
        recommendedFor: [String],
        sourceURLs: [String]
    ) -> Game3DModelDescriptor {
        Game3DModelDescriptor(
            id: id,
            displayName: displayName,
            providerID: providerID,
            deployment: deployment,
            capabilities: capabilities,
            supportsTextInput: supportsTextInput,
            supportsImageInput: supportsImageInput,
            outputFormats: outputFormats,
            license: license,
            localRequirements: localRequirements,
            recommendedFor: recommendedFor,
            sourceURLs: sourceURLs
        )
    }

    static func normalize(_ id: String) -> String {
        id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
