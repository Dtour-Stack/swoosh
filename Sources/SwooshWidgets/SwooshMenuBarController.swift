// SwooshWidgets/SwooshMenuBarController.swift
// Native macOS menu bar integration for Cartridge status.
//
// Shows: game harness status, pending approvals, and active playtests.
// Clicking the menu bar item opens the full TUI or approval queue.

import Foundation
#if canImport(AppKit)
import AppKit

@MainActor
public final class SwooshMenuBarController: NSObject {

    // MARK: - State

    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    private var refreshTimer: Timer?

    private var snapshot: SwooshWidgetSnapshot?

    public var onShowTUI: (() -> Void)?
    public var onShowApprovals: (() -> Void)?
    public var onQuit: (() -> Void)?

    // MARK: - Lifecycle

    public override init() { super.init() }

    public func install() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(menuBarClicked)
        statusItem?.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])
        buildMenu()
        refresh()
        startRefreshTimer()
    }

    public func uninstall() {
        refreshTimer?.invalidate()
        if let item = statusItem { NSStatusBar.system.removeStatusItem(item) }
        statusItem = nil
    }

    // MARK: - Timer

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
    }

    // MARK: - Data refresh

    private func refresh() {
        snapshot = SwooshWidgetSnapshot.load()
        updateButton()
        buildMenu()
    }

    // MARK: - Button title

    private func updateButton() {
        guard let button = statusItem?.button else { return }

        let icon = systemStatusIcon()
        var title = icon

        // Pending approvals badge
        if let pending = snapshot?.pendingApprovals, pending > 0 {
            title += " ⚡\(pending)"
        }

        if let snap = snapshot, snap.activeWorkflows > 0 {
            title += "  \(snap.activeWorkflows) playtest\(snap.activeWorkflows == 1 ? "" : "s")"
        }

        button.title = title
    }

    private func systemStatusIcon() -> String {
        switch snapshot?.systemStatus {
        case .healthy: return "⚡"
        case .degraded: return "⚠️"
        case .offline: return "🔴"
        case nil: return "◉"
        }
    }

    // MARK: - Menu

    private func buildMenu() {
        let m = NSMenu()
        m.autoenablesItems = false

        // Header
        let header = NSMenuItem(title: "Cartridge", action: nil, keyEquivalent: "")
        header.isEnabled = false
        m.addItem(header)
        m.addItem(.separator())

        // Status row
        if let snap = snapshot {
            let statusItem = NSMenuItem(title: statusSummary(snap), action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            m.addItem(statusItem)
            m.addItem(.separator())

            // Pending approvals
            if snap.pendingApprovals > 0 {
                let appItem = NSMenuItem(
                    title: "⚡ \(snap.pendingApprovals) Pending Approval\(snap.pendingApprovals == 1 ? "" : "s")",
                    action: #selector(showApprovals),
                    keyEquivalent: ""
                )
                appItem.target = self
                m.addItem(appItem)
                m.addItem(.separator())
            }
        }

        if let snap = snapshot {
            let harnessHeader = NSMenuItem(title: "Game Harness", action: nil, keyEquivalent: "")
            harnessHeader.isEnabled = false
            m.addItem(harnessHeader)
            for title in gameHarnessRows(snap) {
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                m.addItem(item)
            }
            m.addItem(.separator())
        }

        // Actions
        let openItem = NSMenuItem(title: "Open Swoosh", action: #selector(openTUI), keyEquivalent: "")
        openItem.target = self
        m.addItem(openItem)

        m.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Swoosh", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        m.addItem(quitItem)

        menu = m
    }

    private func statusSummary(_ snap: SwooshWidgetSnapshot) -> String {
        var parts: [String] = []
        if snap.activeAgents > 0 { parts.append("\(snap.activeAgents) agent\(snap.activeAgents == 1 ? "" : "s")") }
        if snap.activeWorkflows > 0 { parts.append("\(snap.activeWorkflows) workflow\(snap.activeWorkflows == 1 ? "" : "s")") }
        if parts.isEmpty { parts.append("idle") }
        if let cost = snap.totalCost { parts.append(cost) }
        return parts.joined(separator: " · ")
    }

    private func gameHarnessRows(_ snap: SwooshWidgetSnapshot) -> [String] {
        [
            "Agents: \(snap.activeAgents)",
            "Playtests: \(snap.activeWorkflows)",
            "Approvals: \(snap.pendingApprovals)",
        ]
    }

    // MARK: - Actions

    @objc private func menuBarClicked() {
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func openTUI() { onShowTUI?() }
    @objc private func showApprovals() { onShowApprovals?() }
    @objc private func quitApp() { onQuit?() }
}

#endif
