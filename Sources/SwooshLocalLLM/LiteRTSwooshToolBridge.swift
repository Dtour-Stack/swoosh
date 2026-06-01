#if os(iOS)

// SwooshLocalLLM/LiteRTSwooshToolBridge.swift — 0.9S local model dispatch hook
//
// The default package graph does not link a local model runtime. This
// hook remains the stable dispatch slot that a plugin runtime can use
// when it provides the concrete on-device inference engine.

import Foundation
import os

public final class SwooshDispatchTool {

    /// Sendable closure type for the host-side dispatch handler.
    public typealias DispatchHandler = @Sendable (String, String) async throws -> String

    /// Lock-protected slot for the dispatch handler. Written once at app
    /// start (e.g. `LocalToolDispatcher.install()`) and read by every
    /// `swoosh_dispatch` tool call from the local model. `OSAllocatedUnfairLock`
    /// replaces the previous `nonisolated(unsafe) static var` slot which
    /// tripped Swift 6 strict-concurrency checks. The lock pairs with
    /// `LocalToolDispatcher`'s identical slot for the inbound side.
    private static let dispatchSlot = OSAllocatedUnfairLock<DispatchHandler?>(initialState: nil)

    /// Set this at app start with a closure that routes (toolName, jsonArgs)
    /// through Swoosh's ToolRegistry. The closure must apply the same
    /// firewall + approval gates as the cloud path — humanOnly tools
    /// must NOT execute without a real user grant. Safe to read/write
    /// from any actor.
    public static var dispatch: DispatchHandler? {
        get { dispatchSlot.withLock { $0 } }
        set { dispatchSlot.withLock { $0 = newValue } }
    }
}

#endif
