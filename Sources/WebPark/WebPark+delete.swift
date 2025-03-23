//
//  WebPark+delete.swift
//  
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

@available(macOS 12.0, *)
public extension WebPark {

    func delete(_ endpoint: String) async throws -> Void {
        
        guard let request = try createRequest("DELETE", endpoint: endpoint) else {
            throw WebParkError.unableToMakeRequest
        }
        
        let (_, response) = try await urlSession.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode > 400 {
            throw WebParkHttpError(res.statusCode)
        }
    }
    
    func delete(_ endpoint: String,
                queryItems: [URLQueryItem]) async throws -> Void {
        
        guard let request = try createRequest("DELETE",
                                              endpoint: endpoint,
                                              queryItems: queryItems) else {
            throw WebParkError.unableToMakeRequest
        }
        
        let (_, response) = try await urlSession.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode > 400 {
            throw WebParkHttpError(res.statusCode)
        }
    }
    
}
