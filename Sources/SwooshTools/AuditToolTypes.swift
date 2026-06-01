// SwooshTools/AuditToolTypes.swift — Audit tool types — 1.1.7
import Foundation

// ── audit.tail ────────────────────────────────────────────────────

public struct AuditTailInput: Codable, Sendable {
    public let limit: Int?
    public let eventTypes: [String]?

    public init(limit: Int? = nil, eventTypes: [String]? = nil) {
        self.limit = limit
        self.eventTypes = eventTypes
    }
}

public struct AuditTailOutput: Codable, Sendable {
    public let events: [AuditEntry]

    public init(events: [AuditEntry]) {
        self.events = events
    }
}

// ── audit.search ──────────────────────────────────────────────────

public struct AuditSearchInput: Codable, Sendable {
    public let query: String
    public let limit: Int?

    public init(query: String, limit: Int? = nil) {
        self.query = query
        self.limit = limit
    }
}

public struct AuditSearchOutput: Codable, Sendable {
    public let events: [AuditEntry]

    public init(events: [AuditEntry]) {
        self.events = events
    }
}

// ── audit.get_event ───────────────────────────────────────────────

public struct AuditGetEventInput: Codable, Sendable {
    public let eventID: String

    public init(eventID: String) {
        self.eventID = eventID
    }
}

public struct AuditGetEventOutput: Codable, Sendable {
    public let event: AuditEntry?

    public init(event: AuditEntry?) {
        self.event = event
    }
}
