// Tests/SwooshToolsetsTests/DefaultToolRegistrarTests.swift

import Foundation
import Testing
@testable import SwooshFiles
@testable import SwooshFirewall
@testable import SwooshProcess
@testable import SwooshTools
@testable import SwooshToolsets

private struct TestHarness: Sendable {
    let firewall: SwooshFirewallActor
    let audit: SwooshAuditLog
    let approvals: InMemoryApprovalRequester
    let dependencies: ToolDependencies

    init() {
        let firewall = SwooshFirewallActor()
        let audit = SwooshAuditLog()
        let approvals = InMemoryApprovalRequester(autoApprove: true)
        self.firewall = firewall
        self.audit = audit
        self.approvals = approvals
        self.dependencies = ToolDependencies(
            firewall: firewall,
            audit: audit,
            approvals: approvals,
            fileAccess: SafeFileAccessor(rootStore: InMemoryRootStore()),
            processRunner: StreamingProcessRunner()
        )
    }

    func makeRegistry() -> ToolRegistry {
        ToolRegistry(firewall: firewall, audit: audit, approvals: approvals)
    }

    func descriptors() async -> [ToolDescriptor] {
        let registry = makeRegistry()
        await DefaultToolRegistrar.registerAll(into: registry, dependencies: dependencies)
        return await registry.listAvailable(context: ToolContext(sessionID: "test"))
    }
}

@Suite("DefaultToolRegistrar")
struct DefaultToolRegistrarTests {
    @Test("registerAll exposes Cartridge core and game harness tools")
    func registerAllSucceeds() async {
        let descriptors = await TestHarness().descriptors()
        let names = Set(descriptors.map(\.name))
        #expect(names.contains("core.status"))
        #expect(names.contains("core.list_tools"))
        #expect(names.contains("game.list_sessions"))
        #expect(names.contains("game.list_cli_starters"))
        #expect(names.contains("game.list_3d_generation_providers"))
        #expect(names.contains("game.list_2d_creation_providers"))
        #expect(names.contains("game.init_cli_starter"))
        #expect(names.contains("game.load_local_url"))
        #expect(names.contains("game.record_observation"))
        #expect(names.contains("game.record_action"))
        #expect(names.contains("game.generate_content"))
        #expect(names.contains("game.save_pipeline"))
        #expect(names.contains("game.import_pipeline"))
        #expect(names.contains("game.evaluate_session"))
    }

    @Test("registerAll no longer exposes non-gaming tool families")
    func defaultSurfaceIsGamingOnly() async {
        let descriptors = await TestHarness().descriptors()
        let names = Set(descriptors.map(\.name))
        let removedPrefixes = [
            "file.", "git.", "memory.", "audit.", "permissions.",
            "workflow.", "web.", "mcp.", "calendar.", "skill.", "goal.",
            "manifest.", "cron."
        ]

        for prefix in removedPrefixes {
            #expect(!names.contains { $0.hasPrefix(prefix) })
        }
    }

    @Test("Re-registering is idempotent on tool count")
    func idempotent() async {
        let harness = TestHarness()
        let registry = harness.makeRegistry()
        await DefaultToolRegistrar.registerAll(into: registry, dependencies: harness.dependencies)
        let first = await registry.listAvailable(context: ToolContext(sessionID: "t")).count

        await DefaultToolRegistrar.registerAll(into: registry, dependencies: harness.dependencies)
        let second = await registry.listAvailable(context: ToolContext(sessionID: "t")).count
        #expect(first == second)
    }

    @Test("Harness creates independent registries")
    func independentRegistries() async {
        let harness1 = TestHarness()
        let harness2 = TestHarness()
        let descriptors1 = await harness1.descriptors()
        let descriptors2 = await harness2.descriptors()
        let names1 = Set(descriptors1.map(\.name))
        let names2 = Set(descriptors2.map(\.name))
        #expect(names1 == names2)
        #expect(names1.count > 0)
    }

    @Test("Harness with manual approval mode still registers the game catalog")
    func manualApprovalMode() async {
        let firewall = SwooshFirewallActor()
        let audit = SwooshAuditLog()
        let approvals = InMemoryApprovalRequester(autoApprove: false)
        let dependencies = ToolDependencies(
            firewall: firewall,
            audit: audit,
            approvals: approvals,
            fileAccess: SafeFileAccessor(rootStore: InMemoryRootStore()),
            processRunner: StreamingProcessRunner()
        )

        let registry = ToolRegistry(firewall: firewall, audit: audit, approvals: approvals)
        await DefaultToolRegistrar.registerAll(into: registry, dependencies: dependencies)
        let descriptors = await registry.listAvailable(context: ToolContext(sessionID: "test"))
        let names = Set(descriptors.map(\.name))
        #expect(names.contains("game.list_cli_starters"))
        #expect(names.contains("game.load_local_url"))
    }

    @Test("Harness tool metadata consistency")
    func toolMetadataConsistency() async {
        let descriptors = await TestHarness().descriptors()
        for descriptor in descriptors {
            #expect(!descriptor.name.isEmpty)
            #expect(!descriptor.description.isEmpty)
            #expect(descriptor.toolset == .core || descriptor.toolset == .gaming)
        }
    }

    @Test("Harness registry isolation")
    func registryIsolation() async {
        let harness = TestHarness()
        let registry1 = harness.makeRegistry()
        let registry2 = harness.makeRegistry()

        await DefaultToolRegistrar.registerAll(into: registry1, dependencies: harness.dependencies)

        let tools1 = await registry1.listAvailable(context: ToolContext(sessionID: "test"))
        let tools2 = await registry2.listAvailable(context: ToolContext(sessionID: "test"))

        #expect(tools1.count > 0)
        #expect(tools2.count == 0)
    }
}
