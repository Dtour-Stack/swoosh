// Tests/SwooshLocalVoiceTests/KokoroBackendTests.swift
//
// Validates that the Kokoro catalog entry remains a CoreML provider
// candidate while the default package graph keeps heavyweight local
// model SDKs behind a plugin boundary.

import XCTest
@testable import SwooshLocalVoice

final class KokoroBackendTests: XCTestCase {

    // MARK: - Catalog → backend wiring (no network)

    func test_kokoroCatalogEntry_targetsCoreML() {
        XCTAssertEqual(
            LocalVoiceCatalog.kokoro.engineKind, .coreml,
            "Kokoro must declare engineKind=.coreml so KokoroAneBackend is selected"
        )
    }

    func test_kokoroCatalogEntry_pointsAtCoreMLWeights() {
        let url = LocalVoiceCatalog.kokoro.downloadURL
        XCTAssertEqual(url.host, "huggingface.co")
        XCTAssertTrue(
            url.path.contains("FluidInference") || url.path.contains("kokoro"),
            "Catalog URL should point at the Kokoro CoreML bundle (got \(url.path))"
        )
    }

    func test_omniVoiceCatalogEntry_isWiredButFallsBack() {
        // OmniVoice has no Swift inference yet — the model entry exists
        // (so users can download + see the offering) but synthesis
        // routes through Apple fallback until sherpa-onnx ships.
        let omni = LocalVoiceCatalog.omniVoice
        XCTAssertEqual(omni.engineKind, .onnx, "OmniVoice catalog declares ONNX (future SherpaOnnxBackend)")
        XCTAssertTrue(omni.supportsVoiceCloning, "OmniVoice is the voice-cloning entry")
    }

    func test_sherpaOnnxBackend_reportsUnavailable() async {
        // Until a real sherpa-onnx Swift package ships, this backend
        // MUST refuse to load — that's the signal to the dispatcher
        // (and a regression alarm if someone accidentally wires it).
        do {
            try await SherpaOnnxBackend.shared.load(modelPath: nil, model: LocalVoiceCatalog.omniVoice)
            XCTFail("SherpaOnnxBackend.load() must throw until a real Swift implementation lands")
        } catch let error as LocalVoiceError {
            if case .backendNotAvailable = error {
                // expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Plugin boundary

    func test_kokoroRequiresVoicePlugin() async throws {
        let engine = LocalVoiceEngine(model: LocalVoiceCatalog.kokoro)
        do {
            _ = try await engine.synthesize(text: "Hello from Cartridge.")
            XCTFail("Kokoro must require a local voice plugin in the default package graph")
        } catch let error as LocalVoiceError {
            if case .backendNotAvailable = error {
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
}
