// Tests/SwooshArenaTests/GameHarnessTests.swift

import Foundation
import Testing
@testable import SwooshArena
@testable import SwooshTools

@Suite("GameURLPolicy")
struct GameURLPolicyTests {
    @Test("allows localhost and file URLs")
    func allowsLocalURLs() throws {
        #expect(try GameURLPolicy.validateLocalGameURL("http://localhost:5173").host == "localhost")
        #expect(try GameURLPolicy.validateLocalGameURL("http://127.0.0.1:8080").host == "127.0.0.1")
        #expect(try GameURLPolicy.validateLocalGameURL("file:///tmp/game/index.html").scheme == "file")
    }

    @Test("rejects remote hosts")
    func rejectsRemoteHosts() throws {
        #expect(throws: GameHarnessError.self) {
            try GameURLPolicy.validateLocalGameURL("https://example.com/game")
        }
    }
}

@Suite("CartridgeHarness")
struct CartridgeHarnessTests {
    @Test("loads local URL with hybrid LLM policy")
    func loadLocalURL() async throws {
        let harness = CartridgeHarness()
        let session = try await harness.loadLocalURL(
            title: "Dungeon QA",
            urlString: "http://localhost:3000",
            mode: .test,
            policies: [
                .hybrid(providerID: "openrouter", modelID: "anthropic/claude-sonnet-4.5")
            ]
        )
        #expect(session.title == "Dungeon QA")
        #expect(session.target.kind == .localURL)
        #expect(session.policies[0].kind == .hybrid)
        #expect(session.policies[0].usesNitroGen)
        #expect(try await harness.listSessions().count == 1)
    }

    @Test("records observations, actions, artifacts, pipelines, and evaluations")
    func recordsHarnessData() async throws {
        let harness = CartridgeHarness()
        let session = try await harness.loadLocalURL(
            title: "Arena",
            urlString: "http://localhost:3000",
            mode: .play,
            policies: [.nitroGen]
        )
        let observation = GameObservation(summary: "spawned", state: .object(["hp": .int(100)]))
        let first = try await harness.observe(sessionID: session.id, observation: observation, reward: 0, done: false)
        #expect(first.index == 0)
        let action = GameAction(kind: .move, policyID: "nitrogen", parameters: .object(["direction": .string("north")]))
        let second = try await harness.act(sessionID: session.id, action: action, observation: observation, reward: 0.2, done: false)
        #expect(second.index == 1)
        try await harness.addArtifact(
            sessionID: session.id,
            artifact: GameContentArtifact(kind: .character, title: "Scout", body: .object(["class": .string("ranger")]), exportFormats: [.json, .godot])
        )
        let node = GamePipelineNode(kind: .characterGeneration, title: "Character")
        try await harness.addPipeline(sessionID: session.id, pipeline: try GamePipeline(name: "NPC pack", nodes: [node], edges: []))
        try await harness.addEvaluation(
            sessionID: session.id,
            evaluation: GameEvaluation(kind: .playability, summary: "stable", facts: ["no crash"], score: 0.9)
        )
        let updated = try await harness.requireSession(id: session.id)
        #expect(updated.trajectory.count == 2)
        #expect(updated.artifacts.count == 1)
        #expect(updated.pipelines.count == 1)
        #expect(updated.evaluations.count == 1)
    }
}

@Suite("GameIntegrationCatalog")
struct GameIntegrationCatalogTests {
    @Test("covers requested major game integrations")
    func coversMajorIntegrations() throws {
        let ids = Set(try GameIntegrationCatalog.list().map(\.id))
        #expect(ids.contains("threejs"))
        #expect(ids.contains("webgpu"))
        #expect(ids.contains("unity"))
        #expect(ids.contains("unreal"))
        #expect(ids.contains("blender"))
        #expect(ids.contains("roblox"))
        #expect(ids.contains("fortnite-uefn"))
        #expect(ids.contains("minecraft"))
        #expect(ids.contains("3ds-max"))
        #expect(try GameIntegrationCatalog.require(id: "3ds").id == "3ds-max")
    }

    @Test("builds Three.js and WebGPU starters")
    func buildsWebStarters() throws {
        let three = try GameProjectScaffoldFactory.make(template: .threeJS, title: "Arena Lab")
        let webgpu = try GameProjectScaffoldFactory.make(template: .webGPU, title: "Arena Lab")

        #expect(three.integrationIDs == ["threejs"])
        #expect(three.files.contains { $0.path == "src/main.ts" && $0.body.contains("WebGLRenderer") })
        #expect(three.files.contains { $0.path == "src/simulation.ts" })
        #expect(webgpu.integrationIDs == ["webgpu"])
        #expect(webgpu.files.contains { $0.path == "src/shaders.wgsl" })
        #expect(webgpu.files.contains { $0.path == "src/main.ts" && $0.body.contains("navigator.gpu") })
    }

    @Test("filters pipeline templates by integration")
    func filtersPipelineTemplates() throws {
        #expect(try GamePipelineTemplateCatalog.list(integrationID: "threejs").map(\.id) == ["pipeline.web-runtime"])
        #expect(try GamePipelineTemplateCatalog.list(integrationID: "blender").map(\.id) == ["pipeline.asset-export"])
    }

