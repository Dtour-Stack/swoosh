// SwooshArena/GameProjectScaffoldFactory.swift — Cartridge starter scaffolds (0.1B)

import Foundation

public enum GameProjectScaffoldFactory {
    public static func make(template: GameProjectTemplateKind, title: String) throws -> GameProjectScaffold {
        let slug = try projectSlug(title)
        switch template {
        case .threeJS:
            return try webScaffold(title: title, template: .threeJS, integrationID: "threejs", files: threeJSFiles(slug: slug))
        case .webGPU:
            return try webScaffold(title: title, template: .webGPU, integrationID: "webgpu", files: webGPUFiles(slug: slug))
        case .unityPackage:
            return try pluginScaffold(title: title, template: template, integrationIDs: ["unity"], files: unityFiles(slug: slug))
        case .unrealPlugin:
            return try pluginScaffold(title: title, template: template, integrationIDs: ["unreal"], files: unrealFiles())
        case .blenderAddon:
            return try pluginScaffold(title: title, template: template, integrationIDs: ["blender"], files: blenderFiles(slug: slug))
        case .robloxExperience:
            return try pluginScaffold(title: title, template: template, integrationIDs: ["roblox"], files: robloxFiles(slug: slug))
        case .fortniteUEFN:
            return try pluginScaffold(title: title, template: template, integrationIDs: ["fortnite-uefn"], files: fortniteFiles())
        case .minecraftDatapack:
            return try pluginScaffold(title: title, template: template, integrationIDs: ["minecraft"], files: minecraftFiles(slug: slug))
        case .threeDSMaxScript:
            return try pluginScaffold(title: title, template: template, integrationIDs: ["3ds-max"], files: threeDSMaxFiles(slug: slug))
        }
    }

    private static func webScaffold(
        title: String,
        template: GameProjectTemplateKind,
        integrationID: String,
        files: [GameScaffoldFile]
    ) throws -> GameProjectScaffold {
        GameProjectScaffold(
            title: title,
            template: template,
            integrationIDs: [integrationID],
            files: files,
            pipelines: try GamePipelineTemplateCatalog.list(integrationID: integrationID),
            nextSteps: ["Install with npm install.", "Run npm run dev.", "Load the localhost URL in Cartridge."]
        )
    }

    private static func pluginScaffold(
        title: String,
        template: GameProjectTemplateKind,
        integrationIDs: [String],
        files: [GameScaffoldFile]
    ) throws -> GameProjectScaffold {
        var pipelines: [GamePipeline] = []
        for integrationID in integrationIDs {
            pipelines.append(contentsOf: try GamePipelineTemplateCatalog.list(integrationID: integrationID))
        }
        return GameProjectScaffold(
            title: title,
            template: template,
            integrationIDs: integrationIDs,
            files: files,
            pipelines: pipelines,
            nextSteps: ["Install the generated files into the matching project.", "Point the bridge at the local Cartridge server.", "Run a playtest session and save telemetry."]
        )
    }

    private static func projectSlug(_ title: String) throws -> String {
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789")
        let lowered = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let raw = lowered.map { allowed.contains($0) ? String($0) : "-" }.joined()
        let slug = raw.split(separator: "-").joined(separator: "-")
        guard !slug.isEmpty else {
            throw GameHarnessError.invalidProjectTitle(title)
        }
        return slug
    }

    private static func file(_ path: String, _ role: String, _ body: String) -> GameScaffoldFile {
        GameScaffoldFile(path: path, role: role, body: body)
    }

