//
//  WebPark+delete.swift
//
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

public extension WebPark {
    func delete(_ endpoint: String) async throws {
        let request = try createRequest("DELETE", endpoint: endpoint)
        _ = try await perform(request)
    }

    func delete(_ endpoint: String,
                queryItems: [URLQueryItem]) async throws {
        let request = try createRequest("DELETE",
                                        endpoint: endpoint,
                                        queryItems: queryItems)
        _ = try await perform(request)
    }
}
