// SwooshTUI/DefaultCommands.swift — 0.9S Built-in slash commands
//
// Returns an array of SlashCommandDefinitions wired into
// `SlashCommandRegistry` by `SwooshShell`'s caller (today, the
// `swoosh chat` subcommand).
//
// `/help` is rendered live from the registry (`registry.helpText()` —
// see SlashCommand.swift), so adding a new command auto-surfaces in
// the help output instead of waiting for someone to update a literal.

import Foundation
import SwooshTools

/// Build the default set of in-shell slash commands.
///
/// `registry` is passed in so `/help` can render the live command list
/// via `registry.helpText()` rather than a hand-typed literal that
/// silently drifts as commands are added/removed.
public func makeDefaultCommandDefinitions(
    registry: SlashCommandRegistry
) -> [SlashCommandDefinition] {
    makeCoreCommands(registry: registry)
        + makeAgentCommands()
        + makeSystemDevCommands()
}

// MARK: - Core (/help, /exit, /clear)

private func makeCoreCommands(
    registry: SlashCommandRegistry
) -> [SlashCommandDefinition] {
    let helpCmd = SlashCommandDefinition(
        name: "help",
        aliases: ["h", "?"],
        summary: "Show available commands.",
        category: .general
    ) { [weak registry] _ in
        guard let registry else { return .success("") }
        let text = await registry.helpText()
        return .success(text)
    }

    let exitCmd = SlashCommandDefinition(
        name: "exit",
        aliases: ["quit", "q"],
        summary: "Exit Swoosh.",
        category: .general,
        handler: { _ in .exit }
    )

    let clearCmd = SlashCommandDefinition(
        name: "clear",
        aliases: ["cls"],
        summary: "Clear the terminal.",
        category: .general,
        handler: { _ in .success("\u{001B}[2J\u{001B}[H") }
    )

    return [helpCmd, exitCmd, clearCmd]
}

// MARK: - Agent (/tools, /sessions)

private func makeAgentCommands() -> [SlashCommandDefinition] {
    let toolsCmd = SlashCommandDefinition(
        name: "tools",
        aliases: ["t"],
        summary: "Pointers to Cartridge game harness discovery.",
        category: .agent
    ) { _ in
        .success("""

          ─── Tools ────────────────────────────────────────
            The live game harness registry lives in the Cartridge app's runtime.

              swoosh game cli list       — CLI starter catalog
              swoosh game cli init ...   — generate a laptop/game CLI starter
              swoosh provider list       — active model providers

        """)
    }

    let sessionsCmd = SlashCommandDefinition(
        name: "sessions",
        summary: "Manage chat sessions.",
        category: .agent
    ) { ctx in
        .success("""

          ─── Sessions ─────────────────────────────────────
            Current: \(ctx.sessionID)
            Use: swoosh sessions list | resume <id> | delete <id>

        """)
    }

    return [toolsCmd, sessionsCmd]
}