    private static func threeJSFiles(slug: String) -> [GameScaffoldFile] {
        [
            file("package.json", "package", """
            {"name":"\(slug)","private":true,"type":"module","scripts":{"dev":"vite --host 127.0.0.1","build":"tsc && vite build","preview":"vite preview --host 127.0.0.1"},"dependencies":{"three":"latest"},"devDependencies":{"typescript":"latest","vite":"latest"}}
            """),
            file("index.html", "entry", """
            <div id="hud">Cartridge</div><canvas id="game"></canvas><script type="module" src="/src/main.ts"></script>
            """),
            file("src/input.ts", "input", """
            export type InputState = { forward: boolean; back: boolean; left: boolean; right: boolean }
            export function bindInput(): InputState {
              const state: InputState = { forward: false, back: false, left: false, right: false }
              const set = (code: string, value: boolean) => {
                if (code === "KeyW") state.forward = value
                if (code === "KeyS") state.back = value
                if (code === "KeyA") state.left = value
                if (code === "KeyD") state.right = value
              }
              addEventListener("keydown", event => set(event.code, true))
              addEventListener("keyup", event => set(event.code, false))
              return state
            }
            """),
            file("src/simulation.ts", "simulation", """
            import type { InputState } from "./input"
            export type SimState = { ticks: number; x: number; z: number }
            export function step(state: SimState, input: InputState, dt: number): SimState {
              const speed = dt * 2
              return {
                ticks: state.ticks + 1,
                x: state.x + (input.right ? speed : 0) - (input.left ? speed : 0),
                z: state.z + (input.back ? speed : 0) - (input.forward ? speed : 0)
              }
            }
            """),
            file("src/main.ts", "runtime", """
            import * as THREE from "three"
            import { bindInput } from "./input"
            import { step, type SimState } from "./simulation"

            const canvas = document.querySelector<HTMLCanvasElement>("#game")
            if (!canvas) throw new Error("Missing game canvas")

            const renderer = new THREE.WebGLRenderer({ canvas, antialias: true })
            const scene = new THREE.Scene()
            const camera = new THREE.PerspectiveCamera(60, 1, 0.1, 100)
            const actor = new THREE.Mesh(new THREE.BoxGeometry(1, 1, 1), new THREE.MeshStandardMaterial({ color: 0x2dd4bf }))
            const light = new THREE.DirectionalLight(0xffffff, 2)
            const input = bindInput()
            let state: SimState = { ticks: 0, x: 0, z: 0 }
            let previous = performance.now()

            scene.background = new THREE.Color(0x101820)
            scene.add(actor, light)
            light.position.set(3, 4, 2)
            camera.position.set(0, 3, 6)
            camera.lookAt(0, 0, 0)

            function resize() {
              const width = innerWidth
              const height = innerHeight
              renderer.setSize(width, height, false)
              camera.aspect = width / height
              camera.updateProjectionMatrix()
            }

            function frame(now: number) {
              const dt = Math.min((now - previous) / 1000, 0.05)
              previous = now
              state = step(state, input, dt)
              actor.position.set(state.x, 0, state.z)
              document.querySelector("#hud")!.textContent = `Cartridge ticks ${state.ticks}`
              renderer.render(scene, camera)
              requestAnimationFrame(frame)
            }

            addEventListener("resize", resize)
            resize()
            requestAnimationFrame(frame)
            """)
        ]
    }

    private static func webGPUFiles(slug: String) -> [GameScaffoldFile] {
        [
            file("package.json", "package", """
            {"name":"\(slug)-webgpu","private":true,"type":"module","scripts":{"dev":"vite --host 127.0.0.1","build":"tsc && vite build","preview":"vite preview --host 127.0.0.1"},"devDependencies":{"@webgpu/types":"latest","typescript":"latest","vite":"latest"}}
            """),
            file("index.html", "entry", """
            <canvas id="game"></canvas><pre id="hud">Cartridge WebGPU</pre><script type="module" src="/src/main.ts"></script>
            """),
            file("src/vite-env.d.ts", "types", """
            /// <reference types="vite/client" />
            /// <reference types="@webgpu/types" />
            """),
            file("src/shaders.wgsl", "shader", """
            @vertex fn vs(@builtin(vertex_index) i: u32) -> @builtin(position) vec4f {
              var p = array<vec2f, 3>(vec2f(0.0, 0.7), vec2f(-0.7, -0.7), vec2f(0.7, -0.7));
              return vec4f(p[i], 0.0, 1.0);
            }
            @fragment fn fs() -> @location(0) vec4f { return vec4f(0.13, 0.84, 0.74, 1.0); }
            """),
            file("src/simulation.ts", "simulation", """
            export type SimState = { ticks: number }
            export function step(state: SimState): SimState { return { ticks: state.ticks + 1 } }
            """),
            file("src/main.ts", "runtime", """
            import shader from "./shaders.wgsl?raw"
            import { step, type SimState } from "./simulation"

            const canvas = document.querySelector<HTMLCanvasElement>("#game")
            const hud = document.querySelector<HTMLElement>("#hud")
            if (!canvas || !hud) throw new Error("Missing Cartridge WebGPU surface")
            if (!navigator.gpu) throw new Error("WebGPU is unavailable in this browser")

            const adapter = await navigator.gpu.requestAdapter()
            if (!adapter) throw new Error("No WebGPU adapter available")
            const device = await adapter.requestDevice()
            const context = canvas.getContext("webgpu")
            if (!context) throw new Error("Missing WebGPU canvas context")

            const format = navigator.gpu.getPreferredCanvasFormat()
            context.configure({ device, format, alphaMode: "opaque" })
            const module = device.createShaderModule({ code: shader })
            const pipeline = device.createRenderPipeline({
              layout: "auto",
              vertex: { module, entryPoint: "vs" },
              fragment: { module, entryPoint: "fs", targets: [{ format }] },
              primitive: { topology: "triangle-list" }
            })
            let state: SimState = { ticks: 0 }

            function frame() {
              state = step(state)
              hud.textContent = `Cartridge WebGPU ticks ${state.ticks}`
              const encoder = device.createCommandEncoder()
              const pass = encoder.beginRenderPass({ colorAttachments: [{ view: context.getCurrentTexture().createView(), loadOp: "clear", storeOp: "store", clearValue: { r: 0.06, g: 0.08, b: 0.1, a: 1 } }] })
              pass.setPipeline(pipeline)
              pass.draw(3)
              pass.end()
              device.queue.submit([encoder.finish()])
              requestAnimationFrame(frame)
            }
            requestAnimationFrame(frame)
            """)
        ]
    }

