//
//  WebLeopard+put.swift
//  
//
//  Created by Daniel Giralte on 6/5/22.
//

import Foundation

@available(macOS 12.0, *)
public extension WebLeopard {
    
    func put<T, D>(endpoint: String,
                   body: D) async throws -> T where T:Codable, D:Codable {
        
        guard var request = try createLeopardRequest("PUT", endpoint: endpoint, isJSON: true) else {
            throw RESTLeopardError.unableToMakeRequest
        }
        
        do {
            request.httpBody = try Coder.encode(body)
        } catch {
            throw RESTLeopardError.encodeFailure
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let res = response as? HTTPURLResponse,
           res.statusCode > 400 {
            throw HttpError(res.statusCode)
        }
            
        do {
            let decoded = try Coder<T>.decode(data)
            return decoded
        } catch {
            throw RESTLeopardError.decodeFailure
        }
    }
    
}
