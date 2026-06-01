// SwooshArena/Game3DGenerationCatalog+Cloud.swift — Cartridge cloud 3D providers (0.1A)

import Foundation

extension Game3DGenerationCatalog {
    static let cloudProviders: [Game3DProviderDescriptor] = [
        makeProvider(
            id: "fal-ai",
            displayName: "fal.ai 3D",
            deployment: .cloudAPI,
            websiteURL: "https://fal.ai/models?keywords=3d",
            capabilities: [.textTo3D, .imageTo3D, .multiViewTo3D, .textureGeneration, .pbrMaterials],
            requiredSecretNames: ["FAL_KEY"],
            defaultOutputFormats: [.glb, .obj],
            integrationIDs: ["threejs", "webgpu", "unity", "unreal", "blender"],
            models: [
                makeModel(
                    id: "fal-ai/hunyuan-3d/v3.1/pro/text-to-3d",
                    displayName: "Hunyuan 3D v3.1 Pro Text",
                    providerID: "fal-ai",
                    deployment: .cloudAPI,
                    capabilities: [.textTo3D, .textureGeneration, .pbrMaterials],
                    supportsTextInput: true,
                    supportsImageInput: false,
                    outputFormats: [.glb, .obj],
                    license: "fal commercial API",
                    recommendedFor: ["current cloud default for text-to-3D props and hero assets"],
                    sourceURLs: ["https://fal.ai/models/fal-ai/hunyuan-3d/v3.1/pro/text-to-3d/api"]
                ),
                makeModel(
                    id: "fal-ai/hunyuan-3d/v3.1/pro/image-to-3d",
                    displayName: "Hunyuan 3D v3.1 Pro Image",
                    providerID: "fal-ai",
                    deployment: .cloudAPI,
                    capabilities: [.imageTo3D, .multiViewTo3D, .textureGeneration, .pbrMaterials],
                    supportsTextInput: false,
                    supportsImageInput: true,
                    outputFormats: [.glb, .obj],
                    license: "fal commercial API",
                    recommendedFor: ["image-to-3D character and prop reconstruction"],
                    sourceURLs: ["https://fal.ai/models/fal-ai/hunyuan-3d/v3.1/pro/image-to-3d"]
                ),
                makeModel(
                    id: "fal-ai/trellis-2",
                    displayName: "TRELLIS 2",
                    providerID: "fal-ai",
                    deployment: .cloudAPI,
                    capabilities: [.imageTo3D, .textureGeneration, .pbrMaterials, .retopology],
                    supportsTextInput: false,
                    supportsImageInput: true,
                    outputFormats: [.glb],
                    license: "fal commercial API",
                    recommendedFor: ["high-detail image-to-3D meshes with game decimation controls"],
                    sourceURLs: ["https://fal.ai/models/fal-ai/trellis-2/api"]
                )
            ],
            strengths: ["Already wired through `media.generate_3d`.", "Queue API fits long-running generation."],
            limitations: ["Requires `networkAccess`, `threeDGenerate`, and a stored FAL key."],
            sourceURLs: ["https://fal.ai/docs/model-api-reference/3d-api/overview"]
        ),
        makeProvider(
            id: "meshy",
            displayName: "Meshy",
            deployment: .cloudAPI,
            websiteURL: "https://docs.meshy.ai",
            capabilities: [.textTo3D, .imageTo3D, .textureGeneration, .pbrMaterials, .retopology],
            requiredSecretNames: ["MESHY_API_KEY"],
            defaultOutputFormats: [.glb, .gltf, .fbx, .obj, .usdz, .stl, .threeMF],
            integrationIDs: ["threejs", "unity", "unreal", "blender"],
            models: [
                makeModel(
                    id: "meshy/text-to-3d-v2",
                    displayName: "Meshy Text to 3D",
                    providerID: "meshy",
                    deployment: .cloudAPI,
                    capabilities: [.textTo3D, .textureGeneration, .pbrMaterials, .retopology],
                    supportsTextInput: true,
                    supportsImageInput: false,
                    outputFormats: [.glb, .fbx, .obj, .usdz, .stl, .threeMF],
                    license: "Meshy commercial API",
                    recommendedFor: ["custom game props", "style-consistent characters"],
                    sourceURLs: ["https://docs.meshy.ai/en/api/text-to-3d"]
                ),
                makeModel(
                    id: "meshy/image-to-3d-v1",
                    displayName: "Meshy Image to 3D",
                    providerID: "meshy",
                    deployment: .cloudAPI,
                    capabilities: [.imageTo3D, .textureGeneration, .pbrMaterials, .retopology],
                    supportsTextInput: false,
                    supportsImageInput: true,
                    outputFormats: [.glb, .fbx, .obj, .usdz, .stl, .threeMF],
                    license: "Meshy commercial API",
                    recommendedFor: ["concept-art to game mesh conversion"],
                    sourceURLs: ["https://docs.meshy.ai/en/api/image-to-3d"]
                )
            ],
            strengths: ["Broad export coverage.", "Good fit for artist-facing game asset creation."],
            limitations: ["External API adapter is cataloged but not wired yet."],
            sourceURLs: ["https://docs.meshy.ai/en/api/text-to-3d", "https://docs.meshy.ai/en/api/image-to-3d"]
        ),
        makeProvider(
            id: "tripo",
            displayName: "Tripo",
            deployment: .cloudAPI,
            websiteURL: "https://docs.tripo3d.ai",
            capabilities: [.textTo3D, .imageTo3D, .multiViewTo3D, .rigging, .retopology, .formatConversion],
            requiredSecretNames: ["TRIPO_API_KEY"],
            defaultOutputFormats: [.glb, .gltf, .fbx, .obj, .usdz, .stl, .threeMF],
            integrationIDs: ["threejs", "unity", "unreal", "blender"],
            models: [
                makeModel(
                    id: "tripo/v3.1",
                    displayName: "Tripo v3.1",
                    providerID: "tripo",
                    deployment: .cloudAPI,
                    capabilities: [.textTo3D, .imageTo3D, .multiViewTo3D, .retopology, .rigging],
                    supportsTextInput: true,
                    supportsImageInput: true,
                    outputFormats: [.glb, .gltf, .fbx, .obj, .usdz, .stl, .threeMF],
                    license: "Tripo commercial API",
                    recommendedFor: ["multi-view game asset generation", "riggable character base meshes"],
                    sourceURLs: ["https://docs.tripo3d.ai/"]
                )
            ],
            strengths: ["Text, single-image, and multi-view flows.", "Conversion endpoint covers GLTF, USDZ, FBX, OBJ, STL, and 3MF."],
            limitations: ["External API adapter is cataloged but not wired yet."],
            sourceURLs: ["https://docs.tripo3d.ai/", "https://docs.tripo3d.ai/export/conversion.html"]
        ),
        makeProvider(
            id: "hyper3d-rodin",
            displayName: "Hyper3D Rodin",
            deployment: .cloudAPI,
            websiteURL: "https://hyper3d.ai/features/api",
            capabilities: [.textTo3D, .imageTo3D, .textureGeneration, .pbrMaterials],
            requiredSecretNames: ["RODIN_API_KEY"],
            defaultOutputFormats: [.glb, .fbx, .obj, .usd, .stl],
            integrationIDs: ["threejs", "unity", "unreal", "blender"],
            models: [
                makeModel(
                    id: "rodin/gen-2",
                    displayName: "Rodin Gen-2",
                    providerID: "hyper3d-rodin",
                    deployment: .cloudAPI,
                    capabilities: [.textTo3D, .imageTo3D, .textureGeneration],
                    supportsTextInput: true,
                    supportsImageInput: true,
                    outputFormats: [.glb, .fbx, .obj, .usd, .stl],
                    license: "Hyper3D commercial API",
                    recommendedFor: ["production cloud text/image-to-3D"],
                    sourceURLs: ["https://developer.hyper3d.ai/api-specification/rodin-generation-gen2"]
                )
            ],
            strengths: ["Production API surface with texture jobs.", "Good partner candidate for game asset workflows."],
            limitations: ["External API adapter is cataloged but not wired yet."],
            sourceURLs: ["https://hyper3d.ai/features/api"]
        ),
        makeProvider(
            id: "stability-ai-3d",
            displayName: "Stability AI 3D",
            deployment: .cloudAPI,
            websiteURL: "https://stability.ai/stable-3d",
            capabilities: [.imageTo3D, .textureGeneration, .pbrMaterials],
            requiredSecretNames: ["STABILITY_API_KEY"],
            defaultOutputFormats: [.glb],
            integrationIDs: ["threejs", "unity", "unreal", "blender"],
            models: [
                makeModel(
                    id: "stability/stable-fast-3d",
                    displayName: "Stable Fast 3D",
                    providerID: "stability-ai-3d",
                    deployment: .localHostable,
                    capabilities: [.imageTo3D, .textureGeneration, .pbrMaterials],
                    supportsTextInput: false,
                    supportsImageInput: true,
                    outputFormats: [.glb],
                    license: "Stability AI Community License",
                    localRequirements: ["512x512 source image", "local Python or hosted Stability API"],
                    recommendedFor: ["fast textured mesh reconstruction"],
                    sourceURLs: ["https://huggingface.co/stabilityai/stable-fast-3d"]
                ),
                makeModel(
                    id: "stability/spar3d",
                    displayName: "SPAR3D",
                    providerID: "stability-ai-3d",
                    deployment: .localHostable,
                    capabilities: [.imageTo3D, .textureGeneration],
                    supportsTextInput: false,
                    supportsImageInput: true,
                    outputFormats: [.glb],
                    license: "Stability AI model license",
                    localRequirements: ["local GPU runtime or Stability-hosted deployment"],
                    recommendedFor: ["fast image-to-3D with editable structure"],
                    sourceURLs: ["https://stability.ai/stable-3d"]
                )
            ],
            strengths: ["Cloud API plus local/self-host paths.", "Fast reconstruction models fit iterative game asset passes."],
            limitations: ["License tier must be checked before commercial deployment at scale."],
            sourceURLs: ["https://stability.ai/stable-3d", "https://stability.ai/license"]
        )
    ]
}
