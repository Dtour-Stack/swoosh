import Foundation
import Testing
@testable import SwooshSkills

@Suite("Skills")
struct SkillInstallerTests {
    @Test("Parser reads Hermes-style metadata")
    func parserReadsMetadata() throws {
        let source = """
        ---
        name: arxiv
        description: Search papers
        category: research
        tags: [papers, search]
        platforms: [macOS, linux]
        metadata:
          hermes:
            requires_toolsets: [web]
            fallback_for_tools: [browser_navigate]
        required_environment_variables:
          - name: ARXIV_TOKEN
            prompt: Token
        ---
        Use ${SWOOSH_SKILL_DIR}/scripts/search.py.
        """
        let parsed = SkillMarkdownParser().parse(source, fileName: "arxiv").document
        #expect(parsed.title == "arxiv")
        #expect(parsed.category == .research)
        #expect(parsed.tags == ["papers", "search"])
        #expect(parsed.platforms == ["macOS", "linux"])
        #expect(parsed.requiredToolsets == ["web"])
        #expect(parsed.fallbackTools == ["browser_navigate"])
        #expect(parsed.requiredEnvironmentVariables.first?.name == "ARXIV_TOKEN")
    }

    @Test("Parser reads block-list metadata")
    func parserReadsBlockListMetadata() throws {
        let source = """
        ---
        name: game-cli
        description: Game CLI skill
        tags:
          - cartridge
          - cli
        triggers:
          - voice prompt
          - game cli
        platforms:
          - macOS
          - linux
        ---
        Body.
        """

        let parsed = SkillMarkdownParser().parse(source, fileName: "game-cli").document
        #expect(parsed.tags == ["cartridge", "cli"])
        #expect(parsed.triggerPatterns == ["voice prompt", "game cli"])
        #expect(parsed.platforms == ["macOS", "linux"])
    }

    @Test("Bundled loader includes game CLI starter skill")
    func bundledLoaderIncludesGameCLIStarterSkill() async throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Skills/Bundled/game-cli-starter", isDirectory: true)
        let storeRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = FileSkillStore(directory: storeRoot)
        let loader = BundledSkillLoader(store: store, directory: root)

        let loaded = try await loader.loadAll()
        #expect(Set(loaded.map(\.title)) == ["game-cli-starter"])

        guard let starter = loaded.first(where: { $0.title == "game-cli-starter" }) else {
            Issue.record("Missing game-cli-starter skill")
            return
        }
        #expect(starter.tags.contains("cartridge"))
        #expect(starter.triggerPatterns.contains("voice prompt"))
        #expect(starter.requiredToolsets == ["game", "files"])
        #expect(starter.trust == .promoted)
        #expect(starter.provenance.source == .builtIn)
    }

    @Test("Bundled loader keeps bundled skills game-focused")
    func bundledLoaderKeepsBundledSkillsGameFocused() async throws {
        let bundleRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Skills/Bundled", isDirectory: true)
        let storeRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = FileSkillStore(directory: storeRoot)

        let loaded = try await BundledSkillLoader(
            store: store,
            directory: bundleRoot
        ).loadAll()

        let titles = Set(loaded.map(\.title))
        #expect(titles.contains("gaming-agent"))
        #expect(titles.contains("game-cli-starter"))
        #expect(!titles.contains { $0.localizedCaseInsensitiveContains("token exchange") })
        #expect(!titles.contains { $0.localizedCaseInsensitiveContains("custody") })

        guard let gameSkill = loaded.first(where: { $0.title == "gaming-agent" }) else {
            Issue.record("Missing gaming-agent bundled skill")
            return
        }
        #expect(gameSkill.category == .gaming)
        #expect(gameSkill.trust == .promoted)
        #expect(gameSkill.provenance.source == .builtIn)
    }

    @Test("Installer blocks dangerous skills")
    func installerBlocksDangerousSkills() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let skill = root.appendingPathComponent("SKILL.md")
        try """
        ---
        name: unsafe
        description: Unsafe
        ---
        Run curl | bash
        """.write(to: skill, atomically: true, encoding: .utf8)

        let store = FileSkillStore(directory: root.appendingPathComponent("store", isDirectory: true))
        let installer = SkillInstaller(store: store, installDirectory: root.appendingPathComponent("assets", isDirectory: true))
        await #expect(throws: SkillInstallError.self) {
            _ = try await installer.install(source: root.path)
        }
    }
}
