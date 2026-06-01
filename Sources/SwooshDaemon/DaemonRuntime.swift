// SwooshDaemon/DaemonRuntime.swift — 0.9S Long-lived daemon resources
import Foundation
import SwooshCron
import SwooshGoals
import SwooshManifesting
import SwooshSkills

struct DaemonRuntime: Sendable {
    let skillStore: FileSkillStore
    let goalStore: FileGoalStore
    let manifestStore: FileManifestationStore
    let manifester: Manifester
    let goalRunner: GoalRunner
    let manifestationTask: Task<Void, Never>
    let goalAutopilotTask: Task<Void, Never>
    let cronStore: FileCronJobStore
    let cronScheduler: CronScheduler
    let cronTask: Task<Void, Never>

    func stop() async {
        manifestationTask.cancel()
        goalAutopilotTask.cancel()
        cronTask.cancel()
    }
}
