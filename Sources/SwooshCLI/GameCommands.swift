// SwooshCLI/GameCommands.swift — Cartridge game CLI starter commands (0.1A)

import ArgumentParser
import Foundation
import SwooshArena

extension GameCLIStarterKind: ExpressibleByArgument {}
extension GameCLIInputModality: ExpressibleByArgument {}

struct GameCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "game",
        abstract: "Create Cartridge game, agent, and character starter CLIs.",
        subcommands: [GameCLICommand.self]
    )
}

struct GameCLICommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cli",
        abstract: "Discover and generate agent-friendly Cartridge CLIs.",
        subcommands: [GameCLIListCommand.self, GameCLIInitCommand.self]
    )
}

struct GameCLIListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list", abstract: "List Cartridge CLI starters.")

    @Option(name: .long, help: "Filter by kind: game, agent, or character.")
    var kind: GameCLIStarterKind?

    @Option(name: .long, help: "Filter by input modality: textPrompt, voicePrompt, visionCapture, nitroPolicy.")
    var input: GameCLIInputModality?

    @Flag(name: .long, help: "Emit machine-readable JSON.")
    var json = false

    func run() async throws {
        let starters = try GameCLIStarterCatalog.list(kind: kind, inputModality: input)
        if json {
            try printAsJSON(starters)
            return
        }
        for starter in starters {
            print("\(starter.id) [\(starter.kind.rawValue)]")
            print("  \(starter.commandGroups.joined(separator: ", "))")
            print("  inputs: \(starter.inputModalities.map(\.rawValue).joined(separator: ", "))")
        }
    }
}

struct GameCLIInitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "init", abstract: "Generate a Cartridge CLI starter.")

    @Option(name: .long, help: "Starter id: cartridge-game-cli, cartridge-agent-cli, or cartridge-character-cli.")
    var starter: String = "cartridge-game-cli"

    @Option(name: .long, help: "Project, agent, or character title.")
    var title: String

    @Option(name: .long, help: "Generated executable name.")
    var name: String?

    @Option(name: .long, help: "Directory to write the starter into.")
    var output: String?

    @Flag(name: .long, help: "Emit machine-readable JSON.")
    var json = false

    func run() async throws {
        let scaffold = try GameCLIStarterFactory.make(starterID: starter, title: title, executableName: name)
        let writtenFiles: [String]
        if let output {
            writtenFiles = try write(scaffold: scaffold, to: output)
        } else {
            writtenFiles = []
        }
        if json {
            try printAsJSON(GameCLIInitResult(scaffold: scaffold, writtenFiles: writtenFiles))
            return
        }
        print("Generated \(scaffold.executableName)")
        if writtenFiles.isEmpty {
            print("Files: \(scaffold.files.map(\.path).joined(separator: ", "))")
        } else {
            for file in writtenFiles {
                print(file)
            }
        }
    }

    private func write(scaffold: GameCLIStarterScaffold, to outputDirectory: String) throws -> [String] {
        let root = URL(fileURLWithPath: outputDirectory, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true, attributes: nil)
        var writtenFiles: [String] = []
        for file in scaffold.files {
            let relativePath = try validatedRelativePath(file.path)
            let url = root.appendingPathComponent(relativePath, isDirectory: false)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            try file.body.write(to: url, atomically: true, encoding: .utf8)
            writtenFiles.append(url.path)
        }
        return writtenFiles
    }

    private func validatedRelativePath(_ path: String) throws -> String {
        let pieces = path.split(separator: "/").map(String.init)
        guard !pieces.isEmpty, !path.hasPrefix("/"), !pieces.contains("..") else {
            throw ValidationError("invalid generated path: \(path)")
        }
        return pieces.joined(separator: "/")
    }
}

struct GameCLIInitResult: Encodable {
    let scaffold: GameCLIStarterScaffold
    let writtenFiles: [String]
}
