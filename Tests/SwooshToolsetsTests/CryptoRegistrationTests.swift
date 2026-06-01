// Tests/SwooshToolsetsTests/CryptoRegistrationTests.swift

import Foundation
import Testing
@testable import SwooshFiles
@testable import SwooshFirewall
@testable import SwooshProcess
@testable import SwooshTools
@testable import SwooshToolsets

@Suite("Default tool surface excludes crypto")
struct CryptoRegistrationTests {
    @Test("registerAll does not expose crypto tools")
    func cryptoToolsAreNotDefault() async {
        let firewall = SwooshFirewallActor(granted: Set(SwooshPermission.allCases))
        let audit = SwooshAuditLog()
        let approvals = InMemoryApprovalRequester(autoApprove: true)
        let dependencies = ToolDependencies(
            firewall: firewall,
            audit: audit,
            approvals: approvals,
            fileAccess: SafeFileAccessor(rootStore: InMemoryRootStore()),
            processRunner: StreamingProcessRunner()
        )
        let registry = ToolRegistry(firewall: firewall, audit: audit, approvals: approvals)
        await DefaultToolRegistrar.registerAll(into: registry, dependencies: dependencies)

        for name in [
            "evm.chain_info",
            "solana.cluster_info",
            "jupiter.quote",
            "hyperliquid.all_mids",
            "uniswap.quote"
        ] {
            #expect(await registry.getToolSchema(name: ToolName(name)) == nil)
        }
    }
}
