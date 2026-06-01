// SwooshArena/GameHarnessStore.swift — Cartridge session store (0.1A)

import Foundation

public protocol GameHarnessStoring: Sendable {
    func createSession(_ session: GameHarnessSession) async throws
    func listSessions() async throws -> [GameHarnessSession]
    func getSession(id: String) async throws -> GameHarnessSession?
    func updateSession(_ session: GameHarnessSession) async throws
    func recordObservation(sessionID: String, observation: GameObservation, reward: Double, done: Bool) async throws -> GameTrajectoryStep
    func recordAction(sessionID: String, action: GameAction, observation: GameObservation, reward: Double, done: Bool) async throws -> GameTrajectoryStep
    func addArtifact(sessionID: String, artifact: GameContentArtifact) async throws
    func addPipeline(sessionID: String, pipeline: GamePipeline) async throws
    func addEvaluation(sessionID: String, evaluation: GameEvaluation) async throws
}

public actor InMemoryGameHarnessStore: GameHarnessStoring {
    private var sessions: [String: GameHarnessSession]

    public init(sessions: [GameHarnessSession] = []) {
        self.sessions = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
    }

    public func createSession(_ session: GameHarnessSession) {
        sessions[session.id] = session
    }

    public func listSessions() -> [GameHarnessSession] {
        sessions.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    public func getSession(id: String) -> GameHarnessSession? {
        sessions[id]
    }

    public func updateSession(_ session: GameHarnessSession) throws {
        guard sessions[session.id] != nil else {
            throw GameHarnessError.sessionNotFound(session.id)
        }
        var updated = session
        updated.updatedAt = Date()
        sessions[session.id] = updated
    }

    public func recordObservation(sessionID: String, observation: GameObservation, reward: Double, done: Bool) throws -> GameTrajectoryStep {
        guard var session = sessions[sessionID] else {
            throw GameHarnessError.sessionNotFound(sessionID)
        }
        let step = GameTrajectoryStep(
            index: session.trajectory.count,
            observation: observation,
            action: nil,
            reward: reward,
            done: done
        )
        session.trajectory.append(step)
        session.status = done ? .completed : session.status
        session.updatedAt = Date()
        sessions[sessionID] = session
        return step
    }

    public func recordAction(sessionID: String, action: GameAction, observation: GameObservation, reward: Double, done: Bool) throws -> GameTrajectoryStep {
        guard var session = sessions[sessionID] else {
            throw GameHarnessError.sessionNotFound(sessionID)
        }
        guard session.policies.contains(where: { $0.id == action.policyID }) else {
            throw GameHarnessError.policyNotFound(action.policyID)
        }
        let step = GameTrajectoryStep(
            index: session.trajectory.count,
            observation: observation,
            action: action,
            reward: reward,
            done: done
        )
        session.trajectory.append(step)
        session.status = done ? .completed : .running
        session.updatedAt = Date()
        sessions[sessionID] = session
        return step
    }

    public func addArtifact(sessionID: String, artifact: GameContentArtifact) throws {
        guard var session = sessions[sessionID] else {
            throw GameHarnessError.sessionNotFound(sessionID)
        }
        session.artifacts.append(artifact)
        session.updatedAt = Date()
        sessions[sessionID] = session
    }

    public func addPipeline(sessionID: String, pipeline: GamePipeline) throws {
        guard var session = sessions[sessionID] else {
            throw GameHarnessError.sessionNotFound(sessionID)
        }
        session.pipelines.append(pipeline)
        session.updatedAt = Date()
        sessions[sessionID] = session
    }

    public func addEvaluation(sessionID: String, evaluation: GameEvaluation) throws {
        guard var session = sessions[sessionID] else {
            throw GameHarnessError.sessionNotFound(sessionID)
        }
        session.evaluations.append(evaluation)
        session.updatedAt = Date()
        sessions[sessionID] = session
    }
}

public actor CartridgeHarness {
    private let store: any GameHarnessStoring

    public init(store: any GameHarnessStoring = InMemoryGameHarnessStore()) {
        self.store = store
    }

    public func loadLocalURL(
        title: String,
        urlString: String,
        mode: GameHarnessMode,
        policies: [GamePolicyDescriptor]
    ) async throws -> GameHarnessSession {
        let target = try GameLaunchTarget(
            title: title,
            kind: .localURL,
            urlString: urlString
        )
        let session = try GameHarnessSession(
            title: title,
            mode: mode,
            target: target,
            policies: policies
        )
        try await store.createSession(session)
        return session
    }

    public func createGeneratedGame(
        title: String,
        template: GameProjectTemplateKind,
        mode: GameHarnessMode,
        policies: [GamePolicyDescriptor]
    ) async throws -> GameHarnessSession {
        let target = try GameLaunchTarget(
            title: title,
            kind: .generatedGame,
            engineHint: template.rawValue,
            metadata: ["template": .string(template.rawValue)]
        )
        let session = try GameHarnessSession(
            title: title,
            mode: mode,
            target: target,
            policies: policies
        )
        try await store.createSession(session)
        return session
    }

    public func listSessions() async throws -> [GameHarnessSession] {
        try await store.listSessions()
    }

    public func session(id: String) async throws -> GameHarnessSession? {
        try await store.getSession(id: id)
    }

    public func requireSession(id: String) async throws -> GameHarnessSession {
        guard let session = try await store.getSession(id: id) else {
            throw GameHarnessError.sessionNotFound(id)
        }
        return session
    }

    public func observe(sessionID: String, observation: GameObservation, reward: Double, done: Bool) async throws -> GameTrajectoryStep {
        try await store.recordObservation(sessionID: sessionID, observation: observation, reward: reward, done: done)
    }

    public func act(sessionID: String, action: GameAction, observation: GameObservation, reward: Double, done: Bool) async throws -> GameTrajectoryStep {
        try await store.recordAction(sessionID: sessionID, action: action, observation: observation, reward: reward, done: done)
    }

    public func addArtifact(sessionID: String, artifact: GameContentArtifact) async throws {
        try await store.addArtifact(sessionID: sessionID, artifact: artifact)
    }

    public func addPipeline(sessionID: String, pipeline: GamePipeline) async throws {
        try await store.addPipeline(sessionID: sessionID, pipeline: pipeline)
    }

    public func addEvaluation(sessionID: String, evaluation: GameEvaluation) async throws {
        try await store.addEvaluation(sessionID: sessionID, evaluation: evaluation)
    }
}
