// SwooshArena/Game3DGenerationCatalog+Assets.swift — Cartridge 3D asset libraries (0.1A)

import Foundation

extension Game3DGenerationCatalog {
    static let assetProviders: [Game3DProviderDescriptor] = [
        makeProvider(
            id: "sketchfab",
            displayName: "Sketchfab",
            deployment: .assetLibrary,
            websiteURL: "https://sketchfab.com/developers/download-api",
            capabilities: [.assetSearch],
            requiredSecretNames: ["SKETCHFAB_TOKEN"],
            defaultOutputFormats: [.gltf, .glb, .usdz],
            integrationIDs: ["threejs", "unity", "unreal", "blender"],
            models: [],
            strengths: ["Large Creative Commons asset search and download surface."],
            limitations: ["Licenses and attribution must be preserved per asset."],
            sourceURLs: ["https://sketchfab.com/developers/download-api"]
        ),
        makeProvider(
            id: "poly-haven",
            displayName: "Poly Haven",
            deployment: .assetLibrary,
            websiteURL: "https://polyhaven.com",
            capabilities: [.assetSearch],
            requiredSecretNames: [],
            defaultOutputFormats: [.glb, .gltf, .usd, .fbx, .obj],
            integrationIDs: ["threejs", "unity", "unreal", "blender"],
            models: [],
            strengths: ["CC0 assets work well for generated-game placeholders and environments."],
            limitations: ["Commercial API use needs a custom license or sponsorship."],
            sourceURLs: ["https://polyhaven.com/license", "https://polyhaven.com/af/our-api"]
        ),
        makeProvider(
            id: "fab",
            displayName: "Fab",
            deployment: .assetLibrary,
            websiteURL: "https://dev.epicgames.com/documentation/en-us/fab/fab-documentation",
            capabilities: [.assetSearch],
            requiredSecretNames: [],
            defaultOutputFormats: [.glb, .gltf, .usd, .fbx, .obj],
            integrationIDs: ["unity", "unreal", "fortnite-uefn", "blender"],
            models: [],
            strengths: ["Marketplace path for Unreal, Unity, Sketchfab Store, Quixel, and ArtStation assets."],
            limitations: ["Per-listing license review is mandatory before generated content packs ship."],
            sourceURLs: ["https://dev.epicgames.com/documentation/en-us/fab/fab-documentation"]
        ),
        makeProvider(
            id: "low-poly",
            displayName: "Low-Poly",
            deployment: .assetProcessing,
            websiteURL: "https://low-poly.com/docs/api",
            capabilities: [.formatConversion, .lodGeneration, .retopology],
            requiredSecretNames: ["LOW_POLY_API_KEY"],
            defaultOutputFormats: [.glb, .gltf, .fbx, .obj, .stl, .ply],
            integrationIDs: ["threejs", "webgpu", "unity", "unreal"],
            models: [],
            strengths: ["Decimation, LOD, pivot, batch, and format-conversion steps after generation."],
            limitations: ["Processes existing meshes; it is not a generation model."],
            sourceURLs: ["https://low-poly.com/docs/api"]
        ),
        makeProvider(
            id: "khronos-gltf-sample-assets",
            displayName: "Khronos glTF Sample Assets",
            deployment: .assetLibrary,
            websiteURL: "https://github.com/KhronosGroup/glTF-Sample-Assets",
            capabilities: [.assetSearch, .validation],
            requiredSecretNames: [],
            defaultOutputFormats: [.glb, .gltf],
            integrationIDs: ["threejs", "webgpu"],
            models: [],
            strengths: ["Reference assets for GLB/glTF loader validation and visual regression tests."],
            limitations: ["Samples are validation fixtures, not a production marketplace."],
            sourceURLs: ["https://github.com/KhronosGroup/glTF-Sample-Assets"]
        )
    ]
}
