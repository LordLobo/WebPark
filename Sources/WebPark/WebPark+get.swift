//
//  WebPark+get.swift
//
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

public extension WebPark {
    func get<T>(_ endpoint: String) async throws -> T where T: Codable {
        let request = try createRequest("GET", endpoint: endpoint)
        let data = try await perform(request)

        return try Coder.decode(data)
    }

    func get<T>(_ endpoint: String,
                queryItems: [URLQueryItem]) async throws -> T where T: Codable {
        let request = try createRequest("GET",
                                        endpoint: endpoint,
                                        queryItems: queryItems)
        let data = try await perform(request)

        return try Coder.decode(data)
    }
}
