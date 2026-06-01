// Tests/SwooshToolsetsTests/GameHarnessToolsTests.swift

import Foundation
import Testing
@testable import SwooshArena
@testable import SwooshFiles
@testable import SwooshFirewall
@testable import SwooshProcess
@testable import SwooshToolsets
@testable import SwooshTools

private func gameRegistry() -> (ToolRegistry, SwooshFirewallActor) {
    let firewall = SwooshFirewallActor()
    let audit = SwooshAuditLog()
    let approvals = InMemoryApprovalRequester(autoApprove: true)
    return (ToolRegistry(firewall: firewall, audit: audit, approvals: approvals), firewall)
}

private func jsonInput<T: Encodable>(_ input: T) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(input))
}

@Suite("GameHarnessTools descriptors")
struct GameHarnessToolsDescriptorTests {
    @Test("tools use Cartridge gaming permissions")
    func descriptors() {
        #expect(GameListSessionsTool.permission == .gameObserve)
        #expect(GameListIntegrationsTool.permission == .gameObserve)
        #expect(GameListPipelineTemplatesTool.permission == .gameObserve)
        #expect(GameLoadLocalURLTool.permission == .gameLoad)
        #expect(GameInitProjectTool.permission == .gameGenerate)
        #expect(GameRecordActionTool.permission == .gameAct)
        #expect(GameGenerateContentTool.permission == .gameGenerate)
        #expect(GameEvaluateSessionTool.permission == .gameEvaluate)
        #expect(GameLoadLocalURLTool.toolset == .gaming)
    }
}

@Suite("GameHarnessTools registry")
struct GameHarnessToolsRegistryTests {
    @Test("registers Cartridge game harness tools")
    func registersTools() async {
        let (registry, firewall) = gameRegistry()
        await firewall.grantAll(Set(SwooshPermission.allCases))
        await DefaultToolRegistrar.registerGameHarness(
            into: registry,
            dependencies: GameHarnessToolDependencies(firewall: firewall)
        )
        let names = Set(await registry.listAvailable(context: ToolContext(sessionID: "t")).map(\.name))
        #expect(names.contains("game.load_local_url"))
        #expect(names.contains("game.list_integrations"))
        #expect(names.contains("game.list_pipeline_templates"))
        #expect(names.contains("game.init_project"))
        #expect(names.contains("game.generate_content"))
        #expect(names.contains("game.evaluate_session"))
    }

    @Test("loads a local URL and records generated content")
    func loadAndGenerateContent() async throws {
        let (registry, firewall) = gameRegistry()
        await firewall.grantAll([.gameLoad, .gameGenerate, .gameObserve, .networkAccess, .fileRead])
        let harness = CartridgeHarness()
        await DefaultToolRegistrar.registerGameHarness(
            into: registry,
            dependencies: GameHarnessToolDependencies(harness: harness, firewall: firewall)
        )
        let loadInput = GameLoadLocalURLTool.Input(
            title: "Quest Lab",
            urlString: "http://localhost:3000",
            mode: .create,
            policies: [
                GamePolicyInput(
                    id: "hybrid.openrouter.test",
                    displayName: "OpenRouter Test + NitroGen",
                    kind: .hybrid,
                    providerID: "openrouter",
                    modelID: "anthropic/claude-sonnet-4.5",
                    responsibilities: ["reasoning", "frame_action", "test_oracle"],
                    usesNitroGen: true
                )
            ]
        )
        let loadOutputJSON = try await registry.call(
            name: "game.load_local_url",
            input: try jsonInput(loadInput),
            context: ToolContext(sessionID: "tool-test", isModelInvocation: false)
        )
        let loadOutput = try JSONDecoder().decode(GameLoadLocalURLTool.Output.self, from: JSONEncoder().encode(loadOutputJSON))
        #expect(loadOutput.agentName == "Cartridge")
        #expect(loadOutput.session.mode == .create)
        #expect(loadOutput.session.policies[0].kind == .hybrid)

        let contentInput = GameGenerateContentTool.Input(
            sessionID: loadOutput.session.id,
            kind: .character,
            title: "Market Oracle",
            body: .object(["role": .string("merchant")]),
            exportFormats: [.json, .unity]
        )
        let contentOutputJSON = try await registry.call(
            name: "game.generate_content",
            input: try jsonInput(contentInput),
            context: ToolContext(sessionID: "tool-test", isModelInvocation: false)
        )
        let contentOutput = try JSONDecoder().decode(GameGenerateContentTool.Output.self, from: JSONEncoder().encode(contentOutputJSON))
        #expect(contentOutput.artifact.kind == .character)
        #expect(contentOutput.session.artifacts.count == 1)
    }

