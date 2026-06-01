// SwooshTUI/SystemDevCommands.swift — 0.9S Development commands that show real state
//
// Commands that read live filesystem / env state instead of printing prose.

import Foundation
import SwooshTools

func makeSystemDevCommands() -> [SlashCommandDefinition] {

    let localCmd = SlashCommandDefinition(
        name: "local",
        summary: "Show local model (MLX) status.",
        category: .development
    ) { _ in
        let ram = ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024)
        let modelDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".swoosh/models")
        let modelCount = (try? FileManager.default.contentsOfDirectory(atPath: modelDir.path))?.count ?? 0
        #if arch(arm64)
        let silicon = "✅ Apple Silicon"
        #else
        let silicon = "⚠️  Intel — MLX not available"
        #endif
        return .success("""

          ─── Local Models ─────────────────────────────────
            Platform: \(silicon)  ·  \(ram)GB RAM
            Installed: \(modelCount) model(s) in ~/.swoosh/models/
            Use: swoosh model pull <name>   — download
                 swoosh model list          — list local
                 swoosh model use local     — switch to local

        """)
    }

    let dbCmd = SlashCommandDefinition(
        name: "db",
        summary: "Show storage backend status.",
        category: .development
    ) { ctx in
        switch ctx.arguments.first ?? "status" {
        case "start": return .success("  Use: swoosh db start")
        case "stop":  return .success("  Use: swoosh db stop")
        default:
            let dbPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".swoosh/actant.db").path
            let exists = FileManager.default.fileExists(atPath: dbPath)
            let baseURL = ProcessInfo.processInfo.environment["ACTANT_BASE_URL"] ?? "(unset — launch the Cartridge app)"
            return .success("""

              ─── Storage ──────────────────────────────────────
                Backend: ActantDB  ·  \(exists ? "✅ actant.db exists" : "⚠️ actant.db not yet created")
                Server:  \(baseURL)
                Paths:   ~/.swoosh/actant.db
                         ~/.swoosh/checkpoints/
                         ~/.swoosh/skills/

            """)
        }
    }

    return [localCmd, dbCmd]
}
