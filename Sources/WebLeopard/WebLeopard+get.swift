//
//  WebLeopard+get.swift
//  
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

@available(macOS 12.0, *)
public extension WebLeopard {
        
    func get<T>(endpoint: String) async throws -> T where T:Codable {
        
        guard let request = try createRequest("GET", endpoint: endpoint) else {
            throw WebLeopardError.unableToMakeRequest
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode > 400 {
            throw HttpError(res.statusCode)
        }
        
        return try Coder.decode(data)
    }
    
    func get<T>(endpoint: String,
                queryItems: [URLQueryItem]) async throws -> T where T:Codable {
        
        guard let request = try createRequest("GET",
                                                     endpoint: endpoint,
                                                     queryItems: queryItems) else {
            throw WebLeopardError.unableToMakeRequest
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode > 400 {
            throw HttpError(res.statusCode)
        }
        
        return try Coder.decode(data)
    }
    
}
