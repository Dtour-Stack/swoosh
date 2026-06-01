// SwooshArena/Game2DCreationCatalog+Editors.swift — Cartridge 2D editor and packing providers (0.1A)

import Foundation

extension Game2DCreationCatalog {
    static let editorProviders: [Game2DProviderDescriptor] = [
        makeProvider(
            id: "aseprite",
            displayName: "Aseprite",
            deployment: .assetProcessing,
            websiteURL: "https://www.aseprite.org",
            capabilities: [.pixelEditing, .layerEditing, .paletteControl, .spriteSheetGeneration, .frameAnimation, .framePlayback, .transparentSprites, .exportPackaging],
            requiredSecretNames: [],
            defaultOutputFormats: [.png, .gif, .spriteSheet, .aseprite, .json],
            integrationIDs: ["unity", "godot", "phaser", "threejs"],
            workflows: [
                makeWorkflow(
                    id: "aseprite/cli-export",
                    displayName: "Aseprite CLI Export",
                    providerID: "aseprite",
                    deployment: .assetProcessing,
                    capabilities: [.spriteSheetGeneration, .frameAnimation, .exportPackaging],
                    inputKinds: [.spriteSheet, .frameGrid, .localCanvas],
                    outputFormats: [.png, .gif, .spriteSheet, .aseprite, .json],
                    recommendedFor: ["artist-authored sprite sheets", "CLI atlas export", "animation metadata preservation"],
                    sourceURLs: ["https://www.aseprite.org/docs/cli/"]
                )
            ],
            strengths: ["Industry-standard pixel art editor and CLI exporter.", "Pairs well with DogSprite import/export and Cartridge manifest tracking."],
            limitations: ["Commercial desktop app; install and license are external to Swoosh."],
            sourceURLs: ["https://www.aseprite.org/docs/cli/"]
        ),
        makeProvider(
            id: "texturepacker",
            displayName: "TexturePacker",
            deployment: .assetProcessing,
            websiteURL: "https://www.codeandweb.com/texturepacker",
            capabilities: [.spriteSheetGeneration, .transparentSprites, .exportPackaging, .qaValidation],
            requiredSecretNames: [],
            defaultOutputFormats: [.png, .json, .texturePacker, .phaser, .unity, .godot],
            integrationIDs: ["unity", "godot", "phaser", "unreal", "threejs"],
            workflows: [
                makeWorkflow(
                    id: "texturepacker/atlas-pack",
                    displayName: "Atlas Packing and Engine Export",
                    providerID: "texturepacker",
                    deployment: .assetProcessing,
                    capabilities: [.spriteSheetGeneration, .transparentSprites, .exportPackaging],
                    inputKinds: [.existingImage, .spriteSheet, .frameGrid],
                    outputFormats: [.png, .json, .texturePacker, .phaser, .unity, .godot],
                    recommendedFor: ["dense atlases", "extruded padding", "engine-specific sprite metadata"],
                    sourceURLs: ["https://www.codeandweb.com/texturepacker"]
                )
            ],
            strengths: ["Production atlas packing and engine metadata exports.", "Complements AI generation by creating stable runtime packages."],
            limitations: ["External binary; native Swoosh packer can replace it for local-first users later."],
            sourceURLs: ["https://www.codeandweb.com/texturepacker"]
        ),
        makeProvider(
            id: "tiled",
            displayName: "Tiled Map Editor",
            deployment: .openSource,
            websiteURL: "https://www.mapeditor.org",
            capabilities: [.tilemapEditing, .autotileGeneration, .transparentSprites, .exportPackaging, .localFirst],
            requiredSecretNames: [],
            defaultOutputFormats: [.tiled, .json, .png],
            integrationIDs: ["godot", "phaser", "unity", "threejs"],
            workflows: [
                makeWorkflow(
                    id: "tiled/tilemap-authoring",
                    displayName: "Tilemap Authoring",
                    providerID: "tiled",
                    deployment: .openSource,
                    capabilities: [.tilemapEditing, .autotileGeneration, .exportPackaging, .localFirst],
                    inputKinds: [.spriteSheet, .localCanvas],
                    outputFormats: [.tiled, .json, .png],
                    recommendedFor: ["platformer maps", "autotile preview", "collision metadata"],
                    sourceURLs: ["https://www.mapeditor.org"]
                )
            ],
            strengths: ["Open-source tilemap editor with broad engine support.", "Useful target for Image Extender tile outputs."],
            limitations: ["Not an AI generator; consumes generated tilesets."],
            sourceURLs: ["https://www.mapeditor.org"]
        )
    ]
}
