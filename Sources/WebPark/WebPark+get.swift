//
//  WebPark+get.swift
//  
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

@available(macOS 12.0, *)
public extension WebPark {
        
    func get<T>(_ endpoint: String) async throws -> T where T:Codable {
        
        guard let request = try createRequest("GET", endpoint: endpoint) else {
            throw WebParkError.unableToMakeRequest
        }
        
        let (data, response) = try await urlSession.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode > 400 {
            throw WebParkHttpError(res.statusCode)
        }
        
        return try Coder.decode(data)
    }
    
    func get<T>(_ endpoint: String,
                queryItems: [URLQueryItem]) async throws -> T where T:Codable {
        
        guard let request = try createRequest("GET",
                                              endpoint: endpoint,
                                              queryItems: queryItems) else {
            throw WebParkError.unableToMakeRequest
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode > 400 {
            throw WebParkHttpError(res.statusCode)
        }
        
        return try Coder.decode(data)
    }
    
}
