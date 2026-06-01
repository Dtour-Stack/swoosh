#if os(macOS)

// SwooshUI/Interactions/EditMenu.swift — Cartridge menu bar commands

import SwiftUI

public struct SwooshEditCommands: Commands {
    public init() {}

    public var body: some Commands {
        CommandGroup(after: .toolbar) {
            Divider()

            Button("Go to Gaming") {
                NotificationCenter.default.post(name: .swooshNavigateTab, object: "gaming")
            }
            .keyboardShortcut("1", modifiers: [.command])

            Button("Go to Chat") {
                NotificationCenter.default.post(name: .swooshNavigateTab, object: "chat")
            }
            .keyboardShortcut("2", modifiers: [.command])

            Button("Go to Voice Mode") {
                NotificationCenter.default.post(name: .swooshNavigateTab, object: "voice")
            }
            .keyboardShortcut("3", modifiers: [.command])
        }

        CommandMenu("Cartridge") {
            Button("New Game Chat") {
                NotificationCenter.default.post(name: .swooshNewChat, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command])

            Button("Load Local Game URL") {
                NotificationCenter.default.post(name: .swooshGamingNavigateURL, object: "http://localhost:3000")
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])

            Button("Search Game") {
                NotificationCenter.default.post(name: .swooshGamingSearchGame, object: nil)
            }

            Button("Capture Game Screenshot") {
                NotificationCenter.default.post(name: .swooshGamingScreenshotWeb, object: nil)
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Divider()

            Button("Game Settings") {
                NotificationCenter.default.post(name: .swooshNavigateTab, object: "gaming")
            }
        }
    }
}

