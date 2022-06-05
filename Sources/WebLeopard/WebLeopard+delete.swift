//
//  WebLeopard+delete.swift
//  
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

@available(macOS 12.0, *)
public extension WebLeopard {

    func delete(endpoint: String) async throws -> Void {
        
        guard let request = try createLeopardRequest("DELETE", endpoint: endpoint) else {
            throw WebLeopardError.unableToMakeRequest
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode > 400 {
            throw HttpError(res.statusCode)
        }
    }
    
    func delete(endpoint: String,
                queryItems: [URLQueryItem]) async throws -> Void {
        
        guard let request = try createLeopardRequest("DELETE",
                                                     endpoint: endpoint,
                                                     queryItems: queryItems) else {
            throw WebLeopardError.unableToMakeRequest
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode > 400 {
            throw HttpError(res.statusCode)
        }
    }
    
}
