// SwooshUI/Dashboard/DashboardView.swift — Full-window agent dashboard
//
// The primary macOS surface. Pure black background, neon-line language.
// Uses standard window chrome (traffic lights stay) with transparent
// toolbar so the black content shows through. Sidebar is a custom
// neon-styled column, not NavigationSplitView (which adds grey chrome).

#if os(macOS)

import SwiftUI
import SwooshGenerativeUI
import SwooshCloudGaming

// ═══════════════════════════════════════════════════════════════════
// MARK: - Dashboard view
// ═══════════════════════════════════════════════════════════════════

public struct DashboardView: View {
    @Bindable public var shell: AgentShellModel
    public var voice: VoiceMode?

    @State var selectedTab: DashboardTab = .gaming
    @State var sidebarVisible: Bool = true
    @State var gamingSelectedSource: GameSource? = nil
    @State var gamingControllerLayout: InteractiveControllerView.Layout? = nil
    @State var gamingShowSettings: Bool = false

    public init(shell: AgentShellModel, voice: VoiceMode? = nil) {
        self.shell = shell
        self.voice = voice
    }

    public var body: some View {
        HStack(spacing: 0) {
            if sidebarVisible {
                sidebar
                    .frame(width: 240)
                    .transition(.move(edge: .leading).combined(with: .opacity))

                // Thin neon divider
                Rectangle()
                    .fill(SwooshNeonTokens.Line.rule)
                    .frame(width: 0.5)
            }

            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(SwooshNeonTokens.Canvas.bg)
        .animation(.easeOut(duration: 0.22), value: sidebarVisible)
        .focusedSceneValue(\.activeDashboardTab, selectedTab)
        .menuActionHandler(
            shell: shell,
            voice: voice,
            selectedTab: $selectedTab,
            sidebarVisible: $sidebarVisible
        )
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    sidebarVisible.toggle()
                } label: {
                    Image(systemName: "sidebar.left")
                        .foregroundStyle(SwooshNeonTokens.Canvas.text2)
                }
                .accessibilityLabel(sidebarVisible ? "Hide sidebar" : "Show sidebar")
            }
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Brand header — sits below the traffic lights
            HStack(spacing: 8) {
                Text("CARTRIDGE")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(SwooshNeonTokens.Accent.cyan)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)

            // Navigation items
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {
                    sidebarSection("Cartridge") {
                        sidebarRow("Gaming", icon: "gamecontroller.fill", tab: .gaming)
                        sidebarRow("Chat", icon: "bubble.left.and.bubble.right", tab: .chat)
                        if voice != nil {
                            sidebarRow("Voice Mode", icon: "waveform", tab: .voice)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }

            Spacer()

            // ── Contextual section (bottom half) ─────────────
            if selectedTab == .gaming {
                sidebarGamingSection
            }

            // Footer: settings
            VStack(spacing: 0) {
                Rectangle()
                    .fill(SwooshNeonTokens.Line.rule)
                    .frame(height: 0.5)

                Button {
                    selectedTab = .gaming
                    gamingShowSettings = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundStyle(SwooshNeonTokens.Canvas.text2)
                            .frame(width: 22)
                        Text("Game Settings")
                            .font(.system(size: 13))
                            .foregroundStyle(SwooshNeonTokens.Canvas.text2)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .background(SwooshNeonTokens.Canvas.bg)
    }

    @ViewBuilder
    private func sidebarSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(SwooshNeonTokens.Canvas.text3)
                .padding(.horizontal, 12)
                .padding(.top, 20)
                .padding(.bottom, 6)
            content()
        }
    }

    @ViewBuilder
    private func sidebarRow(_ label: String, icon: String, tab: DashboardTab) -> some View {
        let selected = selectedTab == tab
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? SwooshNeonTokens.Accent.cyan : SwooshNeonTokens.Canvas.text2)
                    .frame(width: 22)
                Text(label)
                    .font(.system(size: 13, weight: selected ? .medium : .regular))
                    .foregroundStyle(selected ? SwooshNeonTokens.Canvas.text1 : SwooshNeonTokens.Canvas.text2)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(SwooshNeonTokens.Accent.cyan.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(SwooshNeonTokens.Accent.cyan.opacity(0.16), lineWidth: 0.5)
                        )
                }
            }
        }
        .buttonStyle(.plain)
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Sidebar gaming section (contextual, 2×2 grid)
    // ─────────────────────────────────────────────────────────────────

    private var sidebarGamingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle()
                .fill(SwooshNeonTokens.Line.rule)
                .frame(height: 0.5)
                .padding(.horizontal, 12)

            Text("PLATFORMS")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(SwooshNeonTokens.Canvas.text3)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(CloudGamingService.allCases) { svc in
                    let isSelected: Bool = {
                        if case .web(let s) = gamingSelectedSource { return s == svc }
                        return false
                    }()
                    SidebarPlatformTile(
                        name: svc.displayName,
                        iconOn: svc.iconAssetOn,
                        iconOff: svc.iconAssetOff,
                        accent: Color(hex: svc.accentHex),
                        isSelected: isSelected
                    ) {
                        if isSelected {
                            gamingSelectedSource = nil
                        } else {
                            gamingSelectedSource = .web(svc)
                        }
                    }
                }
                ForEach(NativeGameSource.allCases) { src in
                    let isSelected: Bool = {
                        if case .native(let s) = gamingSelectedSource { return s == src }
                        return false
                    }()
                    SidebarPlatformTile(
                        name: src.displayName,
                        iconOn: src.iconAssetOn,
                        iconOff: src.iconAssetOff,
                        accent: src.brandColor,
                        isSelected: isSelected
                    ) {
                        if isSelected {
                            gamingSelectedSource = nil
                        } else {
                            gamingSelectedSource = .native(src)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .chat:
            AgentShellView(shell: shell, mode: .window)
        case .gaming:
            GamingPane(
                selectedSource: $gamingSelectedSource,
                manualControllerLayout: $gamingControllerLayout,
                showSettingsModal: $gamingShowSettings,
                voiceMode: voice ?? VoiceMode(shell: shell)
            )
        case .voice:
            if let voice {
                VoicePane(voice: voice, shell: shell)
            } else {
                placeholderPane("Voice", icon: "waveform",
                                detail: "Voice mode is not configured.")
            }
        case .memories, .skills, .safety, .approvals, .firewall, .wallet, .models, .tools, .audit, .settings:
            GamingPane(
                selectedSource: $gamingSelectedSource,
                manualControllerLayout: $gamingControllerLayout,
                showSettingsModal: $gamingShowSettings,
                voiceMode: voice ?? VoiceMode(shell: shell)
            )
        }
    }

    @ViewBuilder
    private func placeholderPane(_ title: String, icon: String, detail: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(SwooshNeonTokens.Accent.cyan.opacity(0.25))
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(SwooshNeonTokens.Canvas.text1)
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(SwooshNeonTokens.Canvas.text3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SwooshNeonTokens.Canvas.bg)
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Tab
// ═══════════════════════════════════════════════════════════════════

public enum DashboardTab: String, CaseIterable, Identifiable, Hashable {
    case chat, memories, skills, safety, approvals, firewall, gaming, wallet, models, tools, audit, voice, settings
    public var id: String { rawValue }
}

#endif