public extension Notification.Name {
    static let swooshPinSelection       = Notification.Name("ai.swoosh.pinSelection")
    static let swooshSendToChat         = Notification.Name("ai.swoosh.sendToChat")
    static let swooshToggleSidebar      = Notification.Name("ai.swoosh.toggleSidebar")
    static let swooshNavigateTab        = Notification.Name("ai.swoosh.navigateTab")
    static let swooshNewChat            = Notification.Name("ai.swoosh.newChat")
    static let swooshCommandPalette     = Notification.Name("ai.swoosh.commandPalette")
    static let swooshOpenApprovals      = Notification.Name("ai.swoosh.openApprovals")
    static let swooshQuickSearch        = Notification.Name("ai.swoosh.quickSearch")
    static let swooshExplainWhy         = Notification.Name("ai.swoosh.explainWhy")
    static let swooshRegenerateReply    = Notification.Name("ai.swoosh.regenerateReply")
    static let swooshForkChat           = Notification.Name("ai.swoosh.forkChat")
    static let swooshClearChat          = Notification.Name("ai.swoosh.clearChat")
    static let swooshExportMarkdown     = Notification.Name("ai.swoosh.exportMarkdown")
    static let swooshExportJSON         = Notification.Name("ai.swoosh.exportJSON")
    static let swooshAttachFile         = Notification.Name("ai.swoosh.attachFile")
    static let swooshAttachScreenshot   = Notification.Name("ai.swoosh.attachScreenshot")
    static let swooshAttachClipboard    = Notification.Name("ai.swoosh.attachClipboard")
    static let swooshInsertSlashCommand = Notification.Name("ai.swoosh.insertSlashCommand")
    static let swooshRunLastWorkflow    = Notification.Name("ai.swoosh.runLastWorkflow")
    static let swooshRunWorkflow        = Notification.Name("ai.swoosh.runWorkflow")
    static let swooshAddMemory          = Notification.Name("ai.swoosh.addMemory")
    static let swooshSearchMemories     = Notification.Name("ai.swoosh.searchMemories")
    static let swooshReviewCandidates   = Notification.Name("ai.swoosh.reviewCandidates")
    static let swooshApproveAll         = Notification.Name("ai.swoosh.approveAll")
    static let swooshRejectAll          = Notification.Name("ai.swoosh.rejectAll")
    static let swooshRunScout           = Notification.Name("ai.swoosh.runScout")
    static let swooshExportMemories     = Notification.Name("ai.swoosh.exportMemories")
    static let swooshImportMemories     = Notification.Name("ai.swoosh.importMemories")
    static let swooshCreateSkill        = Notification.Name("ai.swoosh.createSkill")
    static let swooshImportSkill        = Notification.Name("ai.swoosh.importSkill")
    static let swooshPromoteSkill       = Notification.Name("ai.swoosh.promoteSkill")
    static let swooshFreezeSkill        = Notification.Name("ai.swoosh.freezeSkill")
    static let swooshReloadBundledSkills = Notification.Name("ai.swoosh.reloadBundledSkills")
    static let swooshExportSkills       = Notification.Name("ai.swoosh.exportSkills")
    static let swooshRefreshWallet      = Notification.Name("ai.swoosh.refreshWallet")
    static let swooshCreateWallet       = Notification.Name("ai.swoosh.createWallet")
    static let swooshImportWallet       = Notification.Name("ai.swoosh.importWallet")
    static let swooshViewExplorer       = Notification.Name("ai.swoosh.viewExplorer")
    static let swooshCopyAddress        = Notification.Name("ai.swoosh.copyAddress")
    static let swooshAddProvider        = Notification.Name("ai.swoosh.addProvider")
    static let swooshConfigureKeys      = Notification.Name("ai.swoosh.configureKeys")
    static let swooshTestProvider       = Notification.Name("ai.swoosh.testProvider")
    static let swooshRefreshModels      = Notification.Name("ai.swoosh.refreshModels")
    static let swooshSwitchToMLX        = Notification.Name("ai.swoosh.switchToMLX")
    static let swooshSwitchToFoundation = Notification.Name("ai.swoosh.switchToFoundation")
    static let swooshDownloadModel      = Notification.Name("ai.swoosh.downloadModel")
    static let swooshGrantPermission    = Notification.Name("ai.swoosh.grantPermission")
    static let swooshRevokeAllPermissions = Notification.Name("ai.swoosh.revokeAllPermissions")
    static let swooshRegisterMCP        = Notification.Name("ai.swoosh.registerMCP")
    static let swooshConnectMCP         = Notification.Name("ai.swoosh.connectMCP")
    static let swooshDisconnectMCP      = Notification.Name("ai.swoosh.disconnectMCP")
    static let swooshFilterToolset      = Notification.Name("ai.swoosh.filterToolset")
    static let swooshShowCryptoTools    = Notification.Name("ai.swoosh.showCryptoTools")
    static let swooshShowDeFiTools      = Notification.Name("ai.swoosh.showDeFiTools")
    static let swooshOpenAuditLog       = Notification.Name("ai.swoosh.openAuditLog")
    static let swooshSearchAudit        = Notification.Name("ai.swoosh.searchAudit")
    static let swooshAuditFilterTool    = Notification.Name("ai.swoosh.auditFilterTool")
    static let swooshAuditFilterPerm    = Notification.Name("ai.swoosh.auditFilterPerm")
    static let swooshAuditFilterCrypto  = Notification.Name("ai.swoosh.auditFilterCrypto")
    static let swooshAuditClearFilters  = Notification.Name("ai.swoosh.auditClearFilters")
    static let swooshExportAudit        = Notification.Name("ai.swoosh.exportAudit")
    static let swooshVerifyAnchors      = Notification.Name("ai.swoosh.verifyAnchors")
    static let swooshToggleVoiceNotif   = Notification.Name("ai.swoosh.toggleVoiceNotif")
    static let swooshSwitchOrbTheme     = Notification.Name("ai.swoosh.switchOrbTheme")
    static let swooshNextOrbTheme       = Notification.Name("ai.swoosh.nextOrbTheme")
    static let swooshPrevOrbTheme       = Notification.Name("ai.swoosh.prevOrbTheme")
    static let swooshTogglePTT          = Notification.Name("ai.swoosh.togglePTT")
    static let swooshToggleTTS          = Notification.Name("ai.swoosh.toggleTTS")
    static let swooshSwitchSTT          = Notification.Name("ai.swoosh.switchSTT")
    static let swooshSwitchTTS          = Notification.Name("ai.swoosh.switchTTS")
    static let swooshOpenAppearance     = Notification.Name("ai.swoosh.openAppearance")
    static let swooshChangeTheme        = Notification.Name("ai.swoosh.changeTheme")
    static let swooshConfigureDaemon    = Notification.Name("ai.swoosh.configureDaemon")
    static let swooshRestartDaemon      = Notification.Name("ai.swoosh.restartDaemon")
    static let swooshScoutDepth         = Notification.Name("ai.swoosh.scoutDepth")
    static let swooshManageSecrets      = Notification.Name("ai.swoosh.manageSecrets")
    static let swooshResetSettings      = Notification.Name("ai.swoosh.resetSettings")
    static let swooshGamingSearchGame   = Notification.Name("ai.swoosh.gaming.searchGame")
    static let swooshGamingClickElement = Notification.Name("ai.swoosh.gaming.clickElement")
    static let swooshGamingTypeText     = Notification.Name("ai.swoosh.gaming.typeText")
    static let swooshGamingNavigateURL  = Notification.Name("ai.swoosh.gaming.navigateURL")
    static let swooshGamingScreenshotWeb = Notification.Name("ai.swoosh.gaming.screenshotWeb")
    static let swooshGamingSelectPlatform = Notification.Name("ai.swoosh.gaming.selectPlatform")
}

#endif
