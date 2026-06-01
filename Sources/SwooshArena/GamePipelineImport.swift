// SwooshArena/GamePipelineImport.swift — Pipeline graph import bridge (0.1C)

import Foundation
import SwooshTools

public struct GamePipelineImportDocument: Codable, Sendable, Equatable {
    public let id: String?
    public let name: String?
    public let description: String?
    public let version: String?
    public let nodes: [GamePipelineImportNode]
    public let edges: [GamePipelineImportEdge]

    public init(
        id: String? = nil,
        name: String? = nil,
        description: String? = nil,
        version: String? = nil,
        nodes: [GamePipelineImportNode],
        edges: [GamePipelineImportEdge]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
        self.nodes = nodes
        self.edges = edges
    }

    public func pipeline(defaultName: String) throws -> GamePipeline {
        guard !nodes.isEmpty else {
            throw GameHarnessError.emptyPipeline
        }
        let nodeIDs = nodes.map(\.id)
        guard Set(nodeIDs).count == nodeIDs.count else {
            throw GameHarnessError.invalidPipelineImport("duplicate node id")
        }
        let idSet = Set(nodeIDs)
        let importedNodes = try nodes.map { try $0.pipelineNode(sourceVersion: version) }
        let importedEdges = try edges.map { edge in
            guard idSet.contains(edge.source) else {
                throw GameHarnessError.invalidPipelineImport("missing edge source \(edge.source)")
            }
            guard idSet.contains(edge.target) else {
                throw GameHarnessError.invalidPipelineImport("missing edge target \(edge.target)")
            }
            return GamePipelineEdge(
                id: edge.id ?? "\(edge.source)-\(edge.target)",
                sourceNodeID: edge.source,
                targetNodeID: edge.target
            )
        }
        return try GamePipeline(
            id: id ?? UUID().uuidString,
            name: name ?? defaultName,
            nodes: importedNodes,
            edges: importedEdges
        )
    }
}

public struct GamePipelineImportNode: Codable, Sendable, Equatable {
    public let id: String
    public let type: String?
    public let data: JSONValue?
    public let position: JSONValue?

    public init(id: String, type: String? = nil, data: JSONValue? = nil, position: JSONValue? = nil) {
        self.id = id
        self.type = type
        self.data = data
        self.position = position
    }

    fileprivate func pipelineNode(sourceVersion: String?) throws -> GamePipelineNode {
        let kind = try GamePipelineImportNodeKindMapper.kind(for: type)
        return GamePipelineNode(
            id: id,
            kind: kind,
            title: title,
            config: config(sourceVersion: sourceVersion)
        )
    }

    private var title: String {
        if let label = data?.stringValue(for: "label") {
            return label
        }
        if let title = data?.stringValue(for: "title") {
            return title
        }
        if let name = data?.stringValue(for: "name") {
            return name
        }
        return type ?? id
    }

    private func config(sourceVersion: String?) -> JSONValue {
        var object: [String: JSONValue] = [:]
        if let type {
            object["sourceType"] = .string(type)
        }
        if let sourceVersion {
            object["sourceVersion"] = .string(sourceVersion)
        }
        if let data {
            object["data"] = data
        }
        if let position {
            object["position"] = position
        }
        return .object(object)
    }
}

public struct GamePipelineImportEdge: Codable, Sendable, Equatable {
    public let id: String?
    public let source: String
    public let target: String

    public init(id: String? = nil, source: String, target: String) {
        self.id = id
        self.source = source
        self.target = target
    }
}

private enum GamePipelineImportNodeKindMapper {
    static func kind(for type: String?) throws -> GamePipelineNodeKind {
        guard let type, !type.isEmpty else {
            throw GameHarnessError.invalidPipelineImport("missing node type")
        }
        switch normalized(type) {
        case "trigger":
            return .trigger
        case "ingest":
            return .ingest
        case "contextprovider", "provider":
            return .contextProvider
        case "aigeneration", "generate", "generation":
            return .aiGeneration
        case "charactergeneration", "npcgeneration":
            return .characterGeneration
        case "assetgeneration":
            return .assetGeneration
        case "assetimport":
            return .assetImport
        case "voiceconfig", "voiceconfiguration":
            return .voiceConfig
        case "simulation":
            return .simulation
        case "render":
            return .render
        case "physics":
            return .physics
        case "engineadapter":
            return .engineAdapter
        case "runtimescaffold", "scaffold":
            return .runtimeScaffold
        case "pluginbridge":
            return .pluginBridge
        case "telemetry":
            return .telemetry
        case "playtest":
            return .playtest
        case "evaluator", "evaluation":
            return .evaluator
        case "conditional", "condition":
            return .conditional
        case "export":
            return .export
        default:
            throw GameHarnessError.unsupportedPipelineNodeType(type)
        }
    }

    private static func normalized(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}

private extension JSONValue {
    func stringValue(for key: String) -> String? {
        guard case .object(let object) = self, case .string(let value)? = object[key], !value.isEmpty else {
            return nil
        }
        return value
    }
}
