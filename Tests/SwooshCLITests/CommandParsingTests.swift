// Tests/SwooshCLITests/CommandParsingTests.swift — Argument-parser checks — 0.4A
//
// These tests reach the real command types via `@testable import
// SwooshCLI` (possible because SwooshCLI is now a library target — see
// the audit follow-up). They are the only thing that guarantees a typo
// in an `@Option`/`@Flag` name will fail CI rather than ship silently.

import Testing
import Foundation
import ArgumentParser
import SwooshArena
@testable import SwooshCLI

@Suite("Argument parsing — root")
struct RootParsingTests {
    @Test("swoosh root command parses with no args (defaults to chat)")
    func rootDefaultsToChat() throws {
        let command = try SwooshCommand.parseAsRoot([])
        #expect(command is ChatCommand)
    }

    @Test("swoosh chat parses with no flags (no --continue today)")
    func chatBareCommand() throws {
        let command = try SwooshCommand.parseAsRoot(["chat"])
        #expect(command is ChatCommand)
    }

    @Test("swoosh chat --continue is rejected — flag was unimplemented and removed")
    func chatContinueFlagRemoved() throws {
        #expect(throws: (any Error).self) {
            _ = try SwooshCommand.parseAsRoot(["chat", "--continue"])
        }
    }

    @Test("swoosh ask <question> parses")
    func askPositional() throws {
        let command = try SwooshCommand.parseAsRoot(["ask", "what time is it"])
        let ask = try #require(command as? AskCommand)
        #expect(ask.question == "what time is it")
        #expect(ask.session == "default")
    }

    @Test("swoosh doctor --fix --json --config-dir parses")
    func doctorFullOptions() throws {
        let command = try SwooshCommand.parseAsRoot([
            "doctor", "--fix", "--json", "--config-dir", "/tmp/foo",
        ])
        let doctor = try #require(command as? DoctorCommand)
        #expect(doctor.scaffold == true)
        #expect(doctor.json == true)
        #expect(doctor.configDirectory == "/tmp/foo")
    }
}

@Suite("Argument parsing — setup")
struct SetupParsingTests {
    @Test("swoosh setup parses with no subcommand and defaults to quick")
    func setupDefaultsToQuick() throws {
        let command = try SwooshCommand.parseAsRoot(["setup"])
        #expect(command is SetupQuickCommand)
    }

    @Test("swoosh setup quick parses --non-interactive and presets")
    func quickNonInteractive() throws {
        let command = try SwooshCommand.parseAsRoot([
            "setup", "quick",
            "--non-interactive",
            "--model-path", "hybrid",
            "--permission-profile", "developer",
            "--daemon-port", "9090",
        ])
        let quick = try #require(command as? SetupQuickCommand)
        #expect(quick.nonInteractive == true)
        #expect(quick.requestedModelPath == .hybrid)
        #expect(quick.requestedPermissionProfile?.rawValue == "developer")
        #expect(quick.daemonPort == 9090)
    }

    @Test("swoosh setup full parses --config-dir")
    func fullConfigDir() throws {
        let command = try SwooshCommand.parseAsRoot([
            "setup", "full", "--config-dir", "/tmp/swoosh",
        ])
        let full = try #require(command as? SetupFullCommand)
        #expect(full.configDirectory == "/tmp/swoosh")
    }

    @Test("swoosh setup developer parses")
    func developerParses() throws {
        let command = try SwooshCommand.parseAsRoot(["setup", "developer"])
        #expect(command is SetupDeveloperCommand)
    }

    @Test("swoosh setup server parses")
    func serverParses() throws {
        let command = try SwooshCommand.parseAsRoot(["setup", "server"])
        #expect(command is SetupServerCommand)
    }

    @Test("Removed placeholder setup subcommands no longer parse")
    func placeholderSubcommandsRejected() throws {
        for removed in ["model", "permissions", "memory", "gateway", "tools", "terminal", "local-model", "import-hermes"] {
            // `swoosh setup <removed>` should fail because the subcommand
            // is gone. We accept either a parse failure or a successful
            // re-parse as a *different* command type (e.g. "model" might
            // route to the root `ModelCommand`), but never to a stale
            // setup-stub instance.
            if let parsed = try? SwooshCommand.parseAsRoot(["setup", removed]) {
                #expect(!String(describing: type(of: parsed)).contains("Setup\(removed.capitalized)Command"))
            }
        }
    }
}

@Suite("Argument parsing — removed non-game commands")
struct RemovedNonGameCommandParsingTests {
    @Test("non-game top-level commands are rejected")
    func removedCommandsRejected() throws {
        for removed in ["memory", "skills", "cron", "chat-adapters", "goal", "manifest"] {
            #expect(throws: (any Error).self) {
                _ = try SwooshCommand.parseAsRoot([removed])
            }
        }
    }

    @Test("swoosh permissions --status parses")
    func permissionsStatus() throws {
        let command = try SwooshCommand.parseAsRoot(["permissions", "--status"])
        let perms = try #require(command as? PermissionsCommand)
        #expect(perms.status == true)
    }
}

@Suite("Argument parsing — providers / terminal")
struct ProviderParsingTests {
    @Test("swoosh provider list parses")
    func providerList() throws {
        let command = try SwooshCommand.parseAsRoot(["provider", "list"])
        #expect(command is ProviderListCommand)
    }

    @Test("swoosh provider auth openai --api-key parses")
    func providerAuth() throws {
        let command = try SwooshCommand.parseAsRoot([
            "provider", "auth", "openai", "--api-key", "sk-test",
        ])
        let auth = try #require(command as? ProviderAuthCommand)
        #expect(auth.provider == "openai")
        #expect(auth.apiKey == "sk-test")
        #expect(auth.pkce == false)
    }

