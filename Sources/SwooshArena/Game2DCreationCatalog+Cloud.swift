// SwooshArena/Game2DCreationCatalog+Cloud.swift — Cartridge cloud 2D providers (0.1A)

import Foundation

extension Game2DCreationCatalog {
    static let cloudProviders: [Game2DProviderDescriptor] = [
        makeProvider(
            id: "cartridge-imagegen",
            displayName: "Cartridge Image Generation",
            deployment: .assetPipeline,
            websiteURL: "swoosh://tools/media.generate_image",
            capabilities: [.textToSprite, .imageEditing, .styleReference, .transparentSprites, .exportPackaging],
            requiredSecretNames: [],
            defaultOutputFormats: [.png, .json],
            integrationIDs: ["threejs", "webgpu", "unity", "unreal", "godot", "roblox"],
            workflows: [
                makeWorkflow(
                    id: "media.generate_image/openai-gpt-image",
                    displayName: "OpenAI Images via media.generate_image",
                    providerID: "cartridge-imagegen",
                    deployment: .cloudAPI,
                    capabilities: [.textToSprite, .imageEditing, .styleReference, .transparentSprites],
                    inputKinds: [.textPrompt, .referenceImage, .mask],
                    outputFormats: [.png, .json],
                    recommendedFor: ["single-character concepts", "props", "UI elements", "transparent game assets"],
                    sourceURLs: ["https://platform.openai.com/docs/guides/image-generation"],
                    notes: ["Current Swoosh adapter defaults to the stored OpenAI image model configuration."]
                ),
                makeWorkflow(
                    id: "media.generate_image/apple-image-playground",
                    displayName: "Apple Image Playground",
                    providerID: "cartridge-imagegen",
                    deployment: .localHostable,
                    capabilities: [.textToSprite, .localFirst],
                    inputKinds: [.textPrompt],
                    outputFormats: [.png, .json],
                    recommendedFor: ["Apple-first local creative drafting when the platform model is available"],
                    sourceURLs: ["https://developer.apple.com/documentation/imageplayground"],
                    notes: ["Platform-gated local provider; no cloud key is required."]
                )
            ],
            strengths: ["Already wired through `media.generate_image`.", "Can pair with Cartridge sessions and audit logs."],
            limitations: ["Spritesheet normalization, atlas packing, and animation QA live in the 2D studio pipelines."],
            sourceURLs: ["https://platform.openai.com/docs/guides/image-generation", "https://developer.apple.com/documentation/imageplayground"]
        ),
        makeProvider(
            id: "openrouter-gemini-image",
            displayName: "OpenRouter Gemini Image",
            deployment: .cloudAPI,
            websiteURL: "https://openrouter.ai",
            capabilities: [.textToSprite, .imageEditing, .styleReference, .spriteSheetGeneration, .frameAnimation, .imageExtension, .outpainting, .parallaxBackgrounds, .autotileGeneration, .propGeneration, .qaValidation],
            requiredSecretNames: ["OPENROUTER_API_KEY"],
            defaultOutputFormats: [.png, .spriteSheet, .json],
            integrationIDs: ["threejs", "webgpu", "unity", "godot", "phaser"],
            workflows: [
                makeWorkflow(
                    id: "image-extender/gemini-outpaint",
                    displayName: "Image Extender Gemini Outpaint",
                    providerID: "openrouter-gemini-image",
                    deployment: .cloudAPI,
                    capabilities: [.imageExtension, .outpainting, .imageEditing, .styleReference, .qaValidation],
                    inputKinds: [.existingImage, .textPrompt, .mask],
                    outputFormats: [.png, .json],
                    recommendedFor: ["wide backgrounds", "scene continuation", "seam-quality variant selection"],
                    sourceURLs: ["https://github.com/boona13/image-extender"],
                    notes: ["Uses best-of-N seam scoring and Poisson blending in the reference app."]
                ),
                makeWorkflow(
                    id: "image-extender/game-art-studios",
                    displayName: "Image Extender Game Art Studios",
                    providerID: "openrouter-gemini-image",
                    deployment: .cloudAPI,
                    capabilities: [.spriteSheetGeneration, .frameAnimation, .parallaxBackgrounds, .autotileGeneration, .propGeneration, .transparentSprites, .qaValidation],
                    inputKinds: [.textPrompt, .referenceImage, .styleImage, .structuralGuide],
                    outputFormats: [.png, .spriteSheet, .json, .phaser, .unity, .godot, .defold],
                    recommendedFor: ["parallax layer packs", "13-tile autotiles", "body-plan sprite animations", "transparent prop atlases"],
                    sourceURLs: ["https://github.com/boona13/image-extender"],
                    notes: ["Anchor-to-sheet, tile-template, and art-director QA patterns are the key portable parts."]
                )
            ],
            strengths: ["Strong reference implementation for outpainted backgrounds, autotiles, sprites, props, and manifests.", "BYOK maps cleanly to SwooshSecrets without storing raw keys in prompts."],
            limitations: ["External OpenRouter/Gemini adapter is cataloged but not wired as a native Swoosh provider yet."],
            sourceURLs: ["https://github.com/boona13/image-extender"]
        ),
        makeProvider(
            id: "fal-ai-image",
            displayName: "fal.ai Image Models",
            deployment: .cloudAPI,
            websiteURL: "https://fal.ai/models?categories=image",
            capabilities: [.textToSprite, .imageToSprite, .imageEditing, .styleReference, .backgroundRemoval, .transparentSprites, .qaValidation],
            requiredSecretNames: ["FAL_KEY"],
            defaultOutputFormats: [.png, .json],
            integrationIDs: ["threejs", "webgpu", "unity", "unreal", "godot"],
            workflows: [
                makeWorkflow(
                    id: "fal-ai/nano-banana-2",
                    displayName: "fal.ai Nano Banana 2",
                    providerID: "fal-ai-image",
                    deployment: .cloudAPI,
                    capabilities: [.textToSprite, .imageToSprite, .imageEditing, .styleReference],
                    inputKinds: [.textPrompt, .referenceImage, .styleImage],
                    outputFormats: [.png, .json],
                    recommendedFor: ["fast character sheets", "style exploration", "game art look-dev"],
                    sourceURLs: ["https://docs.fal.ai/model-apis"]
                ),
                makeWorkflow(
                    id: "fal-ai/flux-family",
                    displayName: "fal.ai Flux/Recraft Image Stack",
                    providerID: "fal-ai-image",
                    deployment: .cloudAPI,
                    capabilities: [.textToSprite, .imageEditing, .styleReference],
                    inputKinds: [.textPrompt, .referenceImage, .mask],
                    outputFormats: [.png, .json],
                    recommendedFor: ["high-volume 2D concept passes", "vector-like icons", "environment tiles"],
                    sourceURLs: ["https://fal.ai/docs/model-api-reference"]
                )
            ],
            strengths: ["Large current model catalog behind one queue API.", "Good fit for experiments before choosing a dedicated provider."],
            limitations: ["Model-level licensing and output rights vary by endpoint."],
            sourceURLs: ["https://docs.fal.ai/model-apis", "https://fal.ai/docs/model-api-reference"]
        ),
        makeProvider(
            id: "runware",
            displayName: "Runware",
            deployment: .cloudAPI,
            websiteURL: "https://runware.ai/docs",
            capabilities: [.textToSprite, .imageToSprite, .imageEditing, .styleReference, .backgroundRemoval, .transparentSprites],
            requiredSecretNames: ["RUNWARE_API_KEY"],
            defaultOutputFormats: [.png, .json],
            integrationIDs: ["threejs", "webgpu", "unity", "unreal", "godot"],
            workflows: [
                makeWorkflow(
                    id: "runware/unified-image-api",
                    displayName: "Runware Unified Image API",
                    providerID: "runware",
                    deployment: .cloudAPI,
                    capabilities: [.textToSprite, .imageToSprite, .imageEditing, .styleReference],
                    inputKinds: [.textPrompt, .referenceImage, .mask],
                    outputFormats: [.png, .json],
                    recommendedFor: ["multi-provider routing", "cost and latency comparison", "OpenAI-compatible image workflows"],
                    sourceURLs: ["https://runware.ai/docs/getting-started/introduction"]
                )
            ],
            strengths: ["Single API spans image, video, audio, 3D, and text generation.", "Useful partner router for broad provider comparison."],
            limitations: ["Native Swoosh adapter still needs implementation."],
            sourceURLs: ["https://runware.ai/docs/getting-started/introduction"]
        ),
        makeProvider(
            id: "stability-ai-image",
            displayName: "Stability AI Image",
            deployment: .cloudAPI,
            websiteURL: "https://platform.stability.ai/docs/getting-started/stable-image",
            capabilities: [.textToSprite, .imageToSprite, .imageEditing, .backgroundRemoval, .outpainting, .styleReference],
            requiredSecretNames: ["STABILITY_API_KEY"],
            defaultOutputFormats: [.png, .json],
            integrationIDs: ["threejs", "webgpu", "unity", "unreal", "godot"],
            workflows: [
                makeWorkflow(
                    id: "stability/stable-image-services",
                    displayName: "Stable Image Services",
                    providerID: "stability-ai-image",
                    deployment: .cloudAPI,
                    capabilities: [.textToSprite, .imageToSprite, .imageEditing, .outpainting],
                    inputKinds: [.textPrompt, .existingImage, .referenceImage, .mask],
                    outputFormats: [.png, .json],
                    recommendedFor: ["structured image generation", "sketch-to-asset", "outpainting"],
                    sourceURLs: ["https://platform.stability.ai/docs/getting-started/stable-image"]
                )
            ],
            strengths: ["Dedicated image generation and editing REST APIs.", "Strong fit for mask and sketch-driven 2D game asset passes."],
            limitations: ["Commercial use depends on current Stability terms and selected service."],
            sourceURLs: ["https://platform.stability.ai/docs/getting-started/stable-image"]
        )
    ]
}
