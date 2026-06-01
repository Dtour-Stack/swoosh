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
        subcommands: [GameCatalogCommand.self, GameCLICommand.self]
    )
}

enum GameCatalogSection: String, ExpressibleByArgument {
    case all
    case integrations
    case cli
    case twoD
    case threeD
    case pipelines
}

struct GameCatalogCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "catalog",
        abstract: "List the Cartridge integrations, creation providers, CLI starters, and pipelines."
    )

    @Option(name: .long, help: "Filter by section: all, integrations, cli, twoD, threeD, or pipelines.")
    var section: GameCatalogSection = .all

    @Flag(name: .long, help: "Emit machine-readable JSON.")
    var json = false

    func run() async throws {
        let result = try GameCatalogCLIResult.current()
        if json {
            try printAsJSON(result.filtered(to: section))
            return
        }
        result.printCatalog(section: section)
    }
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

struct GameCatalogCLIResult: Encodable {
    let agentName: String
    let integrations: [GameIntegrationDescriptor]
    let cliStarters: [GameCLIStarterDescriptor]
    let twoD: [Game2DProviderDescriptor]
    let threeD: [Game3DProviderDescriptor]
    let pipelines: [GamePipeline]

    static func current() throws -> GameCatalogCLIResult {
        try GameCatalogCLIResult(
            agentName: CartridgeDefaults.agentName,
            integrations: GameIntegrationCatalog.all,
            cliStarters: GameCLIStarterCatalog.all,
            twoD: Game2DCreationCatalog.all,
            threeD: Game3DGenerationCatalog.all,
            pipelines: GamePipelineTemplateCatalog.list()
        )
    }

    func filtered(to section: GameCatalogSection) -> GameCatalogCLIResult {
        switch section {
        case .all:
            return self
        case .integrations:
            return GameCatalogCLIResult(agentName: agentName, integrations: integrations, cliStarters: [], twoD: [], threeD: [], pipelines: [])
        case .cli:
            return GameCatalogCLIResult(agentName: agentName, integrations: [], cliStarters: cliStarters, twoD: [], threeD: [], pipelines: [])
        case .twoD:
            return GameCatalogCLIResult(agentName: agentName, integrations: [], cliStarters: [], twoD: twoD, threeD: [], pipelines: [])
        case .threeD:
            return GameCatalogCLIResult(agentName: agentName, integrations: [], cliStarters: [], twoD: [], threeD: threeD, pipelines: [])
        case .pipelines:
            return GameCatalogCLIResult(agentName: agentName, integrations: [], cliStarters: [], twoD: [], threeD: [], pipelines: pipelines)
        }
    }

    func printCatalog(section: GameCatalogSection) {
        let result = filtered(to: section)
        if !result.integrations.isEmpty {
            Swift.print("Integrations")
            for integration in result.integrations {
                Swift.print("  \(integration.id) [\(integration.kind.rawValue)] \(integration.displayName)")
            }
        }
        if !result.cliStarters.isEmpty {
            Swift.print("CLI Starters")
            for starter in result.cliStarters {
                Swift.print("  \(starter.id) [\(starter.kind.rawValue)] \(starter.displayName)")
            }
        }
        if !result.twoD.isEmpty {
            Swift.print("2D Creation")
            for provider in result.twoD {
                Swift.print("  \(provider.id) [\(provider.deployment.rawValue)] \(provider.displayName)")
            }
        }
        if !result.threeD.isEmpty {
            Swift.print("3D Generation")
            for provider in result.threeD {
                Swift.print("  \(provider.id) [\(provider.deployment.rawValue)] \(provider.displayName)")
            }
        }
        if !result.pipelines.isEmpty {
            Swift.print("Pipelines")
            for pipeline in result.pipelines {
                Swift.print("  \(pipeline.id) \(pipeline.name)")
            }
        }
    }
}