    @Test("lists integrations and initializes a WebGPU project")
    func listAndInitProject() async throws {
        let (registry, firewall) = gameRegistry()
        await firewall.grantAll([.gameObserve, .gameGenerate])
        let harness = CartridgeHarness()
        await DefaultToolRegistrar.registerGameHarness(
            into: registry,
            dependencies: GameHarnessToolDependencies(harness: harness, firewall: firewall)
        )

        let integrationsJSON = try await registry.call(
            name: "game.list_integrations",
            input: try jsonInput(GameListIntegrationsTool.Input(kind: nil, ids: ["threejs", "webgpu", "unity"])),
            context: ToolContext(sessionID: "tool-test", isModelInvocation: false)
        )
        let integrationsOutput = try JSONDecoder().decode(GameListIntegrationsTool.Output.self, from: JSONEncoder().encode(integrationsJSON))
        #expect(integrationsOutput.agentName == "Cartridge")
        #expect(integrationsOutput.integrations.map(\.id) == ["threejs", "webgpu", "unity"])

        let initInput = GameInitProjectTool.Input(
            title: "GPU Arena",
            template: .webGPU,
            mode: .create,
            policies: [
                GamePolicyInput(
                    id: "nitrogen",
                    displayName: "NitroGen",
                    kind: .nitroGen,
                    providerID: nil,
                    modelID: nil,
                    responsibilities: ["frame_action"],
                    usesNitroGen: true
                )
            ],
            outputDirectory: nil
        )
        let initJSON = try await registry.call(
            name: "game.init_project",
            input: try jsonInput(initInput),
            context: ToolContext(sessionID: "tool-test", isModelInvocation: false)
        )
        let initOutput = try JSONDecoder().decode(GameInitProjectTool.Output.self, from: JSONEncoder().encode(initJSON))
        #expect(initOutput.session.target.kind == .generatedGame)
        #expect(initOutput.session.artifacts.count == 1)
        #expect(initOutput.session.pipelines.map(\.id) == ["pipeline.web-runtime"])
        #expect(initOutput.scaffold.files.contains { $0.path == "src/shaders.wgsl" })
        #expect(initOutput.writtenFiles.isEmpty)
    }

    @Test("initializes a project on disk when file write is granted")
    func initProjectWritesFiles() async throws {
        let (registry, firewall) = gameRegistry()
        await firewall.grantAll([.gameGenerate, .fileWrite])
        let harness = CartridgeHarness()
        await DefaultToolRegistrar.registerGameHarness(
            into: registry,
            dependencies: GameHarnessToolDependencies(harness: harness, firewall: firewall)
        )
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("cartridge-scaffold-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        let input = GameInitProjectTool.Input(
            title: "Three Arena",
            template: .threeJS,
            mode: .create,
            policies: [
                GamePolicyInput(
                    id: "nitrogen",
                    displayName: "NitroGen",
                    kind: .nitroGen,
                    providerID: nil,
                    modelID: nil,
                    responsibilities: ["frame_action"],
                    usesNitroGen: true
                )
            ],
            outputDirectory: root.path
        )
        let outputJSON = try await registry.call(
            name: "game.init_project",
            input: try jsonInput(input),
            context: ToolContext(sessionID: "tool-test", isModelInvocation: false)
        )
        let output = try JSONDecoder().decode(GameInitProjectTool.Output.self, from: JSONEncoder().encode(outputJSON))

        #expect(output.writtenFiles.contains(root.appendingPathComponent("package.json").path))
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("src/main.ts").path))
    }

    @Test("firewall denies ungranted game load")
    func firewallDeniesLoad() async throws {
        let (registry, firewall) = gameRegistry()
        await DefaultToolRegistrar.registerGameHarness(
            into: registry,
            dependencies: GameHarnessToolDependencies(firewall: firewall)
        )
        let input = GameLoadLocalURLTool.Input(
            title: "Blocked",
            urlString: "http://localhost:3000",
            mode: .test,
            policies: [
                GamePolicyInput(
                    id: "nitrogen",
                    displayName: "NitroGen",
                    kind: .nitroGen,
                    providerID: nil,
                    modelID: nil,
                    responsibilities: ["frame_action"],
                    usesNitroGen: true
                )
            ]
        )
        await #expect(throws: ToolError.self) {
            _ = try await registry.call(
                name: "game.load_local_url",
                input: try jsonInput(input),
                context: ToolContext(sessionID: "tool-test", isModelInvocation: false)
            )
        }
    }
}
