#if os(iOS)

// SwooshLocalLLM/LiteRTEngineWrapper.swift — 0.9R local model engine handle
//
// The default SwiftPM graph intentionally does not link a heavyweight
// binary model runtime. Local model engines are loaded through a plugin
// boundary so CLI and daemon verification do not depend on binary
// artifact downloads.

import Foundation

public actor LiteRTEngineWrapper {

    public enum LoadState: Sendable, Equatable {
        case unloaded
        case loading
        case ready
        case failed(String)
    }

    public private(set) var loadState: LoadState = .unloaded

    private var loadedModelPath: String?

    public init() {}

    // MARK: - Lifecycle

    /// Load a `.litertlm` file from disk. The default package graph has
    /// no linked inference runtime, so this reports an explicit failure
    /// instead of silently pretending local generation is available.
    public func load(modelPath: URL) async throws {
        if loadedModelPath == modelPath.path, loadState == .ready { return }
        try await unload()
        loadState = .loading
        loadedModelPath = modelPath.path
        let error = LiteRTWrapperError.backendUnavailable
        loadState = .failed(error.description)
        throw error
    }

    public func unload() async throws {
        loadedModelPath = nil
        loadState = .unloaded
    }

    // MARK: - Generate

    /// Single-shot generate. Returns the full response after the model
    /// finishes decoding.
    public func generate(_ text: String) async throws -> String {
        _ = text
        throw LiteRTWrapperError.backendUnavailable
    }

    /// Streaming generate. The async stream emits chunk text as the
    /// model decodes. Caller can append/concatenate as desired.
    public func generateStream(_ text: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                _ = text
                continuation.finish(throwing: LiteRTWrapperError.backendUnavailable)
            }
        }
    }

    /// Reset the conversation history without unloading the model.
    public func resetConversation() async throws {
        throw LiteRTWrapperError.backendUnavailable
    }
}

// MARK: - Errors

public enum LiteRTWrapperError: Error, CustomStringConvertible {
    case notLoaded
    case backendUnavailable
    case loadFailed(String)

    public var description: String {
        switch self {
        case .notLoaded:        return "Local model is not loaded."
        case .backendUnavailable:
            return "Local model runtime is not linked in the default harness."
        case .loadFailed(let m):return "Local model load failed: \(m)"
        }
    }
}

#endif
