//
//  WebPark+post.swift
//
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

public extension WebPark {
    func post<T, D>(_ endpoint: String,
                    body: D) async throws -> T where T: Codable, D: Codable {
        let request = try createRequest("POST", endpoint: endpoint, body: body)
        let data = try await perform(request)

        return try Coder.decode(data)
    }

    /// Sends a POST request and discards the response body.
    ///
    /// Use this when the endpoint replies with no content, such as `204 No Content`.
    /// Decoding an empty body through the value-returning overload would fail.
    func post<D>(_ endpoint: String,
                 body: D) async throws where D: Codable {
        let request = try createRequest("POST", endpoint: endpoint, body: body)
        _ = try await perform(request)
    }
}
