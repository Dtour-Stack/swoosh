// Apps/SwooshiOS/ClonedVoicesSection.swift — 0.9R Voice clone management
//
// Settings → Voice section that lists every persisted voice clone
// (LocalVoiceCloneStore) and lets the user pick the active one, add a
// new one (via CloneVoiceSheet), or delete an existing one.

import SwiftUI
#if os(iOS)
import SwooshLocalVoice
#endif

struct ClonedVoicesSection: View {
    @State private var clones: [VoiceCloneRecord] = []
    @State private var activeID: String? = ActiveClonePreference.current
    @State private var showingAdd = false
    @State private var deleteError: String?

    var body: some View {
        #if os(iOS)
        Section {
            ForEach(clones) { clone in
                row(clone)
            }
            .onDelete(perform: delete)
            Button {
                showingAdd = true
            } label: {
                Label("Add a new clone", systemImage: "plus.circle.fill")
            }
            .foregroundStyle(.cyan)
        } header: {
            Text("Voice sources")
        } footer: {
            Text("Voice sources persist on this device and become available to local voice plugins.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .task { await reload() }
        .sheet(isPresented: $showingAdd, onDismiss: { Task { await reload() } }) {
            CloneVoiceSheet(onCreated: {})
        }
        #else
        EmptyView()
        #endif
    }

    @ViewBuilder
    private func row(_ clone: VoiceCloneRecord) -> some View {
        Button {
            select(clone.id)
        } label: {
            HStack {
                Image(systemName: activeID == clone.id ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(activeID == clone.id ? .cyan : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(clone.name).foregroundStyle(.primary)
                    Text(clone.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private func select(_ id: String) {
        activeID = id
        ActiveClonePreference.current = id
    }

    private func delete(at offsets: IndexSet) {
        let ids = offsets.map { clones[$0].id }
        Task {
            #if os(iOS)
            var failures: [String] = []
            for id in ids {
                do {
                    try await LocalVoiceCloneStore.shared.delete(id: id)
                    if activeID == id {
                        ActiveClonePreference.current = nil
                        activeID = nil
                    }
                } catch {
                    failures.append("\(id): \(error.localizedDescription)")
                }
            }
            if !failures.isEmpty {
                deleteError = failures.joined(separator: "\n")
            }
            await reload()
            #endif
        }
    }

    @MainActor
    private func reload() async {
        #if os(iOS)
        clones = (try? await LocalVoiceCloneStore.shared.all()) ?? []
        activeID = ActiveClonePreference.current
        #endif
    }
}