    @Test("swoosh provider auth openrouter --pkce parses")
    func providerAuthPKCE() throws {
        let command = try SwooshCommand.parseAsRoot([
            "provider", "auth", "openrouter", "--pkce",
        ])
        let auth = try #require(command as? ProviderAuthCommand)
        #expect(auth.pkce == true)
    }

    @Test("swoosh provider test [name] parses")
    func providerTest() throws {
        let any = try SwooshCommand.parseAsRoot(["provider", "test"])
        #expect(any is ProviderTestCommand)
        let one = try SwooshCommand.parseAsRoot(["provider", "test", "openai"])
        let cmd = try #require(one as? ProviderTestCommand)
        #expect(cmd.provider == "openai")
    }

    @Test("swoosh provider discover parses")
    func providerDiscover() throws {
        let command = try SwooshCommand.parseAsRoot(["provider", "discover"])
        #expect(command is ProviderDiscoverCommand)
    }

    @Test("swoosh provider select <id> parses the active-provider id")
    func providerSelect() throws {
        let command = try SwooshCommand.parseAsRoot(["provider", "select", "dev-proxy"])
        let select = try #require(command as? ProviderSelectCommand)
        #expect(select.provider == "dev-proxy")
    }

    @Test("swoosh provider select with no id is rejected (required arg)")
    func providerSelectRequiresID() throws {
        #expect(throws: (any Error).self) {
            _ = try SwooshCommand.parseAsRoot(["provider", "select"])
        }
    }

    @Test("swoosh game cli list parses laptop starter filters")
    func gameCLIListParses() throws {
        let command = try SwooshCommand.parseAsRoot([
            "game", "cli", "list", "--kind", "laptop", "--input", "voicePrompt", "--json",
        ])
        let list = try #require(command as? GameCLIListCommand)
        #expect(list.kind == .laptop)
        #expect(list.input == .voicePrompt)
        #expect(list.json)
    }

    @Test("swoosh game catalog parses section filters")
    func gameCatalogParses() throws {
        let command = try SwooshCommand.parseAsRoot([
            "game", "catalog", "--section", "threeD", "--json",
        ])
        let catalog = try #require(command as? GameCatalogCommand)
        #expect(catalog.section == .threeD)
        #expect(catalog.json)
    }

    @Test("swoosh game cli init parses laptop starter")
    func gameCLIInitParses() throws {
        let command = try SwooshCommand.parseAsRoot([
            "game", "cli", "init",
            "--starter", "cartridge-laptop-cli",
            "--title", "Laptop Driver",
            "--name", "driver",
            "--output", "/tmp/driver",
            "--json",
        ])
        let initCommand = try #require(command as? GameCLIInitCommand)
        #expect(initCommand.starter == "cartridge-laptop-cli")
        #expect(initCommand.title == "Laptop Driver")
        #expect(initCommand.name == "driver")
        #expect(initCommand.output == "/tmp/driver")
        #expect(initCommand.json)
    }

    @Test("swoosh terminal backends parses")
    func terminalBackends() throws {
        let command = try SwooshCommand.parseAsRoot(["terminal", "backends"])
        #expect(command is TerminalBackendsCommand)
    }

    @Test("swoosh terminal configure docker parses with image")
    func terminalConfigure() throws {
        let command = try SwooshCommand.parseAsRoot([
            "terminal", "configure", "docker", "--docker-image", "swift:6.0",
        ])
        let cfg = try #require(command as? TerminalConfigureCommand)
        #expect(cfg.backend.rawValue == "docker")
        #expect(cfg.dockerImage == "swift:6.0")
    }
}

@Suite("Argument parsing — plugin / daemon / completions / self-test")
struct ExtraParsingTests {
    @Test("swoosh plugin list parses with daemon options")
    func pluginList() throws {
        let command = try SwooshCommand.parseAsRoot([
            "plugin", "list", "--host", "10.0.0.1", "--port", "9100",
        ])
        let list = try #require(command as? PluginListCommand)
        #expect(list.daemon.host == "10.0.0.1")
        #expect(list.daemon.port == 9100)
    }

    @Test("swoosh plugin install <path> --enable parses")
    func pluginInstall() throws {
        let command = try SwooshCommand.parseAsRoot([
            "plugin", "install", "/tmp/myplug", "--enable",
        ])
        let install = try #require(command as? PluginInstallCommand)
        #expect(install.path == "/tmp/myplug")
        #expect(install.enable == true)
    }

    @Test("swoosh daemon pair --port 9090 parses")
    func daemonPair() throws {
        let command = try SwooshCommand.parseAsRoot([
            "daemon", "pair", "--port", "9090",
        ])
        let pair = try #require(command as? DaemonPairCommand)
        #expect(pair.port == 9090)
        #expect(pair.host == nil)
    }

    @Test("swoosh completions <shell> --install parses")
    func completions() throws {
        let command = try SwooshCommand.parseAsRoot(["completions", "bash", "--install"])
        let c = try #require(command as? CompletionsCommand)
        #expect(c.shell == "bash")
        #expect(c.install == true)
    }

    @Test("swoosh self-test parses")
    func selfTest() throws {
        let command = try SwooshCommand.parseAsRoot(["self-test"])
        #expect(command is SelfTestCommand)
    }

    @Test("swoosh model --test parses")
    func modelTest() throws {
        let command = try SwooshCommand.parseAsRoot(["model", "--test"])
        let m = try #require(command as? ModelCommand)
        #expect(m.test == true)
    }
}
