// SwooshToolsets/Exports.swift — Default Tool Registration (0.4B)
//
// Registers the Cartridge agent-facing surface into the ToolRegistry:
// core introspection, game harness tools, game asset generation, and NitroGen.

import Foundation
import SwooshTools
import SwooshImageGen
import SwooshMusic

// ═══════════════════════════════════════════════════════════════════
// MARK: - Media generation dependencies
// ═══════════════════════════════════════════════════════════════════

/// Optional bundle of provider instances for media-generation tools.
/// Passing `nil` for any field skips registering that tool. Wire the
/// providers daemon-side using `CapabilityRouter.activeXProvider()` so
/// the picker's selection drives which model the agent reaches.
public struct MediaGenDependencies: Sendable {
    public let imageProvider: (any ImageGenProviding)?
    public let videoProvider: (any VideoGenProviding)?
    public let threeDProvider: (any ThreeDGenProviding)?
    public let musicProvider: (any MusicProviding)?
    public let cacheDir: URL?
    public let audioDownloader: (any AudioDownloading)?

    public init(
        imageProvider: (any ImageGenProviding)? = nil,
        videoProvider: (any VideoGenProviding)? = nil,
        threeDProvider: (any ThreeDGenProviding)? = nil,
        musicProvider: (any MusicProviding)? = nil,
        cacheDir: URL? = nil,
        audioDownloader: (any AudioDownloading)? = nil
    ) {
        self.imageProvider = imageProvider
        self.videoProvider = videoProvider
        self.threeDProvider = threeDProvider
        self.musicProvider = musicProvider
        self.cacheDir = cacheDir
        self.audioDownloader = audioDownloader
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Default tool registrar
// ═══════════════════════════════════════════════════════════════════

public enum DefaultToolRegistrar {
    public static func registerAll(
        into registry: ToolRegistry,
        dependencies: ToolDependencies,
        mediaGen: MediaGenDependencies? = nil,
        gameHarness: GameHarnessToolDependencies? = nil,
        nitrogen: NitroGenController? = nil
    ) async {
        await registerCore(into: registry, dependencies: dependencies)
        if let mediaGen = mediaGen {
            await registerMediaGen(into: registry, mediaGen: mediaGen)
        }
        await registerGameHarness(
            into: registry,
            dependencies: gameHarness ?? GameHarnessToolDependencies(firewall: dependencies.firewall)
        )
        #if os(macOS)
        if let nitrogen = nitrogen {
            await registerNitroGen(into: registry, controller: nitrogen)
        }
        #endif
    }

    // ── Core ──────────────────────────────────────────────────────
    static func registerCore(into registry: ToolRegistry, dependencies: ToolDependencies) async {
        await registry.register(TypeErasedTool(CoreStatusTool(dependencies: dependencies)))
        await registry.register(TypeErasedTool(ExplainContextTool(dependencies: dependencies)))
        await registry.register(TypeErasedTool(ListToolsetsTool(dependencies: dependencies)))
        await registry.register(TypeErasedTool(ListToolsTool(dependencies: dependencies, registry: registry)))
        await registry.register(TypeErasedTool(GetToolSchemaTool(dependencies: dependencies, registry: registry)))
    }

    static func registerGameHarness(into registry: ToolRegistry, dependencies: GameHarnessToolDependencies) async {
        await registry.register(TypeErasedTool(GameListSessionsTool(dependencies: dependencies)))
        await registry.register(TypeErasedTool(GameListIntegrationsTool(dependencies: dependencies)))
        await registry.register(TypeErasedTool(GameListPipelineTemplatesTool(dependencies: dependencies)))
        await registry.register(TypeErasedTool(GameLoadLocalURLTool(dependencies: dependencies)))
        await registry.register(TypeErasedTool(GameInitProjectTool(dependencies: dependencies)))
        await registry.register(TypeErasedTool(GameRecordObservationTool(dependencies: dependencies)))
        await registry.register(TypeErasedTool(GameRecordActionTool(dependencies: dependencies)))
        await registry.register(TypeErasedTool(GameGenerateContentTool(dependencies: dependencies)))
        await registry.register(TypeErasedTool(GameSavePipelineTool(dependencies: dependencies)))
        await registry.register(TypeErasedTool(GameImportPipelineTool(dependencies: dependencies)))
        await registry.register(TypeErasedTool(GameEvaluateSessionTool(dependencies: dependencies)))
    }

    // ── NitroGen (gaming agent) ───────────────────────────────────
    #if os(macOS)
    static func registerNitroGen(into registry: ToolRegistry, controller: NitroGenController) async {
        await registry.register(TypeErasedTool(NitroGenStartTool(controller: controller)))
        await registry.register(TypeErasedTool(NitroGenStopTool(controller: controller)))
        await registry.register(TypeErasedTool(NitroGenStatusTool(controller: controller)))
        await registry.register(TypeErasedTool(NitroGenScreenshotTool(controller: controller)))

        // Gaming navigation tools (voice-driven game search/click/type)
        await registry.register(TypeErasedTool(GamingSearchGameTool()))
        await registry.register(TypeErasedTool(GamingClickElementTool()))
        await registry.register(TypeErasedTool(GamingTypeTextTool()))
        await registry.register(TypeErasedTool(GamingNavigateURLTool()))
        await registry.register(TypeErasedTool(GamingScreenshotWebTool()))
        await registry.register(TypeErasedTool(GamingSelectPlatformTool()))
    }
    #endif
}
