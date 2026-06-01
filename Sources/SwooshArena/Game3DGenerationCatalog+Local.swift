// SwooshArena/Game3DGenerationCatalog+Local.swift — Cartridge local 3D providers (0.1A)

import Foundation

extension Game3DGenerationCatalog {
    static let localProviders: [Game3DProviderDescriptor] = [
        makeProvider(
            id: "microsoft-trellis",
            displayName: "Microsoft TRELLIS",
            deployment: .localHostable,
            websiteURL: "https://github.com/microsoft/TRELLIS.2",
            capabilities: [.imageTo3D, .textureGeneration, .pbrMaterials, .retopology],
            requiredSecretNames: [],
            defaultOutputFormats: [.glb, .obj, .ply],
            integrationIDs: ["threejs", "webgpu", "unity", "unreal", "blender"],
            models: [
                makeModel(
                    id: "microsoft/TRELLIS.2-4B",
                    displayName: "TRELLIS.2 4B",
                    providerID: "microsoft-trellis",
                    deployment: .localHostable,
                    capabilities: [.imageTo3D, .textureGeneration, .pbrMaterials],
                    supportsTextInput: false,
                    supportsImageInput: true,
                    outputFormats: [.glb, .obj, .ply],
                    license: "MIT",
                    localRequirements: ["high-memory GPU for full-quality local inference"],
                    recommendedFor: ["best local-hostable image-to-3D candidate"],
                    sourceURLs: ["https://github.com/microsoft/TRELLIS.2", "https://github.com/microsoft/TRELLIS"]
                )
            ],
            strengths: ["Open-source code path.", "Strong local-hosting candidate for private game studios."],
            limitations: ["Needs a local runner adapter before Cartridge can execute it directly."],
            sourceURLs: ["https://github.com/microsoft/TRELLIS.2"]
        ),
        makeProvider(
            id: "tencent-hunyuan3d",
            displayName: "Tencent Hunyuan3D",
            deployment: .localHostable,
            websiteURL: "https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1",
            capabilities: [.textTo3D, .imageTo3D, .multiViewTo3D, .textureGeneration, .pbrMaterials],
            requiredSecretNames: [],
            defaultOutputFormats: [.glb, .obj],
            integrationIDs: ["threejs", "unity", "unreal", "blender"],
            models: [
                makeModel(
                    id: "tencent/Hunyuan3D-2.1",
                    displayName: "Hunyuan3D 2.1",
                    providerID: "tencent-hunyuan3d",
                    deployment: .localHostable,
                    capabilities: [.textTo3D, .imageTo3D, .multiViewTo3D, .textureGeneration, .pbrMaterials],
                    supportsTextInput: true,
                    supportsImageInput: true,
                    outputFormats: [.glb, .obj],
                    license: "Tencent Hunyuan3D model license",
                    localRequirements: ["Python runner", "GPU-backed texture generation recommended"],
                    recommendedFor: ["local studio pipeline for textured assets"],
                    sourceURLs: ["https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1", "https://huggingface.co/tencent/Hunyuan3D-2.1"]
                )
            ],
            strengths: ["Local and hosted ecosystem.", "Good fit for game-ready PBR asset pipelines."],
            limitations: ["License and regional terms must be reviewed per product."],
            sourceURLs: ["https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1"]
        ),
        makeProvider(
            id: "triposr",
            displayName: "TripoSR",
            deployment: .openSource,
            websiteURL: "https://github.com/VAST-AI-Research/TripoSR",
            capabilities: [.imageTo3D],
            requiredSecretNames: [],
            defaultOutputFormats: [.obj, .glb],
            integrationIDs: ["threejs", "unity", "unreal", "blender"],
            models: [
                makeModel(
                    id: "VAST-AI-Research/TripoSR",
                    displayName: "TripoSR",
                    providerID: "triposr",
                    deployment: .localHostable,
                    capabilities: [.imageTo3D],
                    supportsTextInput: false,
                    supportsImageInput: true,
                    outputFormats: [.obj, .glb],
                    license: "MIT",
                    localRequirements: ["Python runner"],
                    recommendedFor: ["fast baseline local reconstruction", "offline fallback"],
                    sourceURLs: ["https://github.com/VAST-AI-Research/TripoSR"]
                )
            ],
            strengths: ["Small, fast, permissive baseline.", "Useful as the first local adapter target."],
            limitations: ["Older quality tier than TRELLIS.2 and Hunyuan3D 2.1."],
            sourceURLs: ["https://github.com/VAST-AI-Research/TripoSR"]
        )
    ]
}
