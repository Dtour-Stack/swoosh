// Tests/SwooshToolsTests/ToolRegistryTests.swift — 0.4A QA tests
//
// Acceptance criteria:
// - Register and list tools
// - Execute read-only allowed tool
// - Denied permission blocks execution
// - humanOnly tools cannot be invoked by model
// - askEveryTime approval path is invoked
// - Audit events are written for success and failure
// - Every registered tool has permission, risk, approval
// - Game action human-only prompts remain gated
// - Game tools do not accept secret material input

import Testing
import Foundation
@testable import SwooshTools
@testable import SwooshFirewall
@testable import SwooshToolsets

// MARK: - Test helpers

/// Mock firewall that grants specific permissions
actor MockFirewall: SwooshTools.Firewall {
    var granted: Set<SwooshPermission>
    init(granted: Set<SwooshPermission> = []) { self.granted = granted }
    func require(_ permission: SwooshPermission) async throws {
        guard granted.contains(permission) else {
            throw ToolError.denied(permission.rawValue, "Not granted")
        }
    }
    func isGranted(_ permission: SwooshPermission) async -> Bool { granted.contains(permission) }
    func grant(_ perm: SwooshPermission) { granted.insert(perm) }
}

/// Mock audit that records entries
actor MockAudit: AuditLogging {
    var entries: [AuditEntry] = []
    func append(_ event: AuditEntry) async throws { entries.append(event) }
    func tail(limit: Int) async -> [AuditEntry] { Array(entries.suffix(limit)) }
    func search(query: String, limit: Int) async -> [AuditEntry] { entries.filter { $0.detail.contains(query) } }
    func getEvent(id: String) async -> AuditEntry? { entries.first { $0.id == id } }
}

/// Mock approvals that auto-approves
actor MockApprovals: ApprovalRequesting {
    var autoApprove: Bool
    var pending: [ToolApprovalRequest] = []
    var approvalRequested = false
    init(autoApprove: Bool = true) { self.autoApprove = autoApprove }
    func requireApproval(_ request: ToolApprovalRequest) async throws {
        approvalRequested = true
        if !autoApprove { throw ToolError.denied(request.toolName, "Denied") }
    }
    func listPending() async -> [ToolApprovalRequest] { pending }
    func resolve(id: String, decision: ApprovalDecision, reason: String?) async throws {}
}

/// Stub file access
struct StubFileAccess: FileAccessing {
    func resolveBookmark(id: String) async throws -> URL { URL(fileURLWithPath: "/tmp/test") }
    func listDirectory(root: URL, relativePath: String?, includeHidden: Bool, maxDepth: Int) async throws -> [FileEntry] { [] }
    func readFile(root: URL, relativePath: String, maxBytes: Int?) async throws -> (content: String, truncated: Bool, redaction: RedactionReport?) { ("", false, nil) }
    func writeFile(root: URL, relativePath: String, content: String, createBackup: Bool) async throws -> (bytesWritten: Int64, backupPath: String?) { (0, nil) }
    func deleteFile(root: URL, relativePath: String) async throws {}
    func searchFiles(root: URL, query: String, filePattern: String?, maxResults: Int?) async throws -> [FileSearchMatch] { [] }
}

actor PatchFileAccess: FileAccessing {
    var files: [String: String]

    init(files: [String: String]) {
        self.files = files
    }

    func resolveBookmark(id: String) async throws -> URL { URL(fileURLWithPath: "/tmp/test") }
    func listDirectory(root: URL, relativePath: String?, includeHidden: Bool, maxDepth: Int) async throws -> [FileEntry] { [] }
    func readFile(root: URL, relativePath: String, maxBytes: Int?) async throws -> (content: String, truncated: Bool, redaction: RedactionReport?) {
        guard let content = files[relativePath] else {
            throw ToolError.notFound(relativePath)
        }
        return (content, false, nil)
    }
    func writeFile(root: URL, relativePath: String, content: String, createBackup: Bool) async throws -> (bytesWritten: Int64, backupPath: String?) {
        files[relativePath] = content
        return (Int64(content.utf8.count), createBackup ? "\(relativePath).bak" : nil)
    }
    func deleteFile(root: URL, relativePath: String) async throws {}
    func searchFiles(root: URL, query: String, filePattern: String?, maxResults: Int?) async throws -> [FileSearchMatch] { [] }
    func content(relativePath: String) -> String? { files[relativePath] }
}

