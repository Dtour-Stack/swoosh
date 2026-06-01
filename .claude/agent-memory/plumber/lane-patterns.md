---
name: lane-patterns
description: Canonical wiring patterns in Swoosh for daemon modules: bridge files, runtime-sources closure, SwooshClient extensions, SwooshUI RPC-only reads
metadata:
  type: project
---

## Canonical lane pattern for a new feature module (e.g., SwooshCalendar)

Every new feature module that exposes agent tools + an API endpoint + a UI panel follows this file layout:

### New module (SwooshCalendar)
- `Sources/SwooshCalendar/CalendarEvent.swift` — domain model (Codable, Sendable, actor)
- `Sources/SwooshCalendar/CalendarStore.swift` — `CalendarStoring` protocol + `FileCalendarStore` actor
- `Sources/SwooshCalendar/CalendarTools.swift` — `SwooshTool` conformances + `CalendarToolDependencies`

### Package.swift
- `.target(name: "SwooshCalendar", dependencies: ["SwooshTools"])` — matches SwooshCron/SwooshGoals exactly
- SwooshToolsets += SwooshCalendar
- SwooshDaemon += SwooshCalendar

### Daemon bridge (NOT Daemon.swift)
- NEW `Sources/SwooshDaemon/CalendarAPIBridge.swift` — `extension SwooshDaemon` containing domain→wire mapping functions
- Pattern matches: GoalsAPIBridge.swift, CronAPIBridge.swift

### SwooshAPIRuntimeSources
- Add closure property `calendarEvents: @Sendable () async -> CalendarEventsResponse` with default `{ CalendarEventsResponse(events: []) }`
- SwooshAPI itself does NOT import SwooshCalendar — composition happens in the daemon via the closure

### SwooshClient
- NEW `Sources/SwooshClient/WireTypes+Calendar.swift` — wire types only (Codable, Sendable, zero deps)
- NEW `Sources/SwooshClient/SwooshAPIClient+Calendar.swift` — `extension SwooshAPIClient` GET method
- SwooshClient has ZERO deps on SwooshCalendar

### SwooshUI
- `CalendarTrayPanel.swift` — reads via `SwooshAPIClient.calendarEvents()` RPC only
- SwooshUI must NOT import SwooshCalendar

### SwooshToolsets/Exports.swift
- Add `calendar: CalendarToolDependencies?` to `SelfImprovementDependencies`
- Add `registerCalendar` hook + conditional call in `registerAll`

### Permissions
- Add `swooshCalendarRead` / `swooshCalendarWrite` to SwooshTools/SwooshPermission.swift
- Do NOT reuse `calendarRead`/`calendarWrite` (those gate Apple/Scout system calendar)
- Update Docs/PermissionModel.md

### ToolsetID
- Add `case calendar` to ToolsetID in SwooshTools/Tool.swift

### Wire-type naming convention
The repo uses `…RecordSummary` or `…Summary` for projected wire types.
Use `CalendarEventSummary` (not `CalendarEvent`) to match convention and avoid
collision with the domain type in daemon bridge files that import both.

## check-flow.sh additions for SwooshCalendar

Rule: SwooshUI imports no SwooshCalendar (grep guard)
Rule: SwooshCalendar added to IOS_FORBIDDEN list if iOS isolation is desired
Update .claude/topology.md with two lanes:
  - agent write: AgentToolLoop → ToolRegistry → firewall → CalendarTools → FileCalendarStore
  - UI read: CalendarTrayPanel → SwooshAPIClient → /api/calendar/events → runtime-sources closure → FileCalendarStore

**Why:** Validated during PRE-FLIGHT for the Swoosh Calendar feature (2026-05-28).
Pattern matches SwooshCron + SwooshGoals exactly.
**How to apply:** Use this as the reference when adding any future feature module with agent tools + API endpoint + UI surface.

## SwooshUI dashboard pane lane (Memory/Wallet/Safety pattern, 2026-05-29)

For new dashboard panes that read/write daemon state, the correct lane is:

```
DashboardView (tab case + sidebarRow) → SafetyPane / WalletPane / MemoriesPane
  → SwooshDaemonClient.client() → SwooshAPIClient (RPC)
  → SwooshAPI /api/* route → daemon domain store
```

### Import contract (POST-FLIGHT verified)
New pane files import ONLY: `SwiftUI`, `SwooshGenerativeUI`, `SwooshClient`, `Foundation`
Chain IDs, preset IDs, flag keys are LOCAL strings — never import SwooshWallet or SwooshConfig
MemoryApproval.swift (bounded-concurrency helper): `Foundation` + `SwooshClient` only (no SwiftUI)
ToastCenter.swift (shared @Observable queue + host modifier): `SwiftUI` + `SwooshGenerativeUI` only

### DashboardTab enum change protocol
When adding a case to `DashboardTab`:
1. Add the case + enum rawValue
2. Add `sidebarRow(...)` in DashboardView sidebar
3. Add `case .newTab: NewPane()` in the detail switch
4. Add `case .newTab, .settings:` in EditMenu.swift's switch (group with nearest neighbor)
5. The `.swooshNavigateTab` notification lane uses `DashboardTab(rawValue: raw)` — rawValue-based lookup, no switch needed there
6. No `default:` clause anywhere in the enum consumers — exhaustive switches are the pattern

### Daemon connected-flag semantics (WalletDashboardResponse)
`connected: !walletAccounts.isEmpty` (accounts-based, line 636 DaemonResponseBuilders.swift)
Capability entries' `configured`/`status` still key off `walletBridgeAvailable` in the same payload
Two readers only: `WalletPane.swift:29` and `WalletTrayPanel.swift:36` — both use `.connected` as "show wallet UI"
**NOTE:** `connected` no longer means "bridge ready" — do not add a third reader that treats it that way
