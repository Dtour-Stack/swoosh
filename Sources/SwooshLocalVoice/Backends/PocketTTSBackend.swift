// SwooshLocalVoice/Backends/PocketTTSBackend.swift — 0.9R Persistent cloning adapter
//
// PocketTTS remains a catalog candidate, but its CoreML runtime is not
// part of the default package graph. The default harness keeps voice
// prompts on system/cloud providers and loads local model SDKs through
// plugin boundaries.

import Foundation

actor PocketTTSBackend: Backend {

    static let shared = PocketTTSBackend()

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

    /// Load a previously-persisted voice enrollment blob from the shared
    /// store. Returns nil when the clone id doesn't exist on disk.
    static func loadStoredVoiceData(cloneID: String) async throws -> Data? {
        guard let bytes = try await LocalVoiceCloneStore.shared.voiceDataBytes(id: cloneID) else {
            return nil
        }
        return bytes
    }
}