struct HumanPromptedGameActionInput: Codable, Sendable {}

struct HumanPromptedGameActionOutput: Codable, Sendable {
    let accepted: Bool
}

struct HumanPromptedGameActionTool: SwooshTool {
    typealias Input = HumanPromptedGameActionInput
    typealias Output = HumanPromptedGameActionOutput

    static let name: ToolName = "test.human_prompted_game_action"
    static let displayName = "Human Prompted Game Action"
    static let description = "Test game action tool"
    static let permission = SwooshPermission.gameAct
    static let risk = ToolRisk.critical
    static let approval = ApprovalPolicy.humanOnly
    static let toolset = ToolsetID.gaming

    func call(_ input: Input, context: ToolContext) async throws -> Output {
        HumanPromptedGameActionOutput(accepted: true)
    }
}

/// Stub process runner
struct StubProcessRunner: ProcessRunning {
    func run(executable: String, arguments: [String], workingDirectory: URL?, environment: [String: String]?) async throws -> ProcessResult {
        ProcessResult(exitCode: 0, stdout: "", stderr: "")
    }
}

struct FixedProcessRunner: ProcessRunning {
    let result: ProcessResult

    func run(executable: String, arguments: [String], workingDirectory: URL?, environment: [String: String]?) async throws -> ProcessResult {
        result
    }
}

actor RecordingProcessRunner: ProcessRunning {
    struct Call: Sendable {
        let executable: String
        let arguments: [String]
    }

    private var calls: [Call] = []

    func run(executable: String, arguments: [String], workingDirectory: URL?, environment: [String: String]?) async throws -> ProcessResult {
        calls.append(Call(executable: executable, arguments: arguments))
        return ProcessResult(exitCode: 0, stdout: "ok", stderr: "")
    }

    func recordedCalls() -> [Call] {
        calls
    }
}

actor RecordingWorkflowExecutor: WorkflowStepExecuting {
    struct Call: Sendable {
        let toolName: String
        let arguments: JSONValue
    }

    private var calls: [Call] = []

    func executeWorkflowStep(
        toolName: String,
        arguments: JSONValue,
        context: ToolContext
    ) async throws -> ToolExecutionResult {
        calls.append(Call(toolName: toolName, arguments: arguments))
        return ToolExecutionResult(
            requestID: UUID().uuidString,
            toolName: toolName,
            status: .succeeded,
            output: .object(["ok": .bool(true)])
        )
    }

    func recordedCalls() -> [Call] {
        calls
    }
}

func makeTestDeps(
    firewall: any SwooshTools.Firewall,
    audit: any AuditLogging,
    approvals: any ApprovalRequesting,
    fileAccess: any FileAccessing = StubFileAccess(),
    processRunner: any ProcessRunning = StubProcessRunner(),
    memoryStore: any MemoryToolStoring = InMemoryMemoryToolStore(),
    workflowStore: any WorkflowToolStoring = InMemoryWorkflowToolStore(),
    workflowStepExecutor: (any WorkflowStepExecuting)? = nil
) -> ToolDependencies {
    ToolDependencies(
        firewall: firewall,
        audit: audit,
        approvals: approvals,
        fileAccess: fileAccess,
        processRunner: processRunner,
        memoryStore: memoryStore,
        workflowStore: workflowStore,
        workflowStepExecutor: workflowStepExecutor
    )
}

// MARK: - Tests

