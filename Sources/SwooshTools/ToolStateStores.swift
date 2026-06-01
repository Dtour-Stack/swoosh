// SwooshTools/ToolStateStores.swift — Operational state stores for toolsets
import Foundation

// MARK: - Memory tools

public protocol MemoryToolStoring: Sendable {
    func listApproved(category: MemoryCategory?, limit: Int?) async throws -> [ApprovedMemory]
    func searchApproved(query: String, category: MemoryCategory?, limit: Int?) async throws -> [ApprovedMemorySearchResult]
    func getApproved(id: String) async throws -> ApprovedMemory?
    func listCandidates(status: CandidateStatus?, limit: Int?) async throws -> [MemoryCandidate]
    func getCandidate(id: String) async throws -> MemoryCandidate?
    func propose(_ input: ProposeMemoryCandidateInput) async throws -> String
    func approve(candidateID: String, finalText: String?) async throws -> String
    func reject(candidateID: String, reason: String?) async throws
    func edit(candidateID: String, newText: String, newCategory: MemoryCategory?, newSensitivity: Sensitivity?) async throws
}

public actor InMemoryMemoryToolStore: MemoryToolStoring {
    private var approved: [String: ApprovedMemory] = [:]
    private var candidates: [String: MemoryCandidate] = [:]

    public init(
        approved: [ApprovedMemory] = [],
        candidates: [MemoryCandidate] = []
    ) {
        self.approved = Dictionary(uniqueKeysWithValues: approved.map { ($0.id, $0) })
        self.candidates = Dictionary(uniqueKeysWithValues: candidates.map { ($0.id, $0) })
    }

    public func listApproved(category: MemoryCategory?, limit: Int?) -> [ApprovedMemory] {
        limited(
            approved.values
                .filter { category == nil || $0.category == category }
                .sorted { $0.createdAt > $1.createdAt },
            limit: limit
        )
    }

    public func searchApproved(query: String, category: MemoryCategory?, limit: Int?) -> [ApprovedMemorySearchResult] {
        let needle = query.normalizedForToolSearch()
        guard !needle.isEmpty else { return [] }
        let scored = approved.values.compactMap { memory -> ApprovedMemorySearchResult? in
            guard category == nil || memory.category == category else { return nil }
            let haystack = memory.text.normalizedForToolSearch()
            guard haystack.contains(needle) else { return nil }
            let score = haystack == needle ? 1.0 : max(0.2, Double(needle.count) / Double(max(haystack.count, 1)))
            return ApprovedMemorySearchResult(memory: memory, score: score, reason: "text match")
        }
        return limited(scored.sorted { $0.score > $1.score }, limit: limit)
    }

    public func getApproved(id: String) -> ApprovedMemory? {
        approved[id]
    }

    public func listCandidates(status: CandidateStatus?, limit: Int?) -> [MemoryCandidate] {
        limited(
            candidates.values
                .filter { status == nil || $0.status == status }
                .sorted { $0.createdAt > $1.createdAt },
            limit: limit
        )
    }

    public func getCandidate(id: String) -> MemoryCandidate? {
        candidates[id]
    }

    public func propose(_ input: ProposeMemoryCandidateInput) -> String {
        let id = UUID().uuidString
        candidates[id] = MemoryCandidate(
            id: id,
            text: input.text,
            category: input.category,
            sensitivity: input.sensitivity,
            confidence: input.confidence,
            evidence: input.evidence,
            status: .pending
        )
        return id
    }

    public func approve(candidateID: String, finalText: String?) throws -> String {
        guard let candidate = candidates[candidateID] else {
            throw ToolError.notFound(candidateID)
        }
        let memoryID = UUID().uuidString
        approved[memoryID] = ApprovedMemory(
            id: memoryID,
            text: finalText ?? candidate.text,
            category: candidate.category,
            sensitivity: candidate.sensitivity,
            confidence: candidate.confidence
        )
        candidates[candidateID] = MemoryCandidate(
            id: candidate.id,
            text: finalText ?? candidate.text,
            category: candidate.category,
            sensitivity: candidate.sensitivity,
            confidence: candidate.confidence,
            evidence: candidate.evidence,
            status: .approved,
            createdAt: candidate.createdAt
        )
        return memoryID
    }

    public func reject(candidateID: String, reason: String?) throws {
        guard let candidate = candidates[candidateID] else {
            throw ToolError.notFound(candidateID)
        }
        candidates[candidateID] = MemoryCandidate(
            id: candidate.id,
            text: candidate.text,
            category: candidate.category,
            sensitivity: candidate.sensitivity,
            confidence: candidate.confidence,
            evidence: candidate.evidence,
            status: .rejected,
            createdAt: candidate.createdAt
        )
    }

    public func edit(candidateID: String, newText: String, newCategory: MemoryCategory?, newSensitivity: Sensitivity?) throws {
        guard let candidate = candidates[candidateID] else {
            throw ToolError.notFound(candidateID)
        }
        candidates[candidateID] = MemoryCandidate(
            id: candidate.id,
            text: newText,
            category: newCategory ?? candidate.category,
            sensitivity: newSensitivity ?? candidate.sensitivity,
            confidence: candidate.confidence,
            evidence: candidate.evidence,
            status: .edited,
            createdAt: candidate.createdAt
        )
    }
}

