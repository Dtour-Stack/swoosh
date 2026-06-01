// SwooshStorageTests/SwooshStorageTests.swift — Unit tests for SwooshStorage — 0.9S

import Foundation
import Testing
@testable import SwooshStorage
@testable import SwooshTools
@testable import SwooshCore
@testable import SwooshApprovals

// MARK: - Schema + Migration tests

@Suite("Schema & Migration")
struct SchemaTests {
    @Test func databaseCreatesInMemory() async throws {
        let db = try SwooshDatabase(inMemory: true)
        // Verify we can query the schema version
        let version = try await db.execute { conn in
            let stmt = try conn.prepare("SELECT COALESCE(MAX(version), 0) FROM schema_version")
            for row in stmt {
                return Int(row[0] as! Int64)
            }
            return 0
        }
        #expect(version == 1)
    }

    @Test func idempotentMigration() async throws {
        // Running migrations twice should not error
        let db = try SwooshDatabase(inMemory: true)
        let version = try await db.execute { conn in
            let stmt = try conn.prepare("SELECT MAX(version) FROM schema_version")
            for row in stmt { return Int(row[0] as! Int64) }
            return 0
        }
        #expect(version == 1)
    }
}

// MARK: - Session store tests

@Suite("SQLiteSessionStore")
struct SessionStoreTests {
    @Test func appendAndLoadTranscript() async throws {
        let db = try SwooshDatabase(inMemory: true)
        let store = SQLiteSessionStore(db: db)

        let msg1 = SwooshCore.ChatMessage(role: .user, content: "Hello")
        let msg2 = SwooshCore.ChatMessage(role: .assistant, content: "Hi there!")

        try await store.appendMessage(sessionID: "s1", message: msg1)
        try await store.appendMessage(sessionID: "s1", message: msg2)

        let transcript = try await store.loadTranscript(sessionID: "s1")
        #expect(transcript.count == 2)
        #expect(transcript[0].role == .user)
        #expect(transcript[0].content == "Hello")
        #expect(transcript[1].role == .assistant)
        #expect(transcript[1].content == "Hi there!")
    }

    @Test func sessionsAreIsolated() async throws {
        let db = try SwooshDatabase(inMemory: true)
        let store = SQLiteSessionStore(db: db)

        try await store.appendMessage(sessionID: "s1", message: SwooshCore.ChatMessage(role: .user, content: "A"))
        try await store.appendMessage(sessionID: "s2", message: SwooshCore.ChatMessage(role: .user, content: "B"))

        let t1 = try await store.loadTranscript(sessionID: "s1")
        let t2 = try await store.loadTranscript(sessionID: "s2")
        #expect(t1.count == 1)
        #expect(t2.count == 1)
        #expect(t1[0].content == "A")
        #expect(t2[0].content == "B")
    }
}

// MARK: - Audit log tests

@Suite("SQLiteAuditLog")
struct AuditLogTests {
    @Test func appendAndTail() async throws {
        let db = try SwooshDatabase(inMemory: true)
        let log = SQLiteAuditLog(db: db)

        let entry = AuditEntry(
            kind: .toolCallSucceeded,
            toolName: "game.generate_content",
            detail: "Generated game content"
        )
        try await log.append(entry)

        let tail = await log.tail(limit: 10)
        #expect(tail.count == 1)
        #expect(tail[0].id == entry.id)
        #expect(tail[0].kind == .toolCallSucceeded)
        #expect(tail[0].toolName == "game.generate_content")
    }

    @Test func searchFindsMatches() async throws {
        let db = try SwooshDatabase(inMemory: true)
        let log = SQLiteAuditLog(db: db)

        try await log.append(AuditEntry(kind: .toolCallSucceeded, toolName: "game.generate_content", detail: "Generated game character"))
        try await log.append(AuditEntry(kind: .permissionGranted, detail: "Granted gameObserve"))

        let results = await log.search(query: "character", limit: 10)
        #expect(results.count == 1)
        #expect(results[0].toolName == "game.generate_content")
    }

    @Test func getEventByID() async throws {
        let db = try SwooshDatabase(inMemory: true)
        let log = SQLiteAuditLog(db: db)

        let entry = AuditEntry(kind: .safetyViolation, detail: "Blocked unapproved game input")
        try await log.append(entry)

        let found = await log.getEvent(id: entry.id)
        #expect(found != nil)
        #expect(found?.kind == .safetyViolation)
    }
}

