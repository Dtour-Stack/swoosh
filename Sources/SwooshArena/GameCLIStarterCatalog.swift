// SwooshArena/GameCLIStarterCatalog.swift — Cartridge CLI starter catalog (0.1A)

import Foundation

public enum GameCLIStarterKind: String, Codable, Sendable, CaseIterable {
    case game
    case agent
    case character
    case laptop
}

public enum GameCLIInputModality: String, Codable, Sendable, CaseIterable {
    case textPrompt
    case voicePrompt
    case visionCapture
    case nitroPolicy
}

public enum GameCLIStarterCapability: String, Codable, Sendable, CaseIterable {
    case projectBootstrap
    case playInstructions
    case agentHarness
    case characterSheet
    case commandDiscovery
    case jsonOutput
    case repl
    case undoRedo
    case inputMapping
    case assetManifest
    case testScript
    case nitroGenPolicy
    case voiceDriven
    case visionDriven
    case laptopNavigation
    case appFocus
    case windowControl
    case screenObservation
    case mouseControl
    case keyboardControl
    case hotkeyControl
}

public struct GameCLIStarterDescriptor: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let displayName: String
    public let kind: GameCLIStarterKind
    public let capabilities: [GameCLIStarterCapability]
    public let inputModalities: [GameCLIInputModality]
    public let outputFiles: [String]
    public let commandGroups: [String]
    public let recommendedFor: [String]
    public let sourceInspirations: [String]
    public let notes: [String]
}

public struct GameCLIStarterFile: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let path: String
    public let body: String

    public init(path: String, body: String) {
        self.id = path
        self.path = path
        self.body = body
    }
}

public struct GameCLIStarterScaffold: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let starterID: String
    public let title: String
    public let executableName: String
    public let agentName: String
    public let kind: GameCLIStarterKind
    public let files: [GameCLIStarterFile]
}

public enum GameCLIStarterCatalog {
    public static let all: [GameCLIStarterDescriptor] = [
        GameCLIStarterDescriptor(
            id: "cartridge-game-cli",
            displayName: "Cartridge Game CLI",
            kind: .game,
            capabilities: [.projectBootstrap, .playInstructions, .commandDiscovery, .jsonOutput, .repl, .inputMapping, .testScript, .nitroGenPolicy, .voiceDriven, .visionDriven],
            inputModalities: [.textPrompt, .voicePrompt, .visionCapture, .nitroPolicy],
            outputFiles: ["pyproject.toml", "README.md", "src/<name>/cli.py"],
            commandGroups: ["init", "load-url", "prompt", "playbook", "test-run", "manifest"],
            recommendedFor: ["local web games", "Three.js/WebGPU starters", "playtest harnesses", "agent-readable game controls"],
            sourceInspirations: ["printing-press catalog pattern", "CLI-Anything harness shape", "Cartridge game harness"],
            notes: ["Default agent: Cartridge", "Voice commands enter as speech transcripts from the host app", "Vision context can be attached as frame summaries"]
        ),
        GameCLIStarterDescriptor(
            id: "cartridge-agent-cli",
            displayName: "Cartridge Agent CLI",
            kind: .agent,
            capabilities: [.agentHarness, .commandDiscovery, .jsonOutput, .repl, .undoRedo, .inputMapping, .testScript, .nitroGenPolicy, .voiceDriven, .visionDriven],
            inputModalities: [.textPrompt, .voicePrompt, .visionCapture, .nitroPolicy],
            outputFiles: ["pyproject.toml", "README.md", "src/<name>/cli.py"],
            commandGroups: ["init", "observe", "act", "evaluate", "policy", "manifest"],
            recommendedFor: ["game-playing agents", "NitroGen/provider LLM hybrids", "scripted baselines", "test oracles"],
            sourceInspirations: ["printing-press focused CLI pattern", "CLI-Anything agent harness", "NitroGen controller tools"],
            notes: ["Keeps JSON output first-class for agents", "Separates observation, action, and evaluation commands"]
        ),
        GameCLIStarterDescriptor(
            id: "cartridge-character-cli",
            displayName: "Cartridge Character CLI",
            kind: .character,
            capabilities: [.characterSheet, .commandDiscovery, .jsonOutput, .repl, .assetManifest, .nitroGenPolicy, .voiceDriven, .visionDriven],
            inputModalities: [.textPrompt, .voicePrompt, .visionCapture, .nitroPolicy],
            outputFiles: ["pyproject.toml", "README.md", "src/<name>/cli.py"],
            commandGroups: ["create", "voice", "sprite", "model3d", "persona", "export"],
            recommendedFor: ["NPCs", "player characters", "voice profiles", "2D sprites", "3D model briefs"],
            sourceInspirations: ["printing-press generated CLI ergonomics", "DogSprite/dreamsprites/image-extender 2D workflows", "Cartridge asset catalogs"],
            notes: ["Produces character packets that can be exported into engines or agent personas"]
        ),
        GameCLIStarterDescriptor(
            id: "cartridge-laptop-cli",
            displayName: "Cartridge Laptop Navigator CLI",
            kind: .laptop,
            capabilities: [.laptopNavigation, .screenObservation, .appFocus, .windowControl, .mouseControl, .keyboardControl, .hotkeyControl, .commandDiscovery, .jsonOutput, .testScript, .voiceDriven, .visionDriven],
            inputModalities: [.textPrompt, .voicePrompt, .visionCapture],
            outputFiles: ["pyproject.toml", "README.md", "src/<name>/cli.py"],
            commandGroups: ["prompt", "screenshot", "open-app", "focus-app", "open-url", "click", "type", "hotkey", "plan"],
            recommendedFor: ["voice-driven laptop navigation", "game launcher setup", "cloud gaming login flows", "desktop playtesting"],
            sourceInspirations: ["printing-press focused CLI pattern", "NitroGen gaming navigation tools", "macOS ScreenCaptureKit/CGEvent bridge"],
            notes: ["Defaults to JSON action plans; pass --execute for local macOS actions", "Requires macOS Screen Recording and Accessibility permissions for full control"]
        )
    ]

