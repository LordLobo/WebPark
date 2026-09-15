//
//  WebPark+responseHandlingTests.swift
//
//
//  Covers response handling shared by every HTTP method: non-HTTP replies,
//  empty success bodies, and the messages carried by WebPark's error types.
//

import Foundation
import Testing
@testable import WebPark

private func BuildNoContentURLSession() -> URLSession {
    let noContentURL = URL(string: "https://lordlobo.mockapi.com/nocontent")!

    let response204 = HTTPURLResponse(url: noContentURL,
                                      statusCode: 204,
                                      httpVersion: nil,
                                      headerFields: nil)!

    URLProtocolMock.setMock((error: nil, data: nil, response: response204),
                            for: noContentURL)

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolMock.self]

    return URLSession(configuration: configuration)
}

@Suite("WebPark Response Handling Tests")
struct WebParkResponseHandlingTests {
    // MARK: - Non-HTTP responses

    @Test("A non-HTTP response throws rather than being decoded as success")
    func nonHTTPResponseThrows() async throws {
        let sut = Implementation(urlSession: BuildNonHTTPURLSession())

        await #expect(throws: WebParkError.unexpectedResponse) {
            let _: Cat = try await sut.get("/cats")
        }
    }

    // MARK: - Empty success bodies

    @Test("POST to a 204 endpoint succeeds when the response body is discarded")
    func postNoContent() async throws {
        let sut = Implementation(urlSession: BuildNoContentURLSession())
        let cat = Cat(name: "Yuki", color: "Brown")

        try await sut.post("/nocontent", body: cat)
    }

    @Test("PUT to a 204 endpoint succeeds when the response body is discarded")
    func putNoContent() async throws {
        let sut = Implementation(urlSession: BuildNoContentURLSession())
        let cat = Cat(name: "Yuki", color: "Brown")

        try await sut.put("/nocontent", body: cat)
    }

    @Test("PATCH to a 204 endpoint succeeds when the response body is discarded")
    func patchNoContent() async throws {
        let sut = Implementation(urlSession: BuildNoContentURLSession())
        let cat = Cat(name: "Yuki", color: "Brown")

        try await sut.patch("/nocontent", body: cat)
    }

    @Test("Decoding an empty 204 body still fails on the value-returning overload")
    func postNoContentDecodingFails() async throws {
        let sut = Implementation(urlSession: BuildNoContentURLSession())
        let cat = Cat(name: "Yuki", color: "Brown")

        await #expect(throws: WebParkError.self) {
            let _: Cat = try await sut.post("/nocontent", body: cat)
        }
    }

    // MARK: - Error messages

    @Test("WebParkError reports a useful message after being caught as any Error")
    func webParkErrorLocalizedDescription() async throws {
        let error: any Error = WebParkError.unableToMakeURL

        #expect(error.localizedDescription == "Unable to create URL from provided base URL and endpoint")
    }

    @Test("WebParkHttpError reports a useful message after being caught as any Error")
    func webParkHttpErrorLocalizedDescription() async throws {
        let error: any Error = WebParkHttpError(401)

        #expect(error.localizedDescription == "HTTP 401: Unauthorized")
    }

    @Test("Error messages survive a real catch block")
    func errorMessageInCatchBlock() async throws {
        let sut = Implementation(baseURL: "https://lordlobo.mockapi.com",
                                 urlSession: BuildGETURLSession())

        do {
            let _: [Cat] = try await sut.get("/catserror")
            Issue.record("Should have thrown WebParkHttpError")
        } catch {
            // `error` is bound as `any Error` here, which is what consumers actually get.
            #expect(error.localizedDescription == "HTTP 401: Unauthorized")
        }
    }
}