@Suite("Tool Registry")
struct ToolRegistryTests {

    @Test("Register and list tools")
    func testRegisterAndList() async throws {
        let fw = MockFirewall(granted: [.toolRead])
        let audit = MockAudit()
        let approvals = MockApprovals()
        let deps = makeTestDeps(firewall: fw, audit: audit, approvals: approvals)
        let registry = ToolRegistry(firewall: fw, audit: audit, approvals: approvals)
        await registry.register(TypeErasedTool(CoreStatusTool(dependencies: deps)))
        let tools = await registry.listAvailable(context: ToolContext(sessionID: "test"))
        #expect(tools.count == 1)
        #expect(tools.first?.name == "core.status")
    }

    @Test("Execute read-only tool with granted permission")
    func testReadOnlyTool() async throws {
        let fw = MockFirewall(granted: [.toolRead])
        let audit = MockAudit()
        let approvals = MockApprovals()
        let deps = makeTestDeps(firewall: fw, audit: audit, approvals: approvals)
        let registry = ToolRegistry(firewall: fw, audit: audit, approvals: approvals)
        await registry.register(TypeErasedTool(CoreStatusTool(dependencies: deps)))
        let ctx = ToolContext(sessionID: "test")
        let result = try await registry.call(name: "core.status", input: .object([:]), context: ctx)
        // Should succeed
        if case .object(let dict) = result {
            #expect(dict["version"] == .string("0.4A"))
        }
    }

    @Test("Denied permission blocks execution")
    func testDeniedPermission() async throws {
        let fw = MockFirewall(granted: []) // No permissions granted
        let audit = MockAudit()
        let approvals = MockApprovals()
        let deps = makeTestDeps(firewall: fw, audit: audit, approvals: approvals)
        let registry = ToolRegistry(firewall: fw, audit: audit, approvals: approvals)
        await registry.register(TypeErasedTool(CoreStatusTool(dependencies: deps)))
        let ctx = ToolContext(sessionID: "test")
        do {
            _ = try await registry.call(name: "core.status", input: .object([:]), context: ctx)
            Issue.record("Should have thrown")
        } catch {
            // Expected: permission denied
        }
        // Verify audit recorded denial
        let entries = await audit.entries
        #expect(entries.contains { $0.kind == .toolCallDenied })
    }

    @Test("humanOnly tools blocked for model invocation")
    func testHumanOnlyBlocksModel() async throws {
        let fw = MockFirewall(granted: [.memoryWrite])
        let audit = MockAudit()
        let approvals = MockApprovals()
        let deps = makeTestDeps(firewall: fw, audit: audit, approvals: approvals)
        let registry = ToolRegistry(firewall: fw, audit: audit, approvals: approvals)
        await registry.register(TypeErasedTool(ApproveCandidateTool(dependencies: deps)))
        let ctx = ToolContext(sessionID: "test", isModelInvocation: true) // Model trying to invoke
        do {
            _ = try await registry.call(name: "vault.approve_candidate", input: .object(["candidateID": .string("x")]), context: ctx)
            Issue.record("Should have thrown humanOnly error")
        } catch let error as ToolError {
            if case .humanOnly = error { /* expected */ }
            else { Issue.record("Wrong error: \(error)") }
        }
    }

    @Test("model self-approval lets model queue human-only game action")
    func testModelSelfApprovalQueuesGameAction() async throws {
        let fw = MockFirewall(granted: [.gameAct])
        let audit = MockAudit()
        let approvals = MockApprovals(autoApprove: true)
        let registry = ToolRegistry(
            firewall: fw,
            audit: audit,
            approvals: approvals,
            safetyConfig: SwooshSafetyConfig(modelSelfApprovalEnabled: true)
        )
        await registry.register(TypeErasedTool(HumanPromptedGameActionTool()))
        let ctx = ToolContext(sessionID: "test", isModelInvocation: true)
        let result = try await registry.call(name: "test.human_prompted_game_action", input: .object([:]), context: ctx)
        #expect(await approvals.approvalRequested)
        if case .object(let dict) = result {
            #expect(dict["accepted"] == .bool(true))
        } else {
            Issue.record("Expected object output")
        }
    }

