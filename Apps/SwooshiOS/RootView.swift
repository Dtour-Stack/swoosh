// Apps/SwooshiOS/RootView.swift — Cartridge mobile shell

import SwiftUI
import SwooshUI

enum DrawerDestination: Hashable {
    case gameLab
    case connections
    case settings
}

struct RootView: View {
    @Environment(ClientSession.self) private var session
    @State private var shell = AgentShellModel()
    @State private var drawerOpen: Bool = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            AgentRoot(
                shell: shell,
                onOpenDrawer: { withAnimation(.easeOut(duration: 0.22)) { drawerOpen = true } },
                onNavigate: { destination in path.append(destination) }
            )
            .navigationDestination(for: DrawerDestination.self) { destination in
                switch destination {
                case .gameLab:     GameLabScreen()
                case .connections: ConnectionsScreen()
                case .settings:    SettingsScreen()
                }
            }
        }
        .overlay(alignment: .leading) {
            if drawerOpen {
                SideDrawer(
                    isOpen: $drawerOpen,
                    onSelect: { destination in
                        withAnimation(.easeOut(duration: 0.22)) { drawerOpen = false }
                        path.append(destination)
                    }
                )
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
        .environment(shell)
    }
}
