// SwooshLocalVoice/Backends/StyleTTS2Backend.swift — 0.9R Zero-shot cloning adapter
//
// StyleTTS2 remains a catalog candidate, but its CoreML runtime is not
// part of the default package graph. A voice plugin can provide the
// concrete backend without making every CLI build clone model SDKs.

import Foundation

actor StyleTTS2Backend: Backend {

    static let shared = StyleTTS2Backend()

    func load(modelPath: URL?, model: LocalVoiceModel) async throws {
        _ = modelPath
        throw LocalVoiceError.backendNotAvailable(
            "\(model.displayName) requires a local voice plugin. Use system or cloud TTS in the default harness."
        )
    }

    func synthesize(
        text: String,
        voiceID: String?,
        referenceAudio: URL?,
        model: LocalVoiceModel
    ) async throws -> Data {
        _ = text
        _ = voiceID
        _ = referenceAudio
        throw LocalVoiceError.backendNotAvailable(
            "\(model.displayName) requires a local voice plugin. Use system or cloud TTS in the default harness."
        )
    }
}
