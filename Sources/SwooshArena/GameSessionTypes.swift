// SwooshArena/GameSessionTypes.swift — Cartridge session and evaluation types (0.1B)

import Foundation

public enum GameEvaluatorKind: String, Codable, Sendable, CaseIterable {
    case successPattern
    case mistakeLearning
    case goalProgress
    case relationship
    case efficiency
    case playability
    case exploitFinding
}

public struct GameEvaluation: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let kind: GameEvaluatorKind
    public let summary: String
    public let facts: [String]
    public let score: Double
    public let createdAt: Date

    public init(id: String = UUID().uuidString, kind: GameEvaluatorKind, summary: String, facts: [String], score: Double, createdAt: Date = Date()) {
        self.id = id
        self.kind = kind
        self.summary = summary
        self.facts = facts
        self.score = score
        self.createdAt = createdAt
    }
}

public struct GameHarnessSession: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public var title: String
    public var mode: GameHarnessMode
    public var status: GameHarnessStatus
    public var target: GameLaunchTarget
    public var policies: [GamePolicyDescriptor]
    public var trajectory: [GameTrajectoryStep]
    public var artifacts: [GameContentArtifact]
    public var pipelines: [GamePipeline]
    public var evaluations: [GameEvaluation]
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        title: String,
        mode: GameHarnessMode,
        status: GameHarnessStatus = .loaded,
        target: GameLaunchTarget,
        policies: [GamePolicyDescriptor],
        trajectory: [GameTrajectoryStep] = [],
        artifacts: [GameContentArtifact] = [],
        pipelines: [GamePipeline] = [],
        evaluations: [GameEvaluation] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws {
        guard !policies.isEmpty else { throw GameHarnessError.emptyPolicySet }
        self.id = id
        self.title = title
        self.mode = mode
        self.status = status
        self.target = target
        self.policies = policies
        self.trajectory = trajectory
        self.artifacts = artifacts
        self.pipelines = pipelines
        self.evaluations = evaluations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