// MARK: - Memory store tests

@Suite("SQLiteMemoryStore")
struct MemoryStoreTests {
    @Test func proposeAndListCandidates() async throws {
        let db = try SwooshDatabase(inMemory: true)
        let store = SQLiteMemoryStore(db: db)

        let candidateID = try await store.propose(ProposeMemoryCandidateInput(
            text: "User prefers dark mode",
            category: .preference,
            sensitivity: .normal,
            confidence: 0.8,
            evidence: []
        ))

        let candidates = try await store.listCandidates(status: .pending, limit: nil)
        #expect(candidates.count == 1)
        #expect(candidates[0].id == candidateID)
        #expect(candidates[0].text == "User prefers dark mode")
    }

    @Test func approveMovesToApproved() async throws {
        let db = try SwooshDatabase(inMemory: true)
        let store = SQLiteMemoryStore(db: db)

        let candidateID = try await store.propose(ProposeMemoryCandidateInput(
            text: "Uses Vim bindings",
            category: .preference,
            sensitivity: .normal,
            confidence: 0.9,
            evidence: []
        ))

        let memoryID = try await store.approve(candidateID: candidateID, finalText: nil)

        let approved = try await store.listApproved(category: nil, limit: nil)
        #expect(approved.count == 1)
        #expect(approved[0].id == memoryID)
        #expect(approved[0].text == "Uses Vim bindings")

        let candidate = try await store.getCandidate(id: candidateID)
        #expect(candidate?.status == .approved)
    }

    @Test func rejectCandidate() async throws {
        let db = try SwooshDatabase(inMemory: true)
        let store = SQLiteMemoryStore(db: db)

        let candidateID = try await store.propose(ProposeMemoryCandidateInput(
            text: "Some guess",
            category: .fact,
            sensitivity: .normal,
            confidence: 0.3,
            evidence: []
        ))
        try await store.reject(candidateID: candidateID, reason: "Not accurate")

        let candidate = try await store.getCandidate(id: candidateID)
        #expect(candidate?.status == .rejected)
    }

    @Test func searchApprovedMemories() async throws {
        let db = try SwooshDatabase(inMemory: true)
        let store = SQLiteMemoryStore(db: db)

        let c1 = try await store.propose(ProposeMemoryCandidateInput(
            text: "Works at Acme Corp",
            category: .fact,
            sensitivity: .normal,
            confidence: 0.9,
            evidence: []
        ))
        _ = try await store.approve(candidateID: c1, finalText: nil)

        let c2 = try await store.propose(ProposeMemoryCandidateInput(
            text: "Prefers Python over Java",
            category: .preference,
            sensitivity: .normal,
            confidence: 0.8,
            evidence: []
        ))
        _ = try await store.approve(candidateID: c2, finalText: nil)

        let results = try await store.searchApproved(query: "Acme", category: nil, limit: nil)
        #expect(results.count == 1)
        #expect(results[0].memory.text == "Works at Acme Corp")
    }
}

// MARK: - Approval store tests

@Suite("SQLiteApprovalStore")
struct ApprovalStoreTests {
    @Test func saveAndListPending() async throws {
        let db = try SwooshDatabase(inMemory: true)
        let store = SQLiteApprovalStore(db: db)

        let record = ApprovalRecord(
            sessionID: "s1",
            toolName: "game.record_action",
            risk: .critical,
            permission: .gameAct,
            inputPreview: "Press jump",
            origin: .model
        )
        try await store.save(record)

        let pending = await store.listPending(sessionID: "s1")
        #expect(pending.count == 1)
        #expect(pending[0].toolName == "game.record_action")
    }

    @Test func resolveApproval() async throws {
        let db = try SwooshDatabase(inMemory: true)
        let store = SQLiteApprovalStore(db: db)

        let record = ApprovalRecord(
            sessionID: "s1",
            toolName: "game.record_action",
            risk: .critical,
            permission: .gameAct,
            inputPreview: "Move forward",
            origin: .model
        )
        try await store.save(record)

        try await store.resolve(
            id: record.id,
            status: .approvedForSession,
            resolvedBy: .human,
            reason: nil
        )

        let approved = await store.isApprovedForSession(
            toolName: "game.record_action",
            sessionID: "s1"
        )
        #expect(approved == true)

        let pendingAfter = await store.listPending(sessionID: "s1")
        #expect(pendingAfter.isEmpty)
    }
}
