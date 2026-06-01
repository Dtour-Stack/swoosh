// SwooshTools/RPCClients.swift — Runtime dependency protocols

import Foundation

// ═══════════════════════════════════════════════════════════════════
// MARK: - File access protocol
// ═══════════════════════════════════════════════════════════════════

/// Abstraction for sandboxed file access via approved bookmarks.
public protocol FileAccessing: Sendable {
    func resolveBookmark(id: String) async throws -> URL
    func listDirectory(root: URL, relativePath: String?, includeHidden: Bool, maxDepth: Int) async throws -> [FileEntry]
    func readFile(root: URL, relativePath: String, maxBytes: Int?) async throws -> (content: String, truncated: Bool, redaction: RedactionReport?)
    func writeFile(root: URL, relativePath: String, content: String, createBackup: Bool) async throws -> (bytesWritten: Int64, backupPath: String?)
    func deleteFile(root: URL, relativePath: String) async throws
    func searchFiles(root: URL, query: String, filePattern: String?, maxResults: Int?) async throws -> [FileSearchMatch]
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Process runner protocol
// ═══════════════════════════════════════════════════════════════════

/// Abstraction for running shell processes (git, swift, etc.).
public protocol ProcessRunning: Sendable {
    func run(executable: String, arguments: [String], workingDirectory: URL?, environment: [String: String]?) async throws -> ProcessResult
}

public struct ProcessResult: Codable, Sendable {
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String

    public init(exitCode: Int32, stdout: String, stderr: String) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Secret resolving (Keychain abstraction)
// ═══════════════════════════════════════════════════════════════════

/// Resolves secret references (e.g. Keychain labels) into their raw values.
/// Implementations live in SwooshSecrets; tools never store the value.
public protocol SecretResolving: Sendable {
    /// Resolve a named secret reference. Throws if not found or access denied.
    func resolve(ref: String) async throws -> String
}

public protocol WorkflowStepExecuting: Sendable {
    func executeWorkflowStep(
        toolName: String,
        arguments: JSONValue,
        context: ToolContext
    ) async throws -> ToolExecutionResult
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - Tool dependencies
// ═══════════════════════════════════════════════════════════════════

/// All dependencies needed by tool implementations. Injected at registration.
public struct ToolDependencies: Sendable {
    public let firewall: any Firewall
    public let audit: any AuditLogging
    public let approvals: any ApprovalRequesting
    public let safetyConfig: SwooshSafetyConfig
    public let fileAccess: any FileAccessing
    public let processRunner: any ProcessRunning
    public let memoryStore: any MemoryToolStoring
    public let workflowStore: any WorkflowToolStoring
    public let workflowStepExecutor: (any WorkflowStepExecuting)?
    /// Resolves Keychain secret refs for provider, plugin, and game integration credentials.
    public let secrets: any SecretResolving

    public init(
        firewall: any Firewall,
        audit: any AuditLogging,
        approvals: any ApprovalRequesting,
        safetyConfig: SwooshSafetyConfig = .defaultAgent,
        fileAccess: any FileAccessing,
        processRunner: any ProcessRunning,
        memoryStore: any MemoryToolStoring = InMemoryMemoryToolStore(),
        workflowStore: any WorkflowToolStoring = InMemoryWorkflowToolStore(),
        workflowStepExecutor: (any WorkflowStepExecuting)? = nil,
        secrets: any SecretResolving = NullSecretResolver()
    ) {
        self.firewall = firewall
        self.audit = audit
        self.approvals = approvals
        self.safetyConfig = safetyConfig
        self.fileAccess = fileAccess
        self.processRunner = processRunner
        self.memoryStore = memoryStore
        self.workflowStore = workflowStore
        self.workflowStepExecutor = workflowStepExecutor
        self.secrets = secrets
    }
}

/// Resolver used when no secret store is configured.
public struct NullSecretResolver: SecretResolving {
    public init() {}
    public func resolve(ref: String) async throws -> String {
        throw ToolError.executionFailed("No SecretResolver configured — cannot access secret '\(ref)'")
    }
}
