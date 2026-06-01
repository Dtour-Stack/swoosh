// SwooshCapabilities/CapabilityRouter+MediaGen.swift
// Version: 0.9R
//
// Video + 3D generation routing. Extracted from CapabilityRouter to keep
// the root router file under the LOC ceiling. The active executable
// providers in this router are cloud FAL endpoints; Cartridge's game
// catalog tracks additional local-hostable 3D targets.
//
// FAL key is read hot from Keychain on every provider construction —
// rotating the key in Settings → Provider keys takes effect on the next
// `activeVideoProvider()` / `activeThreeDProvider()` call.

import Foundation
import SwooshSecrets
import SwooshImageGen

extension CapabilityRouter {

    // MARK: - Video generation

    public enum VideoChoice: String, Sendable, CaseIterable, Identifiable {
        case falVeo3            = "fal-veo3"
        case falKlingText       = "fal-kling-text"
        case falKlingImage      = "fal-kling-image"
        case falHunyuan         = "fal-hunyuan"
        case falLuma            = "fal-luma"

        public var id: String { rawValue }

        /// FAL model identifier used when constructing the request.
        public var modelID: String {
            switch self {
            case .falVeo3:        return "fal-ai/veo3"
            case .falKlingText:   return "fal-ai/kling-video/v2/master/text-to-video"
            case .falKlingImage:  return "fal-ai/kling-video/v2/master/image-to-video"
            case .falHunyuan:     return "fal-ai/hunyuan-video"
            case .falLuma:        return "fal-ai/luma-dream-machine"
            }
        }

        public var displayName: String {
            switch self {
            case .falVeo3:        return "FAL · Google Veo 3"
            case .falKlingText:   return "FAL · Kling 2.0 (text-to-video)"
            case .falKlingImage:  return "FAL · Kling 2.0 (image-to-video)"
            case .falHunyuan:     return "FAL · Hunyuan Video"
            case .falLuma:        return "FAL · Luma Dream Machine"
            }
        }

        public var isLocal: Bool { false }
    }

    public var currentVideoChoice: VideoChoice {
        get {
            let raw = UserDefaults.standard.string(forKey: "swoosh.capabilities.video") ?? "fal-veo3"
            return VideoChoice(rawValue: raw) ?? .falVeo3
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "swoosh.capabilities.video") }
    }

    /// Returns a configured video provider, or nil when no FAL key has
    /// been stored in Keychain. Callers should surface a "Configure FAL
    /// key" UI affordance when nil.
    public func activeVideoProvider() -> (any VideoGenProviding)? {
        guard isVideoConfigured else { return nil }
        let client = FALClient(
            apiKey: KeychainAPIKeyProvider.for(KeychainProviderID.fal)
        )
        return FALVideoProvider(client: client)
    }

    public var isVideoConfigured: Bool {
        KeychainAPIKeyProvider.isConfigured(providerID: KeychainProviderID.fal)
    }

    // MARK: - 3D generation

    public enum ThreeDChoice: String, Sendable, CaseIterable, Identifiable {
        case falHunyuan3DProText  = "fal-hunyuan3d-pro-text"
        case falHunyuan3DProImage = "fal-hunyuan3d-pro-image"
        case falTrellis2          = "fal-trellis-2"
        case falTripo3D        = "fal-tripo3d"
        case falTrellis        = "fal-trellis"
        case falTripoSR        = "fal-triposr"
        case falHunyuan3D      = "fal-hunyuan3d"

        public var id: String { rawValue }

        public var modelID: String {
            switch self {
            case .falHunyuan3DProText:  return "fal-ai/hunyuan-3d/v3.1/pro/text-to-3d"
            case .falHunyuan3DProImage: return "fal-ai/hunyuan-3d/v3.1/pro/image-to-3d"
            case .falTrellis2:          return "fal-ai/trellis-2"
            case .falTripo3D:    return "fal-ai/tripo3d"
            case .falTrellis:    return "fal-ai/trellis"
            case .falTripoSR:    return "fal-ai/triposr"
            case .falHunyuan3D:  return "fal-ai/hunyuan3d/v2"
            }
        }

        public var displayName: String {
            switch self {
            case .falHunyuan3DProText:  return "FAL · Hunyuan 3D v3.1 Pro (text)"
            case .falHunyuan3DProImage: return "FAL · Hunyuan 3D v3.1 Pro (image)"
            case .falTrellis2:          return "FAL · Trellis 2"
            case .falTripo3D:    return "FAL · Tripo3D"
            case .falTrellis:    return "FAL · Trellis"
            case .falTripoSR:    return "FAL · TripoSR"
            case .falHunyuan3D:  return "FAL · Hunyuan3D 2.0"
            }
        }

        public var isLocal: Bool { false }
    }

    public var currentThreeDChoice: ThreeDChoice {
        get {
            let raw = UserDefaults.standard.string(forKey: "swoosh.capabilities.threeD") ?? "fal-hunyuan3d-pro-text"
            return ThreeDChoice(rawValue: raw) ?? .falHunyuan3DProText
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "swoosh.capabilities.threeD") }
    }

    public func activeThreeDProvider() -> (any ThreeDGenProviding)? {
        guard isThreeDConfigured else { return nil }
        let client = FALClient(
            apiKey: KeychainAPIKeyProvider.for(KeychainProviderID.fal)
        )
        return FALThreeDProvider(client: client)
    }

    public var isThreeDConfigured: Bool {
        KeychainAPIKeyProvider.isConfigured(providerID: KeychainProviderID.fal)
    }
}