// MARK: - Workflow tools

public protocol WorkflowToolStoring: Sendable {
    func saveDraft(_ draft: WorkflowDraft) async throws
    func listDrafts() async throws -> [WorkflowDraft]
    func getDraft(id: String) async throws -> WorkflowDraft?
    func setEnabled(id: String, enabled: Bool) async throws -> WorkflowDraft
}

public actor InMemoryWorkflowToolStore: WorkflowToolStoring {
    private var drafts: [String: WorkflowDraft] = [:]

    public init(drafts: [WorkflowDraft] = []) {
        self.drafts = Dictionary(uniqueKeysWithValues: drafts.map { ($0.id, $0) })
    }

    public func saveDraft(_ draft: WorkflowDraft) {
        drafts[draft.id] = draft
    }

    public func listDrafts() -> [WorkflowDraft] {
        drafts.values.sorted { $0.name < $1.name }
    }

    public func getDraft(id: String) -> WorkflowDraft? {
        drafts[id]
    }

    public func setEnabled(id: String, enabled: Bool) throws -> WorkflowDraft {
        guard let draft = drafts[id] else {
            throw ToolError.notFound(id)
        }
        let updated = WorkflowDraft(
            id: draft.id,
            name: draft.name,
            summary: draft.summary,
            steps: draft.steps,
            requiredPermissions: draft.requiredPermissions,
            trigger: draft.trigger,
            enabled: enabled
        )
        drafts[id] = updated
        return updated
    }
}

public actor FileWorkflowToolStore: WorkflowToolStoring {
    private let url: URL
    private var loaded = false
    private var drafts: [String: WorkflowDraft] = [:]

    public init(url: URL? = nil) {
        self.url = url ?? defaultSwooshStateDirectory()
            .appendingPathComponent("workflows/tool-drafts.json")
    }

    public func saveDraft(_ draft: WorkflowDraft) throws {
        try ensureLoaded()
        drafts[draft.id] = draft
        try persist()
    }

    public func listDrafts() throws -> [WorkflowDraft] {
        try ensureLoaded()
        return drafts.values.sorted { $0.name < $1.name }
    }

    public func getDraft(id: String) throws -> WorkflowDraft? {
        try ensureLoaded()
        return drafts[id]
    }

    public func setEnabled(id: String, enabled: Bool) throws -> WorkflowDraft {
        try ensureLoaded()
        guard let draft = drafts[id] else {
            throw ToolError.notFound(id)
        }
        let updated = WorkflowDraft(
            id: draft.id,
            name: draft.name,
            summary: draft.summary,
            steps: draft.steps,
            requiredPermissions: draft.requiredPermissions,
            trigger: draft.trigger,
            enabled: enabled
        )
        drafts[id] = updated
        try persist()
        return updated
    }

    private func ensureLoaded() throws {
        guard !loaded else { return }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            let snapshot = try JSONDecoder.swooshToolState.decode(WorkflowToolStoreSnapshot.self, from: data)
            drafts = Dictionary(uniqueKeysWithValues: snapshot.drafts.map { ($0.id, $0) })
        }
        loaded = true
    }

    private func persist() throws {
        let snapshot = WorkflowToolStoreSnapshot(drafts: drafts.values.sorted { $0.name < $1.name })
        let data = try JSONEncoder.swooshToolState.encode(snapshot)
        try data.write(to: url, options: .atomic)
    }
}

private struct WorkflowToolStoreSnapshot: Codable, Sendable {
    let drafts: [WorkflowDraft]
}

private func limited<T>(_ values: [T], limit: Int?) -> [T] {
    guard let limit else { return values }
    return Array(values.prefix(max(0, limit)))
}

private extension String {
    func normalizedForToolSearch() -> String {
        split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

extension JSONEncoder {
    static var swooshToolState: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var swooshToolState: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

// MARK: - Cross-platform state directory

/// Returns the directory where Swoosh stores its per-tool state.
///   • macOS — `~/.swoosh/` (matches the daemon's convention).
///   • iOS   — the app sandbox's Application Support directory.
private func defaultSwooshStateDirectory() -> URL {
    #if os(macOS)
    return FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".swoosh", isDirectory: true)
    #else
    let base = (try? FileManager.default.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )) ?? URL(fileURLWithPath: NSTemporaryDirectory())
    return base.appendingPathComponent("ai.swoosh.agent", isDirectory: true)
    #endif
}
