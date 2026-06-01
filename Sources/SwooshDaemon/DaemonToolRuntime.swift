// SwooshDaemon/DaemonToolRuntime.swift — 0.9S Tool registry + dependency wiring
//
// Builds the daemon's `ToolRegistry` + matching `ToolDependencies` —
// firewall, audit log, approval centre, file access, process runner,
// RPC clients and secret resolver. Mounted once at boot
// from `Daemon.swift` and threaded into every API bridge that calls
// tools.

import Foundation
import SwooshApprovals
import SwooshCore
import SwooshFiles
import SwooshFirewall
import SwooshFlow
import SwooshProcess
import SwooshSecrets
import SwooshStorage
import SwooshTools
import SwooshToolsets

struct DaemonToolRuntime: Sendable {
    let registry: ToolRegistry
    let dependencies: ToolDependencies
    let firewall: SwooshFirewallActor
    let audit: any AuditLogging
    let baselineGrants: Set<SwooshPermission>
}

func makeDaemonToolRuntime(
    swooshDir: URL,
    grantedPermissions: Set<SwooshPermission>,
    safetyConfig: SwooshSafetyConfig,
    database: SwooshDatabase? = nil
) async throws -> DaemonToolRuntime {
    // Durable SQLite stores when database is available, in-memory fallback otherwise.
    let audit: any AuditLogging
    let approvalStore: any ApprovalStoring
    let memoryStore: any MemoryToolStoring

    if let db = database {
        audit = SQLiteAuditLog(db: db)
        approvalStore = SQLiteApprovalStore(db: db)
        memoryStore = SQLiteMemoryStore(db: db)
    } else {
        audit = SwooshAuditLog()
        approvalStore = InMemoryApprovalStore()
        memoryStore = InMemoryMemoryToolStore()
    }

    // ── Firewall with durable permission persistence ─────────────
    let firewall: SwooshFirewallActor
    if let db = database {
        let permStore = SQLitePermissionStore(db: db)
        firewall = SwooshFirewallActor(persister: permStore)
        await firewall.loadPersistedGrants()
        // Layer baseline profile grants on top of persisted ones
        await firewall.grantAll(grantedPermissions)
    } else {
        firewall = SwooshFirewallActor(granted: grantedPermissions)
    }

    let approvalCenter = SwooshApprovals.ApprovalCenter(
        store: approvalStore, audit: audit)
    let rootStore = InMemoryRootStore()
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        .standardizedFileURL
    await rootStore.add(ApprovedRoot(
        id: "cwd",
        displayName: cwd.lastPathComponent.isEmpty ? cwd.path : cwd.lastPathComponent,
        absolutePath: cwd.path,
        allowedRead: true,
        allowedWrite: true
    ))
    await rootStore.add(ApprovedRoot(
        id: "swoosh-state",
        displayName: ".swoosh",
        absolutePath: swooshDir.standardizedFileURL.path,
        allowedRead: true,
        allowedWrite: true
    ))

    let registry = ToolRegistry(
        firewall: firewall,
        audit: audit,
        approvals: approvalCenter,
        safetyConfig: safetyConfig
    )
    // Secret resolver backs provider and RPC endpoint refs.
    let secretResolver = KeychainSecretResolver(store: KeychainSecretStore())
    // Concrete JSON-RPC clients. The endpoint URL is resolved per call
    // from the chain/cluster (Keychain ref → env override → public
    // fallback); these clients are read/broadcast only — no private keys.
    let evmClient = URLSessionEVMRPCClient(secrets: secretResolver)
    let solanaClient = URLSessionSolanaRPCClient(secrets: secretResolver)
    let dependencies = ToolDependencies(
        firewall: firewall,
        audit: audit,
        approvals: approvalCenter,
        safetyConfig: safetyConfig,
        fileAccess: SafeFileAccessor(rootStore: rootStore),
        processRunner: StreamingProcessRunner(approvedRoots: [cwd.path, swooshDir.path]),
        evmClient: evmClient,
        solanaClient: solanaClient,
        walletBridge: nil,
        memoryStore: memoryStore,
        workflowStore: FileWorkflowToolStore(url: swooshDir.appendingPathComponent("workflows/tool-drafts.json")),
        workflowStepExecutor: TracingWorkflowStepExecutor(
            inner: RegistryWorkflowStepExecutor(registry: registry),
            recorder: InMemoryWorkflowTraceRecorder(),
            workflowID: "daemon"
        ),
        secrets: secretResolver
    )
    return DaemonToolRuntime(
        registry: registry,
        dependencies: dependencies,
        firewall: firewall,
        audit: audit,
        baselineGrants: grantedPermissions
    )
}
