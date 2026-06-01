// SwooshToolsets/GameSessionTools.swift — Cartridge session mutation tools (0.1B)

import Foundation
import SwooshArena
import SwooshTools

public struct GameRecordObservationTool: SwooshTool {
    public struct Input: Codable, Sendable {
        public let sessionID: String
        public let summary: String
        public let state: JSONValue
        public let frameReference: String?
        public let events: [String]
        public let reward: Double
        public let done: Bool
    }

    public struct Output: Codable, Sendable {
        public let step: GameTrajectoryStep
        public let session: GameHarnessSession
    }

    public static let name: ToolName = "game.record_observation"
    public static let displayName = "Record Game Observation"
    public static let description = "Record a Cartridge game observation for replay and testing."
    public static let permission = SwooshPermission.gameObserve
    public static let risk = ToolRisk.low
    public static let approval = ApprovalPolicy.never
    public static let toolset = ToolsetID.gaming

    private let dependencies: GameHarnessToolDependencies

    public init(dependencies: GameHarnessToolDependencies) {
        self.dependencies = dependencies
    }

    public func call(_ input: Input, context: ToolContext) async throws -> Output {
        try await dependencies.firewall.require(.gameObserve)
        let observation = GameObservation(
            summary: input.summary,
            state: input.state,
            frameReference: input.frameReference,
            events: input.events
        )
        let step = try await dependencies.harness.observe(
            sessionID: input.sessionID,
            observation: observation,
            reward: input.reward,
            done: input.done
        )
        return Output(step: step, session: try await dependencies.harness.requireSession(id: input.sessionID))
    }
}

public struct GameRecordActionTool: SwooshTool {
    public struct Input: Codable, Sendable {
        public let sessionID: String
        public let kind: GameActionKind
        public let policyID: String
        public let parameters: JSONValue
        public let observationSummary: String
        public let observationState: JSONValue
        public let frameReference: String?
        public let events: [String]
        public let reward: Double
        public let done: Bool
    }

    public struct Output: Codable, Sendable {
        public let step: GameTrajectoryStep
        public let session: GameHarnessSession
    }

    public static let name: ToolName = "game.record_action"
    public static let displayName = "Record Game Action"
    public static let description = "Record a Cartridge game action with the observation it acted on."
    public static let permission = SwooshPermission.gameAct
    public static let risk = ToolRisk.high
    public static let approval = ApprovalPolicy.askEveryTime
    public static let toolset = ToolsetID.gaming

    private let dependencies: GameHarnessToolDependencies

    public init(dependencies: GameHarnessToolDependencies) {
        self.dependencies = dependencies
    }

    public func call(_ input: Input, context: ToolContext) async throws -> Output {
        try await dependencies.firewall.require(.gameAct)
        let action = GameAction(
            kind: input.kind,
            policyID: input.policyID,
            parameters: input.parameters
        )
        let observation = GameObservation(
            summary: input.observationSummary,
            state: input.observationState,
            frameReference: input.frameReference,
            events: input.events
        )
        let step = try await dependencies.harness.act(
            sessionID: input.sessionID,
            action: action,
            observation: observation,
            reward: input.reward,
            done: input.done
        )
        return Output(step: step, session: try await dependencies.harness.requireSession(id: input.sessionID))
    }
}

public struct GameGenerateContentTool: SwooshTool {
    public struct Input: Codable, Sendable {
        public let sessionID: String
        public let kind: GameArtifactKind
        public let title: String
        public let body: JSONValue
        public let exportFormats: [GameExportFormat]
    }

    public struct Output: Codable, Sendable {
        public let artifact: GameContentArtifact
        public let session: GameHarnessSession
    }

    public static let name: ToolName = "game.generate_content"
    public static let displayName = "Generate Game Content"
    public static let description = "Attach a generated character, item, dialogue, asset, script, or content pack to a Cartridge session."
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
        let artifact = GameContentArtifact(
            kind: input.kind,
            title: input.title,
            body: input.body,
            exportFormats: input.exportFormats
        )
        try await dependencies.harness.addArtifact(sessionID: input.sessionID, artifact: artifact)
        return Output(artifact: artifact, session: try await dependencies.harness.requireSession(id: input.sessionID))
    }
}

public struct GameSavePipelineTool: SwooshTool {
    public struct Input: Codable, Sendable {
        public let sessionID: String
        public let name: String
        public let nodes: [GamePipelineNode]
        public let edges: [GamePipelineEdge]
    }

    public struct Output: Codable, Sendable {
        public let pipeline: GamePipeline
        public let session: GameHarnessSession
    }

    public static let name: ToolName = "game.save_pipeline"
    public static let displayName = "Save Game Pipeline"
    public static let description = "Save a Cartridge generation, testing, or export pipeline graph."
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
        let pipeline = try GamePipeline(name: input.name, nodes: input.nodes, edges: input.edges)
        try await dependencies.harness.addPipeline(sessionID: input.sessionID, pipeline: pipeline)
        return Output(pipeline: pipeline, session: try await dependencies.harness.requireSession(id: input.sessionID))
    }
}

public struct GameImportPipelineTool: SwooshTool {
    public struct Input: Codable, Sendable {
        public let sessionID: String
        public let defaultName: String
        public let document: GamePipelineImportDocument
    }

    public struct Output: Codable, Sendable {
        public let pipeline: GamePipeline
        public let session: GameHarnessSession
    }

    public static let name: ToolName = "game.import_pipeline"
    public static let displayName = "Import Game Pipeline"
    public static let description = "Import a Pipeline or React Flow workflow graph into a Cartridge session."
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
        let pipeline = try input.document.pipeline(defaultName: input.defaultName)
        try await dependencies.harness.addPipeline(sessionID: input.sessionID, pipeline: pipeline)
        return Output(pipeline: pipeline, session: try await dependencies.harness.requireSession(id: input.sessionID))
    }
}

public struct GameEvaluateSessionTool: SwooshTool {
    public struct Input: Codable, Sendable {
        public let sessionID: String
        public let kind: GameEvaluatorKind
        public let summary: String
        public let facts: [String]
        public let score: Double
    }

    public struct Output: Codable, Sendable {
        public let evaluation: GameEvaluation
        public let session: GameHarnessSession
    }

    public static let name: ToolName = "game.evaluate_session"
    public static let displayName = "Evaluate Game Session"
    public static let description = "Write a Cartridge playability, goal-progress, exploit-finding, or mistake-learning evaluation."
    public static let permission = SwooshPermission.gameEvaluate
    public static let risk = ToolRisk.medium
    public static let approval = ApprovalPolicy.askFirstTime
    public static let toolset = ToolsetID.gaming

    private let dependencies: GameHarnessToolDependencies

    public init(dependencies: GameHarnessToolDependencies) {
        self.dependencies = dependencies
    }

    public func call(_ input: Input, context: ToolContext) async throws -> Output {
        try await dependencies.firewall.require(.gameEvaluate)
        guard input.score >= 0, input.score <= 1 else {
            throw GameHarnessError.invalidEvaluationScore(input.score)
        }
        let evaluation = GameEvaluation(
            kind: input.kind,
            summary: input.summary,
            facts: input.facts,
            score: input.score
        )
        try await dependencies.harness.addEvaluation(sessionID: input.sessionID, evaluation: evaluation)
        return Output(evaluation: evaluation, session: try await dependencies.harness.requireSession(id: input.sessionID))
    }
}