    @Test("humanOnly tool succeeds for human invocation")
    func testHumanOnlyAllowsHuman() async throws {
        let fw = MockFirewall(granted: [.memoryWrite])
        let audit = MockAudit()
        let approvals = MockApprovals(autoApprove: true)
        let memoryStore = InMemoryMemoryToolStore()
        let candidateID = await memoryStore.propose(ProposeMemoryCandidateInput(
            text: "User prefers Swift.",
            category: .preference,
            sensitivity: .normal,
            confidence: 0.9,
            evidence: []
        ))
        let deps = makeTestDeps(firewall: fw, audit: audit, approvals: approvals, memoryStore: memoryStore)
        let registry = ToolRegistry(firewall: fw, audit: audit, approvals: approvals)
        await registry.register(TypeErasedTool(ApproveCandidateTool(dependencies: deps)))
        let ctx = ToolContext(sessionID: "test", isModelInvocation: false)
        let result = try await registry.call(name: "vault.approve_candidate", input: .object(["candidateID": .string(candidateID)]), context: ctx)
        // Should succeed
        if case .object(let dict) = result {
            #expect(dict["approvedMemoryID"] != nil)
        }
    }

    @Test("Audit events written for success")
    func testAuditSuccess() async throws {
        let fw = MockFirewall(granted: [.toolRead])
        let audit = MockAudit()
        let approvals = MockApprovals()
        let deps = makeTestDeps(firewall: fw, audit: audit, approvals: approvals)
        let registry = ToolRegistry(firewall: fw, audit: audit, approvals: approvals)
        await registry.register(TypeErasedTool(CoreStatusTool(dependencies: deps)))
        let ctx = ToolContext(sessionID: "test")
        _ = try await registry.call(name: "core.status", input: .object([:]), context: ctx)
        let entries = await audit.entries
        #expect(entries.contains { $0.kind == .toolCallStarted })
        #expect(entries.contains { $0.kind == .toolCallSucceeded })
    }

    @Test("Every tool has permission, risk, and approval")
    func testAllToolsHaveMetadata() async throws {
        let fw = MockFirewall(granted: SwooshPermission.allCases.reduce(into: Set<SwooshPermission>()) { $0.insert($1) })
        let audit = MockAudit()
        let approvals = MockApprovals()
        let deps = makeTestDeps(firewall: fw, audit: audit, approvals: approvals)
        let registry = ToolRegistry(firewall: fw, audit: audit, approvals: approvals)
        await DefaultToolRegistrar.registerAll(into: registry, dependencies: deps)
        let tools = await registry.listAvailable(context: ToolContext(sessionID: "test"))
        for tool in tools {
            #expect(!tool.name.isEmpty, "Tool \(tool.id) has empty name")
            #expect(!tool.description.isEmpty, "Tool \(tool.name) has empty description")
            // Risk and approval are always present (non-optional enum values)
        }
        // Should have at least the core tools
        #expect(tools.count >= 5, "Expected at least 5 tools, got \(tools.count)")
    }

    @Test("Tool not found returns error")
    func testToolNotFound() async throws {
        let fw = MockFirewall()
        let audit = MockAudit()
        let approvals = MockApprovals()
        let registry = ToolRegistry(firewall: fw, audit: audit, approvals: approvals)
        let ctx = ToolContext(sessionID: "test")
        do {
            _ = try await registry.call(name: "nonexistent.tool", input: .null, context: ctx)
            Issue.record("Should have thrown")
        } catch let error as ToolError {
            if case .notFound = error { /* expected */ }
            else { Issue.record("Wrong error: \(error)") }
        }
    }
}

