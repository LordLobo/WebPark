//
//  PublicAPISurfaceTests.swift
//
//
//  Guards the public API surface from outside the module.
//
//  Everything here must compile with a plain `import WebPark`. Do not add `@testable`:
//  that exposes internal symbols and would defeat the purpose of this target. The bug this
//  guards against shipped in 0.3.0 — `urlSession` had a non-public default witness, so the
//  README's own Quick Start snippet failed to compile for consumers while the main test
//  suite stayed green.
//

import Foundation
import Testing
import WebPark

// MARK: - Conformances a consumer is expected to be able to write

/// The minimal conformance, exactly as documented in README Quick Start.
/// Supplying only `baseURL` must be sufficient.
private struct MinimalClient: WebPark {
    let baseURL = "https://api.example.com"
}

/// A conformance that overrides the defaulted session.
private struct CustomSessionClient: WebPark {
    let baseURL = "https://api.example.com"
    let urlSession: URLSession
}

private struct StubTokenService: WebParkTokenServiceProtocol {
    var token: String { "stub-token" }
    func refreshToken() async throws {}
}

/// A conformance that supplies a token service.
private struct AuthenticatedClient: WebPark {
    let baseURL = "https://api.example.com"
    let tokenService: (any WebParkTokenServiceProtocol)?
}

@Suite("Public API Surface Tests")
struct PublicAPISurfaceTests {
    @Test("A conformance supplying only baseURL compiles and gets both defaults")
    func minimalConformance() async throws {
        let client = MinimalClient()

        #expect(client.baseURL == "https://api.example.com")
        #expect(client.urlSession === URLSession.shared, "urlSession should default to .shared")
        #expect(client.tokenService == nil, "tokenService should default to nil")
    }

    @Test("The urlSession default can be overridden")
    func overriddenSession() async throws {
        let session = URLSession(configuration: .ephemeral)
        let client = CustomSessionClient(urlSession: session)

        #expect(client.urlSession === session)
        #expect(client.tokenService == nil)
    }

    @Test("The tokenService default can be overridden")
    func overriddenTokenService() async throws {
        let client = AuthenticatedClient(tokenService: StubTokenService())

        let token = try #require(client.tokenService?.token)
        #expect(token == "stub-token")
        #expect(client.urlSession === URLSession.shared)
    }

    // MARK: - Public types reachable without @testable

    @Test("Error types are public and carry usable messages as any Error")
    func errorTypesArePublic() async throws {
        let httpError: any Error = WebParkHttpError(401)
        #expect(httpError.localizedDescription == "HTTP 401: Unauthorized")

        let parkError: any Error = WebParkError.unexpectedResponse
        #expect(parkError.localizedDescription == "The server did not return an HTTP response")

        #expect(WebParkHttpError(404).httpError == .notFound)
        #expect(ErrorResponseCode.tooManyRequests.rawValue == 429)
    }

    @Test("URLRequest helpers are public")
    func requestHelpersArePublic() async throws {
        let url = try #require(URL(string: "https://api.example.com"))
        let request = URLRequest(url: url)
            .addingBearerAuthorization(token: "abc")
            .sendingJSON()
            .acceptingJSON()

        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer abc")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("Coder is public")
    func coderIsPublic() async throws {
        struct Payload: Codable, Equatable {
            let name: String
        }

        let encoded = try Coder.encode(Payload(name: "Yuki"))
        let decoded: Payload = try Coder.decode(encoded)

        #expect(decoded == Payload(name: "Yuki"))
    }

    @Test("hasItems is public")
    func hasItemsIsPublic() async throws {
        #expect([1, 2, 3].hasItems)
        #expect([Int]().hasItems == false)
    }
}
