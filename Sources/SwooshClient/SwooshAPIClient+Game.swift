// SwooshClient/SwooshAPIClient+Game.swift — 0.1A Cartridge creation catalog endpoint

import Foundation

extension SwooshAPIClient {
    public func gameCreationCatalog() async throws -> GameCreationCatalogResponse {
        let request = try makeRequest(method: "GET", path: "api/game/creation-catalog", body: nil)
        return try await execute(request, as: GameCreationCatalogResponse.self)
    }
}
