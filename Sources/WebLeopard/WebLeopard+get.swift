//
//  WebLeopard+get.swift
//  
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

@available(macOS 12.0, *)
public extension WebLeopard {
        
    func get<T>(endpoint: String) async throws -> T where T:Decodable {
        
        guard let request = try createLeopardRequest("GET", endpoint: endpoint) else {
            throw RESTLeopardError.unableToMakeRequest
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode > 400 {
            throw HttpError(res.statusCode)
        }
        
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            throw RESTLeopardError.decodeFailure
        }
    }
    
    func get<T>(endpoint: String,
                queryItems: [URLQueryItem]) async throws -> T where T:Decodable {
        
        guard let request = try createLeopardRequest("GET",
                                                     endpoint: endpoint,
                                                     queryItems: queryItems) else {
            throw RESTLeopardError.unableToMakeRequest
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode > 400 {
            throw HttpError(res.statusCode)
        }
        
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            throw RESTLeopardError.decodeFailure
        }
    }
    
}
