// SwooshArena/Game2DCreationCatalog+Local.swift — Cartridge local 2D pipelines (0.1A)

import Foundation

extension Game2DCreationCatalog {
    static let localProviders: [Game2DProviderDescriptor] = [
        makeProvider(
            id: "dogsprite",
            displayName: "DogSprite",
            deployment: .localHostable,
            websiteURL: "https://github.com/Dexploarer/DogSprite",
            capabilities: [.pixelEditing, .layerEditing, .paletteControl, .spriteSheetGeneration, .frameAnimation, .framePlayback, .transparentSprites, .exportPackaging, .localFirst],
            requiredSecretNames: [],
            defaultOutputFormats: [.png, .gif, .spriteSheet, .aseprite, .json],
            integrationIDs: ["threejs", "webgpu", "unity", "godot", "phaser"],
            workflows: [
                makeWorkflow(
                    id: "dogsprite/browser-editor",
                    displayName: "Offline Browser Pixel Editor",
                    providerID: "dogsprite",
                    deployment: .localHostable,
                    capabilities: [.pixelEditing, .layerEditing, .paletteControl, .frameAnimation, .framePlayback, .transparentSprites, .localFirst],
                    inputKinds: [.localCanvas, .spriteSheet, .existingImage],
                    outputFormats: [.png, .gif, .spriteSheet, .aseprite, .json],
                    recommendedFor: ["manual pixel cleanup", "onion-skin animation", "Aseprite-compatible import and export"],
                    sourceURLs: ["https://github.com/Dexploarer/DogSprite"]
                ),
                makeWorkflow(
                    id: "dogsprite/mcp-pixel-art",
                    displayName: "DogSprite MCP Pixel Art Server",
                    providerID: "dogsprite",
                    deployment: .localHostable,
                    capabilities: [.pixelEditing, .paletteControl, .spriteSheetGeneration, .transparentSprites, .qaValidation, .localFirst],
                    inputKinds: [.textPrompt, .localCanvas],
                    outputFormats: [.png, .json],
                    recommendedFor: ["agent-driven DB16 sprites", "template rendering", "quality checks before export"],
                    sourceURLs: ["https://github.com/Dexploarer/DogSprite"],
                    notes: ["Reference server exposes canvas, drawing, layer, color, transform, template, export, and quality tools."]
                )
            ],
            strengths: ["Offline editor with no cloud art upload.", "MCP server gives Cartridge a clean integration shape for deterministic pixel operations."],
            limitations: ["AI image generation is not the core path; pair with image providers for initial drafts."],
            sourceURLs: ["https://github.com/Dexploarer/DogSprite"]
        ),
        makeProvider(
            id: "dreamsprites",
            displayName: "dreamsprites",
            deployment: .localHostable,
            websiteURL: "https://github.com/Dexploarer/dreamsprites",
            capabilities: [.textToSprite, .spriteSheetGeneration, .frameAnimation, .framePlayback, .particleFX, .rigging2D, .hitboxEditing, .stateMachineEditing, .tilemapEditing, .exportPackaging],
            requiredSecretNames: ["ELIZA_CLOUD_API_KEY"],
            defaultOutputFormats: [.png, .gif, .apng, .spriteSheet, .aseprite, .json],
            integrationIDs: ["threejs", "webgpu", "unity", "godot", "phaser"],
            workflows: [
                makeWorkflow(
                    id: "dreamsprites/ai-spritesheet",
                    displayName: "AI Sprite Sheet Generation",
                    providerID: "dreamsprites",
                    deployment: .cloudAPI,
                    capabilities: [.textToSprite, .spriteSheetGeneration, .frameAnimation, .styleReference],
                    inputKinds: [.textPrompt, .referenceImage],
                    outputFormats: [.png, .spriteSheet, .json],
                    recommendedFor: ["prompted sprite sheets", "style-guided frame grids", "quick animation drafts"],
                    sourceURLs: ["https://raw.githubusercontent.com/Dexploarer/dreamsprites/main/src/server/actions/generate.ts"]
                ),
                makeWorkflow(
                    id: "dreamsprites/export-stack",
                    displayName: "Sprite Export Stack",
                    providerID: "dreamsprites",
                    deployment: .localHostable,
                    capabilities: [.exportPackaging, .frameAnimation, .framePlayback],
                    inputKinds: [.spriteSheet, .frameGrid],
                    outputFormats: [.png, .gif, .apng, .aseprite, .json],
                    recommendedFor: ["nearest-neighbor scaling", "frame ZIPs", "GIF previews"],
                    sourceURLs: ["https://raw.githubusercontent.com/Dexploarer/dreamsprites/main/src/server/actions/export.ts"]
                ),
                makeWorkflow(
                    id: "dreamsprites/editor-suite",
                    displayName: "Sprite Editor Suite",
                    providerID: "dreamsprites",
                    deployment: .localHostable,
                    capabilities: [.particleFX, .rigging2D, .hitboxEditing, .stateMachineEditing, .tilemapEditing, .framePlayback],
                    inputKinds: [.spriteSheet, .localCanvas],
                    outputFormats: [.png, .spriteSheet, .json],
                    recommendedFor: ["hitbox authoring", "animation state machines", "particle sprite sheets", "tilemap iteration"],
                    sourceURLs: ["https://github.com/Dexploarer/dreamsprites", "https://raw.githubusercontent.com/Dexploarer/dreamsprites/main/legacy/IMPLEMENTATION_SPEC.md"]
                )
            ],
            strengths: ["Useful reference for sprite generation, export formats, hitboxes, state machines, particle FX, and tilemaps.", "Pairs naturally with Cartridge create/test loops."],
            limitations: ["The current repo is an early Next.js app; native Swoosh integration should port the workflows rather than vendor the app wholesale."],
            sourceURLs: ["https://github.com/Dexploarer/dreamsprites"]
        ),
        makeProvider(
            id: "image-extender",
            displayName: "Image Extender 2D Game Studio",
            deployment: .localHostable,
            websiteURL: "https://github.com/boona13/image-extender",
            capabilities: [.imageExtension, .outpainting, .spriteSheetGeneration, .frameAnimation, .parallaxBackgrounds, .autotileGeneration, .propGeneration, .transparentSprites, .styleReference, .qaValidation, .exportPackaging],
            requiredSecretNames: ["OPENROUTER_API_KEY"],
            defaultOutputFormats: [.png, .spriteSheet, .json, .phaser, .unity, .godot, .defold],
            integrationIDs: ["threejs", "webgpu", "unity", "godot", "phaser"],
            workflows: [
                makeWorkflow(
                    id: "image-extender/outpaint",
                    displayName: "Poisson-Blended Outpainting",
                    providerID: "image-extender",
                    deployment: .localHostable,
                    capabilities: [.imageExtension, .outpainting, .imageEditing, .qaValidation],
                    inputKinds: [.existingImage, .textPrompt, .mask],
                    outputFormats: [.png, .json],
                    recommendedFor: ["extending concept art", "widening backgrounds", "scene continuation"],
                    sourceURLs: ["https://github.com/boona13/image-extender"]
                ),
                makeWorkflow(
                    id: "image-extender/sprite-studio",
                    displayName: "Anchor-to-Sheet Sprite Studio",
                    providerID: "image-extender",
                    deployment: .localHostable,
                    capabilities: [.textToSprite, .spriteSheetGeneration, .frameAnimation, .characterConsistency, .transparentSprites, .qaValidation],
                    inputKinds: [.textPrompt, .referenceImage, .structuralGuide],
                    outputFormats: [.png, .spriteSheet, .json, .phaser, .unity, .godot, .defold],
                    recommendedFor: ["body-plan animation sets", "canonical character anchors", "baseline and scale normalization"],
                    sourceURLs: ["https://github.com/boona13/image-extender"]
                ),
                makeWorkflow(
                    id: "image-extender/tile-prop-parallax",
                    displayName: "Tiles, Props, and Parallax Packs",
                    providerID: "image-extender",
                    deployment: .localHostable,
                    capabilities: [.parallaxBackgrounds, .autotileGeneration, .propGeneration, .transparentSprites, .styleReference, .exportPackaging],
                    inputKinds: [.textPrompt, .styleImage, .structuralGuide],
                    outputFormats: [.png, .spriteSheet, .json, .tiled, .phaser, .unity, .godot],
                    recommendedFor: ["13-tile platformer sets", "scrolling background layers", "biome prop atlases"],
                    sourceURLs: ["https://github.com/boona13/image-extender"]
                )
            ],
            strengths: ["Best current reference for complete 2D game-art packs: backgrounds, tiles, sprites, and props.", "Its deterministic post-processing rules are portable into Swift or JS workers."],
            limitations: ["BYOK OpenRouter flow needs a native Swoosh secret adapter before becoming a first-party provider."],
            sourceURLs: ["https://github.com/boona13/image-extender"]
        ),
        makeProvider(
            id: "comfyui-2d",
            displayName: "ComfyUI 2D Workflows",
            deployment: .localHostable,
            websiteURL: "https://github.com/comfyanonymous/ComfyUI",
            capabilities: [.textToSprite, .imageToSprite, .imageEditing, .styleReference, .backgroundRemoval, .transparentSprites, .spriteSheetGeneration, .frameAnimation, .outpainting],
            requiredSecretNames: [],
            defaultOutputFormats: [.png, .spriteSheet, .json],
            integrationIDs: ["threejs", "webgpu", "unity", "unreal", "godot"],
            workflows: [
                makeWorkflow(
                    id: "comfyui/controlnet-ipadapter-lora",
                    displayName: "ControlNet, IP-Adapter, and LoRA Sprite Workflows",
                    providerID: "comfyui-2d",
                    deployment: .localHostable,
                    capabilities: [.textToSprite, .imageToSprite, .imageEditing, .styleReference, .spriteSheetGeneration, .frameAnimation],
                    inputKinds: [.textPrompt, .referenceImage, .styleImage, .structuralGuide, .mask],
                    outputFormats: [.png, .spriteSheet, .json],
                    recommendedFor: ["local character consistency", "pose-guided frame sheets", "custom fine-tuned style packs"],
                    sourceURLs: ["https://github.com/comfyanonymous/ComfyUI"]
                )
            ],
            strengths: ["Local GPU path for controlled sprite and texture generation.", "Can host open models without sending game art to cloud providers."],
            limitations: ["Requires users to manage local models, VRAM, and workflow graphs."],
            sourceURLs: ["https://github.com/comfyanonymous/ComfyUI"]
        )
    ]
}