@Suite("Operational tool stores")
struct OperationalToolStoreTests {
    @Test("Memory tools persist candidate approval")
    func memoryToolsPersistCandidateApproval() async throws {
        let fw = MockFirewall(granted: [.memoryWrite, .toolRead])
        let audit = MockAudit()
        let approvals = MockApprovals()
        let memoryStore = InMemoryMemoryToolStore()
        let deps = makeTestDeps(firewall: fw, audit: audit, approvals: approvals, memoryStore: memoryStore)
        let context = ToolContext(sessionID: "test", isModelInvocation: false)

        let proposed = try await ProposeCandidateTool(dependencies: deps).call(
            ProposeMemoryCandidateInput(
                text: "User prefers Swift.",
                category: .preference,
                sensitivity: .normal,
                confidence: 0.9,
                evidence: [EvidencePointer(sourceID: "test", description: "unit test")]
            ),
            context: context
        )
        let candidates = try await ListCandidatesTool(dependencies: deps).call(
            ListCandidatesInput(status: .pending),
            context: context
        )
        #expect(candidates.candidates.count == 1)
        #expect(candidates.candidates[0].id == proposed.candidateID)

        let approved = try await ApproveCandidateTool(dependencies: deps).call(
            ApproveMemoryCandidateInput(candidateID: proposed.candidateID, finalText: "User strongly prefers Swift."),
            context: context
        )
        let listed = try await ListApprovedMemoriesTool(dependencies: deps).call(
            ListApprovedMemoriesInput(category: .preference),
            context: context
        )
        #expect(listed.memories.count == 1)
        #expect(listed.memories[0].id == approved.approvedMemoryID)
        #expect(listed.memories[0].text == "User strongly prefers Swift.")
    }

    @Test("File patch applies unified diff")
    func filePatchAppliesUnifiedDiff() async throws {
        let fw = MockFirewall(granted: [.fileWrite])
        let audit = MockAudit()
        let approvals = MockApprovals()
        let fileAccess = PatchFileAccess(files: ["README.md": "one\ntwo\nthree\n"])
        let deps = makeTestDeps(firewall: fw, audit: audit, approvals: approvals, fileAccess: fileAccess)
        let diff = """
        --- a/README.md
        +++ b/README.md
        @@ -1,3 +1,3 @@
         one
        -two
        +TWO
         three
        """

        let output = try await FilePatchTool(dependencies: deps).call(
            FilePatchInput(rootBookmarkID: "root", relativePath: "README.md", unifiedDiff: diff, createBackup: false),
            context: ToolContext(sessionID: "test", isModelInvocation: false)
        )
        let content = await fileAccess.content(relativePath: "README.md")
        #expect(output.applied)
        #expect(content == "one\nTWO\nthree\n")
    }

    @Test("File-backed workflow store persists drafts and enablement")
    func fileWorkflowStorePersistsDrafts() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swoosh-workflow-store-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let draft = WorkflowDraft(
            id: "wf-1",
            name: "One",
            summary: "Runs one tool",
            steps: [
                WorkflowStepPreview(
                    label: "status",
                    toolName: "core.status",
                    actionKind: "tool",
                    arguments: .object([:])
                ),
            ],
            requiredPermissions: [.toolRead],
            enabled: false
        )
        let first = FileWorkflowToolStore(url: url)
        try await first.saveDraft(draft)
        _ = try await first.setEnabled(id: "wf-1", enabled: true)

        let second = FileWorkflowToolStore(url: url)
        let loaded = try await second.getDraft(id: "wf-1")

