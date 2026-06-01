// SwooshStorage/SQLiteAuditLog.swift — Durable audit log — 0.9S

import Foundation
import SQLite
import SwooshTools

public actor SQLiteAuditLog: AuditLogging {
    private let db: SwooshDatabase

    public init(db: SwooshDatabase) {
        self.db = db
    }

    public func append(_ event: AuditEntry) async throws {
        let ts = swooshDateString(event.timestamp)

        try await db.execute { conn -> Void in
            _ = try conn.run("""
                INSERT OR REPLACE INTO audit_log
                    (id, timestamp, kind, tool_name, session_id, detail, success)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
                event.id, ts, event.kind.rawValue, event.toolName,
                event.sessionID, event.detail, event.success ? 1 : 0
            )
        }
    }

    public func tail(limit: Int) async -> [AuditEntry] {
        (try? await db.execute { conn in
            let stmt = try conn.prepare("""
                SELECT id, timestamp, kind, tool_name, session_id, detail, success
                FROM audit_log ORDER BY timestamp DESC LIMIT ?
            """, limit)
            return Self.rows(from: stmt)
        }) ?? []
    }

    public func search(query: String, limit: Int) async -> [AuditEntry] {
        (try? await db.execute { conn in
            let pattern = "%\(query)%"
            let stmt = try conn.prepare("""
                SELECT id, timestamp, kind, tool_name, session_id, detail, success
                FROM audit_log WHERE detail LIKE ? OR tool_name LIKE ?
                ORDER BY timestamp DESC LIMIT ?
            """, pattern, pattern, limit)
            return Self.rows(from: stmt)
        }) ?? []
    }

    public func getEvent(id: String) async -> AuditEntry? {
        try? await db.execute { conn in
            let stmt = try conn.prepare("""
                SELECT id, timestamp, kind, tool_name, session_id, detail, success
                FROM audit_log WHERE id = ?
            """, id)
            return Self.rows(from: stmt).first
        }
    }

    private static func rows(from stmt: Statement) -> [AuditEntry] {
        var entries: [AuditEntry] = []
        for row in stmt {
            guard let kind = AuditEntryKind(rawValue: row[2] as! String) else { continue }
            entries.append(AuditEntry(
                id: row[0] as! String,
                timestamp: swooshParseDate(row[1] as! String),
                kind: kind,
                toolName: row[3] as? String,
                sessionID: row[4] as? String,
                detail: row[5] as! String,
                success: (row[6] as! Int64) != 0
            ))
        }
        return entries
    }
}