    public static func list(
        kind: GameCLIStarterKind? = nil,
        capability: GameCLIStarterCapability? = nil,
        inputModality: GameCLIInputModality? = nil,
        ids: [String] = []
    ) throws -> [GameCLIStarterDescriptor] {
        let selected = ids.isEmpty ? all : try ids.map { try require(id: $0) }
        return selected.filter { starter in
            if let kind, starter.kind != kind { return false }
            if let capability, !starter.capabilities.contains(capability) { return false }
            if let inputModality, !starter.inputModalities.contains(inputModality) { return false }
            return true
        }
    }

    public static func require(id: String) throws -> GameCLIStarterDescriptor {
        let normalized = normalize(id)
        guard let descriptor = all.first(where: { normalize($0.id) == normalized }) else {
            throw GameHarnessError.cliStarterNotFound(id)
        }
        return descriptor
    }

    static func normalize(_ id: String) -> String {
        id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

public enum GameCLIStarterFactory {
    public static func make(starterID: String, title: String, executableName: String? = nil) throws -> GameCLIStarterScaffold {
        let starter = try GameCLIStarterCatalog.require(id: starterID)
        let cleanTitle = try normalizedTitle(title)
        let executable = try normalizedExecutableName(executableName ?? cleanTitle)
        let package = executable.replacingOccurrences(of: "-", with: "_")
        let files = [
            GameCLIStarterFile(path: "pyproject.toml", body: pyproject(executable: executable, package: package, title: cleanTitle)),
            GameCLIStarterFile(path: "README.md", body: readme(starter: starter, executable: executable, title: cleanTitle)),
            GameCLIStarterFile(path: "src/\(package)/__init__.py", body: "__all__ = []\n"),
            GameCLIStarterFile(path: "src/\(package)/cli.py", body: cliSource(starter: starter, executable: executable, title: cleanTitle))
        ]
        return GameCLIStarterScaffold(
            id: "cli.\(starter.id).\(executable)",
            starterID: starter.id,
            title: cleanTitle,
            executableName: executable,
            agentName: CartridgeDefaults.agentName,
            kind: starter.kind,
            files: files
        )
    }

    private static func normalizedTitle(_ title: String) throws -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw GameHarnessError.invalidCLIStarterTitle(title) }
        return trimmed
    }

    private static func normalizedExecutableName(_ value: String) throws -> String {
        let lowered = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allowed = lowered.map { character -> Character in
            if character.isLetter || character.isNumber || character == "-" { return character }
            if character == "_" || character == " " { return "-" }
            return "-"
        }
        let collapsed = String(allowed)
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        guard !collapsed.isEmpty else { throw GameHarnessError.invalidExecutableName(value) }
        return collapsed.hasSuffix("-cli") ? collapsed : "\(collapsed)-cli"
    }

    private static func pyproject(executable: String, package: String, title: String) -> String {
        #"""
[project]
name = "__EXECUTABLE__"
version = "0.1.0"
description = "__TITLE__ Cartridge CLI starter"
requires-python = ">=3.11"
dependencies = []

[project.scripts]
__EXECUTABLE__ = "__PACKAGE__.cli:main"
"""#
        .replacingOccurrences(of: "__EXECUTABLE__", with: executable)
        .replacingOccurrences(of: "__PACKAGE__", with: package)
        .replacingOccurrences(of: "__TITLE__", with: title)
    }

    private static func readme(starter: GameCLIStarterDescriptor, executable: String, title: String) -> String {
        """
        # \(title)

        Generated by Cartridge from `\(starter.id)`.

        ```bash
        python -m pip install -e .
        \(executable) --help
        \(executable) prompt --text "start a local WebGPU dungeon crawler" --json
        \(executable) prompt --voice-transcript "load the localhost game and explain the controls" --json
        ```

        Agent: Cartridge
        Commands: \(starter.commandGroups.joined(separator: ", "))
        """
    }

    private static func cliSource(starter: GameCLIStarterDescriptor, executable: String, title: String) -> String {
        switch starter.kind {
        case .game:
            return filled(template: gameCLI, executable: executable, title: title, kind: starter.kind.rawValue)
        case .agent:
            return filled(template: agentCLI, executable: executable, title: title, kind: starter.kind.rawValue)
        case .character:
            return filled(template: characterCLI, executable: executable, title: title, kind: starter.kind.rawValue)
        case .laptop:
            return filled(template: laptopCLI, executable: executable, title: title, kind: starter.kind.rawValue)
        }
    }

    private static func filled(template: String, executable: String, title: String, kind: String) -> String {
        template
            .replacingOccurrences(of: "__EXECUTABLE__", with: executable)
            .replacingOccurrences(of: "__TITLE__", with: title)
            .replacingOccurrences(of: "__KIND__", with: kind)
    }

}
