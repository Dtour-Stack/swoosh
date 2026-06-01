// SwooshTools/SafetyConfig.swift — Safety Feature Flags

import Foundation

// MARK: - Safety configuration

/// Controls which advanced capabilities are enabled.
public struct SwooshSafetyConfig: Codable, Sendable, Equatable {
    /// When true, allows browser cookie ingestion for authenticated web-game sessions.
    public var cookieIngestionEnabled: Bool

    /// When true, allows model-origin approval for actions that normally require human review.
    public var modelSelfApprovalEnabled: Bool

    /// When true, lets Cartridge drive desktop game input without per-action human prompts.
    public var autonomousGameControlEnabled: Bool

    /// When true, enables local screen/window capture for playtesting and game navigation.
    public var gameCaptureEnabled: Bool

    /// When true, lets generated assets be written into approved game project folders.
    public var gameAssetWriteEnabled: Bool

    public init(
        cookieIngestionEnabled: Bool = false,
        modelSelfApprovalEnabled: Bool = false,
        autonomousGameControlEnabled: Bool = false,
        gameCaptureEnabled: Bool = false,
        gameAssetWriteEnabled: Bool = false
    ) {
        self.cookieIngestionEnabled = cookieIngestionEnabled
        self.modelSelfApprovalEnabled = modelSelfApprovalEnabled
        self.autonomousGameControlEnabled = autonomousGameControlEnabled
        self.gameCaptureEnabled = gameCaptureEnabled
        self.gameAssetWriteEnabled = gameAssetWriteEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case cookieIngestionEnabled
        case modelSelfApprovalEnabled
        case autonomousGameControlEnabled
        case gameCaptureEnabled
        case gameAssetWriteEnabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            cookieIngestionEnabled: try container.decodeIfPresent(Bool.self, forKey: .cookieIngestionEnabled) ?? false,
            modelSelfApprovalEnabled: try container.decodeIfPresent(Bool.self, forKey: .modelSelfApprovalEnabled) ?? false,
            autonomousGameControlEnabled: try container.decodeIfPresent(Bool.self, forKey: .autonomousGameControlEnabled) ?? false,
            gameCaptureEnabled: try container.decodeIfPresent(Bool.self, forKey: .gameCaptureEnabled) ?? false,
            gameAssetWriteEnabled: try container.decodeIfPresent(Bool.self, forKey: .gameAssetWriteEnabled) ?? false
        )
    }

    public static let defaultAgent = SwooshSafetyConfig()

    public static let development = SwooshSafetyConfig(
        gameCaptureEnabled: true,
        gameAssetWriteEnabled: true
    )

    public static let gameStudio = SwooshSafetyConfig(
        autonomousGameControlEnabled: true,
        gameCaptureEnabled: true,
        gameAssetWriteEnabled: true
    )

    public static let autonomous = SwooshSafetyConfig(
        cookieIngestionEnabled: true,
        modelSelfApprovalEnabled: true,
        autonomousGameControlEnabled: true,
        gameCaptureEnabled: true,
        gameAssetWriteEnabled: true
    )
}

// MARK: - Safety violation

public enum SafetyViolation: Error, Sendable {
    case featureDisabled(String)
    case cookieRejected
    case modelSelfApprovalDenied
    case autonomousGameControlDenied
    case gameCaptureDenied
    case gameAssetWriteDenied

    public var localizedDescription: String {
        switch self {
        case .featureDisabled(let feature):
            return "Feature '\(feature)' is disabled in current safety configuration."
        case .cookieRejected:
            return "Cookie ingestion is disabled."
        case .modelSelfApprovalDenied:
            return "The model cannot approve its own tool calls."
        case .autonomousGameControlDenied:
            return "Autonomous game control is disabled."
        case .gameCaptureDenied:
            return "Game capture is disabled."
        case .gameAssetWriteDenied:
            return "Game asset writes are disabled."
        }
    }
}

// MARK: - Safety guard

/// Convenience methods for checking safety config before tool execution.
extension SwooshSafetyConfig {
    public func requireCookieIngestion() throws {
        guard cookieIngestionEnabled else { throw SafetyViolation.cookieRejected }
    }

    public func requireModelSelfApproval() throws {
        guard modelSelfApprovalEnabled else { throw SafetyViolation.modelSelfApprovalDenied }
    }

    public func requireAutonomousGameControl() throws {
        guard autonomousGameControlEnabled else { throw SafetyViolation.autonomousGameControlDenied }
    }

    public func requireGameCapture() throws {
        guard gameCaptureEnabled else { throw SafetyViolation.gameCaptureDenied }
    }

    public func requireGameAssetWrite() throws {
        guard gameAssetWriteEnabled else { throw SafetyViolation.gameAssetWriteDenied }
    }
}
