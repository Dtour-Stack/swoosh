// SwooshCLI/RuntimePolicyCommands.swift — Permissions command + setup helpers — 1.1.6

import ArgumentParser
import SwooshConfig
import SwooshSecrets
import SwooshTools
import Foundation

// MARK: - Permissions

struct PermissionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "permissions", abstract: "View and manage permission profile.")
    @Flag(name: .long, help: "Show current permission status.")
    var status = false
    func run() async throws {
        guard status else {
            print("Use `swoosh setup permissions` for the profile summary.")
            print("Use `swoosh permissions --status` to view the runtime policy.")
            return
        }
        printRuntimePolicyStatus()
        print("─── Permissions ──────────────────────────────")
        print("  Durable approval backend not wired. Showing runtime policy only.")
    }
}

private func printRuntimePolicyStatus() {
    let runtime = try? SwooshConfigStore().load(SwooshRuntimeConfig.self)
    let preset = PermissionProfilePreset(rawValue: runtime?.permissionProfile ?? "") ?? .developer
    let policy = runtime?.toolPolicy ?? preset.defaultToolPolicy
    let safety = runtime?.safetyConfig ?? preset.defaultSafetyConfig
    print("─── Runtime Policy ───────────────────────────")
    print("Profile: \(runtime?.permissionProfile ?? preset.rawValue)")
    print("Granted permissions: \(preset.grantedSwooshPermissions.count)")
    print("Model tool calls: \(policy.allowModelToolCalls ? "enabled" : "disabled")")
    print("Max tool calls: \(policy.maxToolCallsPerTurn)")
    print("Max chain depth: \(policy.maxToolChainDepth)")
    print("Human-only from model: \(policy.allowHumanOnlyFromModel ? "allowed" : "blocked")")
    print("Critical tools from model: \(policy.allowCriticalToolsFromModel ? "allowed" : "blocked")")
    print("Medium-risk approval: \(policy.requireApprovalForMediumRiskAndAbove ? "required" : "optional")")
    print("Model self-approval: \(safety.modelSelfApprovalEnabled ? "enabled" : "disabled")")
    print("Mainnet writes by default: \(safety.mainnetWritesByDefault ? "enabled" : "disabled")")
}

// MARK: - Helpers

func printBanner() {
    print("""
    ╔═══════════════════════════════════════════╗
    ║                 Swoosh                    ║
    ║   Swift-native agent runtime for macOS    ║
    ╚═══════════════════════════════════════════╝
    """)
}

func printPreflight(_ hw: HardwareProfile) {
    print("─── Preflight ─────────────────────────────────\n")
    print("  \(hw.hasAppleSilicon ? "✓" : "○") \(hw.cpuName.trimmingCharacters(in: .whitespacesAndNewlines))")
    print("  \(hw.totalMemoryGB >= 8 ? "✓" : "○") \(Int(hw.totalMemoryGB)) GB unified memory")
    print("  ✓ Keychain available")
    print("  \(hw.hasGit ? "✓" : "✗") Git \(hw.hasGit ? "installed" : "not found")")
    print("  \(hw.hasXcodeTools ? "✓" : "○") Xcode tools \(hw.hasXcodeTools ? "installed" : "not found")")
    print("  \(hw.hasDocker ? "✓" : "○") Docker \(hw.hasDocker ? "installed" : "not installed — optional")")
    print("  \(hw.hasNode ? "✓" : "○") Node \(hw.hasNode ? "installed" : "not installed — optional")")
    print("  \(hw.hasPython ? "✓" : "○") Python \(hw.hasPython ? "installed" : "not installed — optional")")

    let recs = hw.recommendedLocalModels.filter { $0.fits == .recommended || $0.fits == .feasible }
    if !recs.isEmpty {
        print("\n  Local models: can run \(recs.map(\.sizeLabel).joined(separator: ", "))")
    }
    print()
}
