// SwooshLocalVoice/Backends/KokoroAneBackend.swift — 0.9R Kokoro adapter
//
// Kokoro remains in the catalog as a provider candidate, but the default
// SwiftPM graph does not link its CoreML runtime. Local CoreML voice
// engines belong behind a plugin/integration boundary so CLI and daemon
// builds do not depend on heavyweight model packages.

import Foundation

actor KokoroAneBackend: Backend {

    static let shared = KokoroAneBackend()

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
