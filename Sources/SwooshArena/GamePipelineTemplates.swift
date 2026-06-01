// SwooshArena/GamePipelineTemplates.swift — Cartridge pipeline templates (0.1B)

import Foundation
import SwooshTools

public enum GamePipelineTemplateCatalog {
    public static func list(integrationID: String? = nil) throws -> [GamePipeline] {
        if let integrationID {
            let integration = try GameIntegrationCatalog.require(id: integrationID)
            return try templates().filter { pipeline in
                templateIntegrations[pipeline.id]?.contains(integration.id) == true
            }
        }
        return try templates()
    }

    public static func require(id: String) throws -> GamePipeline {
        guard let pipeline = try templates().first(where: { $0.id == id }) else {
            throw GameHarnessError.pipelineNotFound(id)
        }
        return pipeline
    }

    private static func templates() throws -> [GamePipeline] {
        [
            try webRuntimePipeline(),
            try enginePluginPipeline(),
            try assetPipeline(),
            try twoDAssetStudioPipeline()
        ]
    }

    private static let templateIntegrations: [String: Set<String>] = [
        "pipeline.web-runtime": ["threejs", "webgpu"],
        "pipeline.engine-plugin": ["unity", "unreal", "roblox", "fortnite-uefn", "minecraft"],
        "pipeline.asset-export": ["blender", "3ds-max", "unity", "unreal"],
        "pipeline.2d-asset-studio": ["threejs", "webgpu", "unity", "godot"]
    ]

    private static func webRuntimePipeline() throws -> GamePipeline {
        let ingest = GamePipelineNode(
            id: "web.ingest",
            kind: .ingest,
            title: "Load local URL",
            config: .object(["integrationID": .string("threejs")])
        )
        let scaffold = GamePipelineNode(
            id: "web.scaffold",
            kind: .runtimeScaffold,
            title: "Initialize runtime starter",
            config: .object(["templates": .array([.string("threeJS"), .string("webGPU")])])
        )
        let simulation = GamePipelineNode(
            id: "web.simulation",
            kind: .simulation,
            title: "Run deterministic simulation state",
            config: .object(["stateLocation": .string("src/simulation.ts")])
        )
        let render = GamePipelineNode(
            id: "web.render",
            kind: .render,
            title: "Render WebGL or WebGPU frame",
            config: .object(["rendererBoundary": .string("adapter")])
        )
        let playtest = GamePipelineNode(
            id: "web.playtest",
            kind: .playtest,
            title: "Record Cartridge playtest trajectory",
            config: .object(["agent": .string(CartridgeDefaults.agentName)])
        )
        return try GamePipeline(
            id: "pipeline.web-runtime",
            name: "Web runtime playable scaffold",
            nodes: [ingest, scaffold, simulation, render, playtest],
            edges: [
                GamePipelineEdge(sourceNodeID: ingest.id, targetNodeID: scaffold.id),
                GamePipelineEdge(sourceNodeID: scaffold.id, targetNodeID: simulation.id),
                GamePipelineEdge(sourceNodeID: simulation.id, targetNodeID: render.id),
                GamePipelineEdge(sourceNodeID: render.id, targetNodeID: playtest.id)
            ]
        )
    }

    private static func enginePluginPipeline() throws -> GamePipeline {
        let bridge = GamePipelineNode(
            id: "engine.bridge",
            kind: .pluginBridge,
            title: "Install engine bridge",
            config: .object(["integrationID": .string("unity")])
        )
        let importNode = GamePipelineNode(
            id: "engine.import",
            kind: .assetImport,
            title: "Import generated content pack",
            config: .object(["formats": .array([.string("json"), .string("glb")])])
        )
        let adapter = GamePipelineNode(
            id: "engine.adapter",
            kind: .engineAdapter,
            title: "Map Cartridge actions to engine hooks",
            config: .object(["mode": .string("editor")])
        )
        let telemetry = GamePipelineNode(
            id: "engine.telemetry",
            kind: .telemetry,
            title: "Capture playtest telemetry",
            config: .object(["scope": .string("session")])
        )
        return try GamePipeline(
            id: "pipeline.engine-plugin",
            name: "Engine plugin content bridge",
            nodes: [bridge, importNode, adapter, telemetry],
            edges: [
                GamePipelineEdge(sourceNodeID: bridge.id, targetNodeID: importNode.id),
                GamePipelineEdge(sourceNodeID: importNode.id, targetNodeID: adapter.id),
                GamePipelineEdge(sourceNodeID: adapter.id, targetNodeID: telemetry.id)
            ]
        )
    }

    private static func assetPipeline() throws -> GamePipeline {
        let generate = GamePipelineNode(
            id: "asset.generate",
            kind: .assetGeneration,
            title: "Generate character or prop asset",
            config: .object(["integrationID": .string("blender")])
        )
        let dcc = GamePipelineNode(
            id: "asset.dcc",
            kind: .pluginBridge,
            title: "Open DCC import bridge",
            config: .object(["tools": .array([.string("blender"), .string("3ds-max")])])
        )
        let export = GamePipelineNode(
            id: "asset.export",
            kind: .export,
            title: "Export game-ready package",
            config: .object(["formats": .array([.string("glb"), .string("fbx"), .string("usd")])])
        )
        return try GamePipeline(
            id: "pipeline.asset-export",
            name: "DCC asset generation and export",
            nodes: [generate, dcc, export],
            edges: [
                GamePipelineEdge(sourceNodeID: generate.id, targetNodeID: dcc.id),
                GamePipelineEdge(sourceNodeID: dcc.id, targetNodeID: export.id)
            ]
        )
    }

    private static func twoDAssetStudioPipeline() throws -> GamePipeline {
        let anchor = GamePipelineNode(
            id: "twod.anchor",
            kind: .aiGeneration,
            title: "Lock canonical character or style anchor",
            config: .object(["providers": .array([.string("cartridge-imagegen"), .string("image-extender"), .string("dreamsprites")])])
        )
        let sheet = GamePipelineNode(
            id: "twod.sheet",
            kind: .assetGeneration,
            title: "Generate sprites, tiles, props, or parallax layers",
            config: .object(["formats": .array([.string("png"), .string("spriteSheet"), .string("json")])])
        )
        let normalize = GamePipelineNode(
            id: "twod.normalize",
            kind: .assetProcessing,
            title: "Normalize frames, alpha, scale, baseline, and seams",
            config: .object(["checks": .array([.string("transparent-alpha"), .string("baseline"), .string("tile-seams"), .string("twin-detection")])])
        )
        let package = GamePipelineNode(
            id: "twod.package",
            kind: .export,
            title: "Package engine-ready 2D asset manifest",
            config: .object(["formats": .array([.string("png"), .string("spriteSheet"), .string("json"), .string("phaser"), .string("unity"), .string("godot")])])
        )
        return try GamePipeline(
            id: "pipeline.2d-asset-studio",
            name: "2D sprite, tile, parallax, and prop studio",
            nodes: [anchor, sheet, normalize, package],
            edges: [
                GamePipelineEdge(sourceNodeID: anchor.id, targetNodeID: sheet.id),
                GamePipelineEdge(sourceNodeID: sheet.id, targetNodeID: normalize.id),
                GamePipelineEdge(sourceNodeID: normalize.id, targetNodeID: package.id)
            ]
        )
    }
}