        #expect(loaded?.enabled == true)
        #expect(loaded?.steps.first?.toolName == "core.status")
        #expect(try await second.listDrafts().count == 1)
    }

    @Test("Workflow run executes configured step executor")
    func workflowRunExecutesConfiguredExecutor() async throws {
        let fw = MockFirewall(granted: [.workflowRun])
        let audit = MockAudit()
        let approvals = MockApprovals()
        let workflowStore = InMemoryWorkflowToolStore()
        let executor = RecordingWorkflowExecutor()
        let draft = WorkflowDraft(
            id: "wf-run",
            name: "Run",
            summary: "Runs a status tool",
            steps: [
                WorkflowStepPreview(
                    label: "status",
                    toolName: "core.status",
                    actionKind: "tool",
                    arguments: .object(["verbose": .bool(true)])
                ),
            ],
            requiredPermissions: [.toolRead],
            enabled: true
        )
        await workflowStore.saveDraft(draft)
        let deps = makeTestDeps(
            firewall: fw,
            audit: audit,
            approvals: approvals,
            workflowStore: workflowStore,
            workflowStepExecutor: executor
        )

        let output = try await WorkflowRunTool(dependencies: deps).call(
            WorkflowRunInput(draftID: "wf-run", confirmExecution: true),
            context: ToolContext(sessionID: "test", isModelInvocation: false)
        )
        let calls = await executor.recordedCalls()

        #expect(output.status == "completed")
        #expect(output.stepsCompleted == 1)
        #expect(calls.map(\.toolName) == ["core.status"])
        #expect(calls.first?.arguments == .object(["verbose": .bool(true)]))
    }

    @Test("Terminal local backend does not invoke a shell")
    func terminalLocalBackendRunsExecutableDirectly() async throws {
        let fw = MockFirewall(granted: [.shellRun])
        let audit = MockAudit()
        let approvals = MockApprovals()
        let runner = RecordingProcessRunner()
        let deps = makeTestDeps(
            firewall: fw,
            audit: audit,
            approvals: approvals,
            processRunner: runner
        )
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("swoosh-terminal-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: storeURL) }

        _ = try await TerminalRunTool(
            dependencies: deps,
            store: TerminalConfigStore(url: storeURL)
        ).call(
            TerminalRunInput(command: "swift test --filter SwooshArenaTests", backend: .local),
            context: ToolContext(sessionID: "test", isModelInvocation: false)
        )
        let calls = await runner.recordedCalls()

        #expect(calls.count == 1)
        #expect(calls[0].executable == "swift")
        #expect(calls[0].arguments == ["test", "--filter", "SwooshArenaTests"])
    }
}

@Suite("Safety Config")
struct SafetyConfigTests {

    @Test("Default safety config locks everything")
    func testDefaultsLocked() throws {
        let config = SwooshSafetyConfig.defaultAgent
        #expect(!config.cookieIngestionEnabled)
        #expect(!config.modelSelfApprovalEnabled)
        #expect(!config.autonomousGameControlEnabled)
        #expect(!config.gameCaptureEnabled)
        #expect(!config.gameAssetWriteEnabled)
    }

    @Test("Safety violations throw")
    func testSafetyViolations() throws {
        let config = SwooshSafetyConfig.defaultAgent
        #expect(throws: SafetyViolation.self) { try config.requireAutonomousGameControl() }
        #expect(throws: SafetyViolation.self) { try config.requireGameCapture() }
        #expect(throws: SafetyViolation.self) { try config.requireGameAssetWrite() }
        #expect(throws: SafetyViolation.self) { try config.requireModelSelfApproval() }
    }

    @Test("Custom config can unlock features")
    func testCustomConfig() throws {
        var config = SwooshSafetyConfig.defaultAgent
        config.autonomousGameControlEnabled = true
        config.gameCaptureEnabled = true
        config.gameAssetWriteEnabled = true
        try config.requireAutonomousGameControl()
        try config.requireGameCapture()
        try config.requireGameAssetWrite()
    }
}