    private static func unityFiles(slug: String) -> [GameScaffoldFile] {
        [
            file("Packages/ai.cartridge.\(slug)/package.json", "manifest", """
            {"name":"ai.cartridge.\(slug)","version":"0.1.0","displayName":"Cartridge Harness","unity":"2022.3","description":"Cartridge bridge for local game testing and content import."}
            """),
            file("Packages/ai.cartridge.\(slug)/Runtime/CartridgeBridge.cs", "runtime", """
            using UnityEngine;
            public sealed class CartridgeBridge : MonoBehaviour {
              public string ServerUrl = "http://127.0.0.1:4111";
              public void RecordObservation(string summary) { Debug.Log($"[CartridgeBridge] {summary}"); }
            }
            """),
            file("Packages/ai.cartridge.\(slug)/Editor/CartridgeWindow.cs", "editor", """
            using UnityEditor;
            using UnityEngine;
            public sealed class CartridgeWindow : EditorWindow {
              [MenuItem("Window/Cartridge/Harness")] static void Open() => GetWindow<CartridgeWindow>("Cartridge");
              void OnGUI() { GUILayout.Label("Cartridge local game harness"); }
            }
            """)
        ]
    }

    private static func unrealFiles() -> [GameScaffoldFile] {
        [
            file("Plugins/CartridgeHarness/CartridgeHarness.uplugin", "manifest", """
            {"FileVersion":3,"VersionName":"0.1.0","FriendlyName":"Cartridge Harness","Category":"Testing","Modules":[{"Name":"CartridgeHarness","Type":"Runtime","LoadingPhase":"Default"}]}
            """),
            file("Plugins/CartridgeHarness/Source/CartridgeHarness/CartridgeHarness.Build.cs", "build", """
            using UnrealBuildTool;
            public class CartridgeHarness : ModuleRules {
              public CartridgeHarness(ReadOnlyTargetRules Target) : base(Target) { PublicDependencyModuleNames.AddRange(new[] { "Core", "Engine", "HTTP", "Json" }); }
            }
            """)
        ]
    }

    private static func blenderFiles(slug: String) -> [GameScaffoldFile] {
        [
            file("cartridge_\(slug)/__init__.py", "addon", """
            bl_info = {"name": "Cartridge Harness", "blender": (4, 0, 0), "category": "Import-Export"}
            import bpy
            class CARTRIDGE_OT_export(bpy.types.Operator):
                bl_idname = "cartridge.export_pack"
                bl_label = "Export Cartridge Pack"
                def execute(self, context):
                    bpy.ops.export_scene.gltf(filepath="//cartridge_export.glb")
                    return {"FINISHED"}
            def register(): bpy.utils.register_class(CARTRIDGE_OT_export)
            def unregister(): bpy.utils.unregister_class(CARTRIDGE_OT_export)
            """)
        ]
    }

    private static func robloxFiles(slug: String) -> [GameScaffoldFile] {
        [
            file("default.project.json", "project", """
            {"name":"\(slug)","tree":{"$className":"DataModel","ServerScriptService":{"CartridgeHarness":{"$path":"src/ServerScriptService/CartridgeHarness.server.lua"}}}}
            """),
            file("src/ServerScriptService/CartridgeHarness.server.lua", "server", """
            local HttpService = game:GetService("HttpService")
            local CartridgeHarness = {}
            function CartridgeHarness.record(summary)
              print("[CartridgeHarness] " .. HttpService:JSONEncode({ summary = summary }))
            end
            return CartridgeHarness
            """)
        ]
    }

    private static func fortniteFiles() -> [GameScaffoldFile] {
        [
            file("Plugins/CartridgeUEFN/README.md", "guide", "Install this folder in a UEFN project and map generated content packs to Verse devices.\n"),
            file("Content/CartridgeDevice.verse", "verse", """
            using { /Fortnite.com/Devices }
            cartridge_device := class(creative_device):
                OnBegin<override>()<suspends>:void = {}
            """)
        ]
    }

    private static func minecraftFiles(slug: String) -> [GameScaffoldFile] {
        [
            file("pack.mcmeta", "manifest", """
            {"pack":{"pack_format":48,"description":"Cartridge datapack for \(slug)"}}
            """),
            file("data/cartridge/functions/tick.mcfunction", "function", "say Cartridge harness tick\n")
        ]
    }

    private static func threeDSMaxFiles(slug: String) -> [GameScaffoldFile] {
        [
            file("scripts/cartridge_\(slug)_export.ms", "script", """
            outputPath = getSaveFileName caption:"Export Cartridge FBX" types:"FBX (*.fbx)|*.fbx|"
            if outputPath != undefined do exportFile outputPath #noPrompt selectedOnly:false using:FBXEXP
            """)
        ]
    }
}
