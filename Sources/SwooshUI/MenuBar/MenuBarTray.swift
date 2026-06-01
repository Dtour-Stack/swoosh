// SwooshUI/MenuBar/MenuBarTray.swift — 0.1A Swoosh-native menu-bar tray
//
// The menu-bar popover for the macOS app. Owns a neon tab bar and switches
// between Cartridge's tray surfaces: Chat, Games, Cloud, and Calendar.

#if os(macOS)

import SwiftUI
import AppKit
import SwooshGenerativeUI

public struct MenuBarTray: View {
    @Bindable var shell: AgentShellModel

    public init(shell: AgentShellModel) {
        self.shell = shell
    }

    enum TrayPanel: String, CaseIterable, Identifiable {
        case chat, games, cloud, calendar
        var id: String { rawValue }

        var title: String {
            switch self {
            case .chat: return "Chat"
            case .games: return "Games"
            case .cloud: return "Cloud"
            case .calendar: return "Calendar"
            }
        }

        var icon: String {
            switch self {
            case .chat: return "bubble.left.fill"
            case .games: return "gamecontroller.fill"
            case .cloud: return "cloud.fill"
            case .calendar: return "calendar"
            }
        }
    }

    @State private var selected: TrayPanel = .chat

    public var body: some View {
        VStack(spacing: 0) {
            tabBar
            TrayHairline()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 400, height: 540)
        .background(SwooshNeonTokens.Canvas.bg)
        .environment(\.colorScheme, .dark)
        // MenuBarExtra(.window) popovers don't become key on open, so a
        // TextField inside can't take keyboard focus — the chat field then
        // silently ignores typing/Return. Activating the app makes the
        // popover focusable.
        .onAppear { NSApp.activate(ignoringOtherApps: true) }
    }

    @ViewBuilder
    private var content: some View {
        switch selected {
        case .chat: AgentShellView(shell: shell, mode: .tray)
        case .games: gamesPanel
        case .cloud: CloudTrayPanel()
        case .calendar: CalendarTrayPanel()
        }
    }

    private var gamesPanel: some View {
        TrayPanelScaffold(
            title: "Games",
            subtitle: "Load, test, and generate",
            icon: "gamecontroller.fill",
            accent: .cyan,
            openTab: "gaming"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                TrayStatusRow(icon: "link", message: "Load a local game URL from the dashboard.")
                TrayStatusRow(icon: "cube.transparent", message: "Generate 2D sprites and 3D assets through Cartridge.")
                TrayStatusRow(icon: "terminal", message: "Use CLI starters for game agents and characters.")
            }
        }
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(TrayPanel.allCases) { panel in
                tabButton(panel)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 9)
        .padding(.bottom, 6)
    }

    private func tabButton(_ panel: TrayPanel) -> some View {
        let isSelected = selected == panel
        let accent = NeonAccent.cyan.color
        return Button {
            withAnimation(.spring(duration: 0.25, bounce: 0.15)) {
                selected = panel
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: panel.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(panel.title)
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(isSelected ? accent : SwooshNeonTokens.Canvas.text3)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.12) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? accent.opacity(SwooshNeonTokens.Line.dim) : .clear,
                                  lineWidth: SwooshNeonTokens.Line.width)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(panel.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#endif