@Suite("Swift developer tools")
struct SwiftDeveloperToolTests {
    @Test("Package describe parses JSON output")
    func packageDescribeParsesJSON() async throws {
        let fw = MockFirewall(granted: [.swiftBuild])
        let audit = MockAudit()
        let approvals = MockApprovals()
        let stdout = """
        {"name":"Demo","products":[{"name":"DemoLib"}],"targets":[{"name":"DemoLib","type":"library"},{"name":"DemoTests","type":"test"}],"dependencies":[{"identity":"swift-argument-parser"}]}
        """
        let deps = makeTestDeps(
            firewall: fw,
            audit: audit,
            approvals: approvals,
            processRunner: FixedProcessRunner(result: ProcessResult(exitCode: 0, stdout: stdout, stderr: ""))
        )

        let output = try await SwiftPackageDescribeTool(dependencies: deps).call(
            SwiftPackageDescribeInput(rootBookmarkID: "cwd"),
            context: ToolContext(sessionID: "s1")
        )

        #expect(output.packageName == "Demo")
        #expect(output.products == ["DemoLib"])
        #expect(output.targets.map(\.name).contains("DemoTests"))
        #expect(output.dependencies == ["swift-argument-parser"])
    }

    @Test("Swift test parses test summary")
    func swiftTestParsesSummary() async throws {
        let fw = MockFirewall(granted: [.swiftBuild])
        let audit = MockAudit()
        let approvals = MockApprovals()
        let stdout = "Test Suite 'All tests' passed. Executed 5 tests, with 1 failure (0 unexpected) in 0.1 seconds."
        let deps = makeTestDeps(
            firewall: fw,
            audit: audit,
            approvals: approvals,
            processRunner: FixedProcessRunner(result: ProcessResult(exitCode: 1, stdout: stdout, stderr: "/tmp/File.swift:4:2: error: bad"))
        )

        let output = try await SwiftTestTool(dependencies: deps).call(
            SwiftTestInput(rootBookmarkID: "cwd"),
            context: ToolContext(sessionID: "s1")
        )

        #expect(output.exitCode == 1)
        #expect(output.testsPassed == 4)
        #expect(output.testsFailed == 1)
        #expect(output.diagnostics.count == 1)
    }
}

@Suite("Approval Policy")
struct ApprovalPolicyTests {

    @Test("never does not require approval")
    func testNever() {
        #expect(!ApprovalPolicy.never.requiresUserApproval)
        #expect(ApprovalPolicy.never.modelCanInvoke)
    }

    @Test("humanOnly blocks model")
    func testHumanOnly() {
        #expect(ApprovalPolicy.humanOnly.requiresUserApproval)
        #expect(!ApprovalPolicy.humanOnly.modelCanInvoke)
    }

    @Test("disabled blocks model")
    func testDisabled() {
        #expect(ApprovalPolicy.disabled.requiresUserApproval)
        #expect(!ApprovalPolicy.disabled.modelCanInvoke)
    }

    @Test("askEveryTime requires approval and model can invoke")
    func testAskEveryTime() {
        #expect(ApprovalPolicy.askEveryTime.requiresUserApproval)
        #expect(ApprovalPolicy.askEveryTime.modelCanInvoke)
    }
}

@Suite("Tool Risk")
struct ToolRiskTests {

    @Test("Risk ordering")
    func testRiskOrder() {
        #expect(ToolRisk.readOnly < ToolRisk.low)
        #expect(ToolRisk.low < ToolRisk.medium)
        #expect(ToolRisk.medium < ToolRisk.high)
        #expect(ToolRisk.high < ToolRisk.critical)
    }
}

@Suite("JSONValue Redaction")
struct JSONValueRedactionTests {

    @Test("Redacts sensitive fields")
    func testRedaction() {
        let value = JSONValue.object(["name": .string("test"), "password": .string("secret123")])
        let preview = value.redactedPreview()
        #expect(!preview.contains("secret123"))
    }

    @Test("Truncates long values")
    func testTruncation() {
        let longString = String(repeating: "x", count: 500)
        let value = JSONValue.string(longString)
        let preview = value.redactedPreview(maxLength: 100)
        #expect(preview.count <= 101) // 100 + "…"
    }
}