    @Test("imports Pipeline React Flow workflow graphs")
    func importsPipelineWorkflowGraph() throws {
        let document = GamePipelineImportDocument(
            id: "workflow-npc-playtest",
            name: "NPC playtest workflow",
            version: "3.0-june-2026",
            nodes: [
                GamePipelineImportNode(
                    id: "1",
                    type: "trigger",
                    data: .object(["label": .string("Start: NPC Generation Request")])
                ),
                GamePipelineImportNode(
                    id: "2",
                    type: "aiGeneration",
                    data: .object(["label": .string("Generate NPC Personality"), "model": .string("claude-sonnet-4-5")])
                ),
                GamePipelineImportNode(
                    id: "3",
                    type: "voiceConfig",
                    data: .object(["label": .string("Configure Voice Profile")])
                ),
                GamePipelineImportNode(
                    id: "4",
                    type: "conditional",
                    data: .object(["label": .string("Needs another pass?")])
                ),
                GamePipelineImportNode(
                    id: "5",
                    type: "export",
                    data: .object(["label": .string("Export NPC Package"), "formats": .array([.string("unity"), .string("elizaos")])]),
                    position: .object(["x": .int(200), "y": .int(500)])
                )
            ],
            edges: [
                GamePipelineImportEdge(id: "e1-2", source: "1", target: "2"),
                GamePipelineImportEdge(id: "e2-3", source: "2", target: "3"),
                GamePipelineImportEdge(id: "e3-4", source: "3", target: "4"),
                GamePipelineImportEdge(id: "e4-5", source: "4", target: "5")
            ]
        )

        let pipeline = try document.pipeline(defaultName: "Imported")

        #expect(pipeline.id == "workflow-npc-playtest")
        #expect(pipeline.name == "NPC playtest workflow")
        #expect(pipeline.nodes.map(\.kind) == [.trigger, .aiGeneration, .voiceConfig, .conditional, .export])
        #expect(pipeline.nodes[1].title == "Generate NPC Personality")
        #expect(pipeline.edges.map(\.sourceNodeID) == ["1", "2", "3", "4"])
        #expect(pipeline.nodes[4].config == .object([
            "sourceType": .string("export"),
            "sourceVersion": .string("3.0-june-2026"),
            "data": .object(["label": .string("Export NPC Package"), "formats": .array([.string("unity"), .string("elizaos")])]),
            "position": .object(["x": .int(200), "y": .int(500)])
        ]))
    }

    @Test("rejects unsupported Pipeline node types")
    func rejectsUnsupportedPipelineNodeTypes() throws {
        let document = GamePipelineImportDocument(
            nodes: [GamePipelineImportNode(id: "1", type: "unknownWidget")],
            edges: []
        )

        #expect(throws: GameHarnessError.self) {
            _ = try document.pipeline(defaultName: "Broken")
        }
    }
}

@Suite("Game3DGenerationCatalog")
struct Game3DGenerationCatalogTests {
    @Test("covers cloud, local, and asset 3D providers")
    func coversProviderSurface() throws {
        let ids = Set(Game3DGenerationCatalog.all.map(\.id))

        #expect(ids.contains("fal-ai"))
        #expect(ids.contains("meshy"))
        #expect(ids.contains("tripo"))
        #expect(ids.contains("hyper3d-rodin"))
        #expect(ids.contains("stability-ai-3d"))
        #expect(ids.contains("microsoft-trellis"))
        #expect(ids.contains("tencent-hunyuan3d"))
        #expect(ids.contains("triposr"))
        #expect(ids.contains("sketchfab"))
        #expect(ids.contains("poly-haven"))
        #expect(ids.contains("fab"))
        #expect(ids.contains("low-poly"))
        #expect(ids.contains("khronos-gltf-sample-assets"))

        let fal = try Game3DGenerationCatalog.require(id: "fal-ai")
        #expect(fal.models.contains { $0.id == "fal-ai/hunyuan-3d/v3.1/pro/text-to-3d" })
        #expect(fal.models.contains { $0.id == "fal-ai/trellis-2" })
    }

    @Test("filters local-hostable and text-capable providers")
    func filtersProviders() throws {
        let local = try Game3DGenerationCatalog.list(localHostableOnly: true)
        let localIDs = Set(local.map(\.id))
        #expect(localIDs.contains("microsoft-trellis"))
        #expect(localIDs.contains("tencent-hunyuan3d"))
        #expect(localIDs.contains("triposr"))

        let cloudText = try Game3DGenerationCatalog.list(
            deployment: .cloudAPI,
            supportsTextInput: true,
            capability: .textTo3D
        )
        let cloudTextIDs = Set(cloudText.map(\.id))
        #expect(cloudTextIDs.contains("fal-ai"))
        #expect(cloudTextIDs.contains("meshy"))
        #expect(cloudTextIDs.contains("tripo"))
        #expect(cloudTextIDs.contains("hyper3d-rodin"))
    }
}
